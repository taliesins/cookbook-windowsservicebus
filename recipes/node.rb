#
# Cookbook Name:: windowsservicebus
# Recipe:: node
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

powershell_script 'Add-SBHost' do
    guard_interpreter :powershell_script
    code <<-EOH
$RunAsPassword = "#{node['windowsservicebus']['service']['password']}"
$EnableFirewallRules = $#{node['windowsservicebus']['service']['enablefirewalls']
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"

$hostName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
$sbFarm = get-sbfarm

if ($sbFarm){
    $sbFarmHost = $sbFarm.Hosts | ?{$_.Name -eq $hostName}
    if (!$sbFarmHost){
        Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $SBRunAsPassword -EnableFirewallRules $true
    }
} else {
    Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $SBRunAsPassword -EnableFirewallRules $true
}
    EOH
    action :run
    not_if <<-EOH
$hostName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
$sbFarm = get-sbfarm

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