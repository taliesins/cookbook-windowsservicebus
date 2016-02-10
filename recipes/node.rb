#
# Cookbook Name:: windowsservicebus
# Recipe:: node
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

if node['windowsservicebus']['service']['account'] == ""
    raise "Please configure Windows Service Bus service_account attribute is configured"
end

if node['windowsservicebus']['instance']['FarmDns'] == ""
    raise "Please configure Windows Service Bus FarmDns attribute is configured"
end

powershell_script 'Add-SBHost' do
    guard_interpreter :powershell_script
    code <<-EOH
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$RunAsPassword = convertto-securestring "#{node['windowsservicebus']['service']['password']}" -asplaintext -force
$EnableFirewallRules = $#{node['windowsservicebus']['service']['enablefirewalls']
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"
$GatewayDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}"
$FarmDns = "#{node['windowsservicebus']['instance']['FarmDns']}"

$hostName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
try{$sbFarm = get-sbfarm}catch{$sbFarm = $null}

if ($sbFarm){
    $sbFarmHost = $sbFarm.Hosts | ?{$_.Name -eq $hostName}
    if (!$sbFarmHost){
        Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
    } else {
        $localRunAsAccount = $sbFarm.RunAsAccount 
        $localRunAsAccount = $localRunAsAccount -replace "#{'^\.\\\\'}", ""
        $localRunAsAccount = $localRunAsAccount -replace "^$env:COMPUTERNAME\\", ""
    
        if ($localRunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
            Stop-SBFarm
            Update-SBHost
            Start-SBFarm
        }
    }
} else {
    Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
}
    EOH
    action :run
    not_if <<-EOH
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$hostName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
try{$sbFarm = get-sbfarm}catch{$sbFarm = $null}

if ($sbFarm){
    $sbFarmHost = $sbFarm.Hosts | ?{$_.Name -eq $hostName}
    if ($sbFarmHost){
        return $true
    } else {
        return $false
    }
} else {
    return $false
}
return $true
    EOH
end