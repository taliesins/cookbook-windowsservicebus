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

if node['windowsservicebus']['instance']['FarmCertificateThumbprint'] == ""
    raise "Please configure Windows Service Bus FarmCertificateThumbprint attribute is configured"
end

if node['windowsservicebus']['instance']['EncryptionCertificateThumbprint'] == ""
    raise "Please configure Windows Service Bus EncryptionCertificateThumbprint attribute is configured"
end

powershell_script 'New-SBFarm' do
	guard_interpreter :powershell_script
	code <<-EOH
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"
$GatewayDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}"
$MessageContainerDBConnectionString = "#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}"
$FarmDns = "#{node['windowsservicebus']['instance']['FarmDns']}"
$FarmCertificateThumbprint = "#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}"
$EncryptionCertificateThumbprint = "#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}"

$sbFarm = get-sbfarm

if ($sbFarm){
    if ($sbFarm.RunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
        Set-SBFarm -RunAsAccount $RunAsAccount -SBFarmDBConnectionString $SBFarmDBConnectionString -FarmDns $FarmDns
    }
} else {
    New-SBFarm SBFarmDBConnectionString $SBFarmDBConnectionString -GatewayDBConnectionString $GatewayDBConnectionString -MessageContainerDBConnectionString $MessageContainerDBConnectionString -RunAsAccount $RunAsAccount -FarmDns $FarmDns -FarmCertificateThumbprint $FarmCertificateThumbprint -EncryptionCertificateThumbprint $EncryptionCertificateThumbprint
}
    EOH
    action :run
    not_if <<-EOH
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"
$GatewayDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}"
$MessageContainerDBConnectionString = "#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}"
$FarmDns = "#{node['windowsservicebus']['instance']['FarmDns']}"
$FarmCertificateThumbprint = "#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}"
$EncryptionCertificateThumbprint = "#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}"

$sbFarm = get-sbfarm

if ($sbFarm){
    if ($sbFarm.RunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
        return $false
    }
} else {
    return $false
}
return $true
    EOH
end

node['windowsservicebus']['instance']['SBMessageContainers'].each do |SBMessageContainer|
    powershell_script "New-SBMessageContainer #{SBMessageContainer['DatabaseName']}" do
    	guard_interpreter :powershell_script
    	code <<-EOH
$DatabaseName = "#{SBMessageContainer['DatabaseName']}"
$ContainerDBConnectionString = "#{SBMessageContainer['ConnectionString']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"

$SBMessageContainer = Get-SBMessageContainer | ?{$_.DatabaseName -eq $DatabaseName}

if (!$SBMessageContainer) {
    New-SBMessageContainer -SBFarmDBConnectionString $SBFarmDBConnectionString -ContainerDBConnectionString $ContainerDBConnectionString -Verbose
}
		EOH
	    action :run
		not_if <<-EOH
$DatabaseName = "#{SBMessageContainer['DatabaseName']}"
$ContainerDBConnectionString = "#{SBMessageContainer['ConnectionString']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"

$SBMessageContainer = Get-SBMessageContainer | ?{$_.DatabaseName -eq $DatabaseName}

if (!$SBMessageContainer) {
    return $false
}
return $true
		EOH
    end
end

node['windowsservicebus']['instance']['ServiceBusNamespaces'].each do |serviceBusNamespace|
    powershell_script "New-SBNamespace #{serviceBusNamespace['Namespace']}" do
    	guard_interpreter :powershell_script
		code <<-EOH
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$Namespace = "#{serviceBusNamespace['Namespace']}"
$PrimaryKey = "#{serviceBusNamespace['PrimaryKey']}"
$SecondaryKey = "#{serviceBusNamespace['SecondaryKey']}"
$KeyName = "RootManageSharedAccessKey"

$SBNamespace = Get-SBNamespace -Name $Namespace
if ($SBNamespace) {
    $SBAuthorizationRule = Get-SBAuthorizationRule -NamespaceName $Namespace | ?{$_.KeyName -eq $KeyName}

    if (!$SBAuthorizationRule) {
        if ($SBAuthorizationRule.PrimaryKey -ne $PrimaryKey -or $SBAuthorizationRule.SecondaryKey -ne $SecondaryKey) {
            Set-SBAuthorizationRule -NamespaceName $Namespace -Name $KeyName -PrimaryKey $PrimaryKey -SecondaryKey $SecondaryKey -Verbose 
        }
    } else {
        Set-SBAuthorizationRule -NamespaceName $Namespace -Name $KeyName -PrimaryKey $PrimaryKey -SecondaryKey $SecondaryKey -Verbose 
    }
} else {
    New-SBNamespace -Name $Namespace -AddressingScheme 'Path' -ManageUsers $RunAsAccount -Verbose 
    Set-SBAuthorizationRule -NamespaceName $Namespace -Name $KeyName -PrimaryKey $PrimaryKey -SecondaryKey $SecondaryKey -Verbose    
}
        EOH
	    action :run
		not_if <<-EOH
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$Namespace = "#{serviceBusNamespace['Namespace']}"
$PrimaryKey = "#{serviceBusNamespace['PrimaryKey']}"
$SecondaryKey = "#{serviceBusNamespace['SecondaryKey']}"
$KeyName = "RootManageSharedAccessKey"

$SBNamespace = Get-SBNamespace -Name $Namespace
if ($SBNamespace) {
    $SBAuthorizationRule = Get-SBAuthorizationRule -NamespaceName $Namespace | ?{$_.KeyName -eq $KeyName}

    if (!$SBAuthorizationRule) {
        if ($SBAuthorizationRule.PrimaryKey -ne $PrimaryKey -or $SBAuthorizationRule.SecondaryKey -ne $SecondaryKey) {
            return $false
        }
    } else {
        return $false
    }
} else {
    return $false
}
return $true
		EOH
    end    
end