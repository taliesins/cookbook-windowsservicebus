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

powershell_script 'New-SBFarm' do
    guard_interpreter :powershell_script
    code <<-EOH1    
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$RunAsPassword = convertto-securestring "#{node['windowsservicebus']['service']['password']}" -asplaintext -force
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"
$GatewayDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}"
$MessageContainerDBConnectionString = "#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}"
$FarmDns = "#{node['windowsservicebus']['instance']['FarmDns']}"

$FarmCertificateThumbprint = "#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}"
$FarmCertificatePath = "#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']}"
$FarmCertificatePassword = "#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']}"

if (!$FarmCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($FarmCertificatePath,$FarmCertificatePassword,'DefaultKeySet')
    $FarmCertificateThumbprint = $cert.Thumbprint.ToLower()
}

$EncryptionCertificateThumbprint = "#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}"
$EncryptionCertificatePath = "#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']}"
$EncryptionCertificatePassword = "#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']}"

if (!$EncryptionCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($EncryptionCertificatePath,$EncryptionCertificatePassword,'DefaultKeySet')
    $EncryptionCertificateThumbprint = $cert.Thumbprint.ToLower()
}

try{$sbFarm = get-sbfarm}catch{$sbFarm = $null}

if ($sbFarm){
    $hostName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
    $sbFarmHost = $sbFarm.Hosts | ?{$_.Name -eq $hostName}
    if (!$sbFarmHost){
        Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
    }
    $localRunAsAccount = $sbFarm.RunAsAccount 
    $localRunAsAccount = $localRunAsAccount -replace "#{'^\.\\\\'}", ""
    $localRunAsAccount = $localRunAsAccount -replace "#{'^$env:COMPUTERNAME\\\\'}", ""
    
    if ($localRunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
        Stop-SBFarm
        Set-SBFarm -RunAsAccount $RunAsAccount -SBFarmDBConnectionString $SBFarmDBConnectionString -FarmDns $FarmDns
        Update-SBHost
        Start-SBFarm
    }
} else {
    New-SBFarm -SBFarmDBConnectionString $SBFarmDBConnectionString -GatewayDBConnectionString $GatewayDBConnectionString -MessageContainerDBConnectionString $MessageContainerDBConnectionString -RunAsAccount $RunAsAccount -FarmDns $FarmDns -FarmCertificateThumbprint $FarmCertificateThumbprint -EncryptionCertificateThumbprint $EncryptionCertificateThumbprint
    Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
}

EOH1
    
    only_if <<-EOH2
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"
$GatewayDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}"
$MessageContainerDBConnectionString = "#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}"
$FarmDns = "#{node['windowsservicebus']['instance']['FarmDns']}"

$FarmCertificateThumbprint = "#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}"
$FarmCertificatePath = "#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']}"
$FarmCertificatePassword = "#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']}"

if (!$FarmCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($FarmCertificatePath,$FarmCertificatePassword,'DefaultKeySet')
    $FarmCertificateThumbprint = $cert.Thumbprint.ToLower()
}

$EncryptionCertificateThumbprint = "#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}"
$EncryptionCertificatePath = "#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']}"
$EncryptionCertificatePassword = "#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']}"

if (!$EncryptionCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($EncryptionCertificatePath,$EncryptionCertificatePassword,'DefaultKeySet')
    $EncryptionCertificateThumbprint = $cert.Thumbprint.ToLower()
}

try{$sbFarm = get-sbfarm}catch{$sbFarm = $null}

if ($sbFarm){
    $localRunAsAccount = $sbFarm.RunAsAccount 
    $localRunAsAccount = $localRunAsAccount -replace "#{'^\.\\\\'}", ""
    $localRunAsAccount = $localRunAsAccount -replace "#{'^$env:COMPUTERNAME\\\\'}", ""
    if ($localRunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
        return $true
    }
} else {
    return $true
}
return $false
EOH2
    action :run
end

node['windowsservicebus']['instance']['SBMessageContainers'].each do |service_bus_message_container|
    powershell_script "New-SBMessageContainer #{service_bus_message_container['DatabaseName']}" do
        guard_interpreter :powershell_script
        code <<-EOH3
$ErrorActionPreference="Stop"       
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$DatabaseName = "#{service_bus_message_container['DatabaseName']}"
$ContainerDBConnectionString = "#{service_bus_message_container['ConnectionString']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"

$SBMessageContainer = Get-SBMessageContainer | ?{$_.DatabaseName -eq $DatabaseName}

if (!$SBMessageContainer) {
    New-SBMessageContainer -SBFarmDBConnectionString $SBFarmDBConnectionString -ContainerDBConnectionString $ContainerDBConnectionString -Verbose
}
EOH3
        action :run
        only_if <<-EOH4
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$DatabaseName = "#{service_bus_message_container['DatabaseName']}"
$ContainerDBConnectionString = "#{service_bus_message_container['ConnectionString']}"
$SBFarmDBConnectionString = "#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}"

$SBMessageContainer = Get-SBMessageContainer | ?{$_.DatabaseName -eq $DatabaseName}

if (!$SBMessageContainer) {
    return $true
}
return $false
EOH4
    end
end

node['windowsservicebus']['instance']['ServiceBusNamespaces'].each do |service_bus_namespace|
    powershell_script "New-SBNamespace #{service_bus_namespace['Namespace']}" do
        guard_interpreter :powershell_script
        code <<-EOH5
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$RunAsAccount = "#{node['windowsservicebus']['service']['account']}"
$Namespace = "#{service_bus_namespace['Namespace']}"
$PrimaryKey = "#{service_bus_namespace['PrimaryKey']}"
$SecondaryKey = "#{service_bus_namespace['SecondaryKey']}"
$KeyName = "RootManageSharedAccessKey"

$SBNamespace = Get-SBNamespace | ?{$_.Name -eq $Namespace}
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
    Try
    {
        $localRunAsAccount = $RunAsAccount -replace "#{'^\.\\\\'}", ""
        $localRunAsAccount = $localRunAsAccount -replace "#{'^$env:COMPUTERNAME\\\\'}", ""
    
        New-SBNamespace -Name $Namespace -AddressingScheme 'Path' -ManageUsers @("Administrators", $localRunAsAccount) -Verbose 
        Set-SBAuthorizationRule -NamespaceName $Namespace -Name $KeyName -PrimaryKey $PrimaryKey -SecondaryKey $SecondaryKey -Verbose    
    }
    Catch [system.InvalidOperationException]
    {
    }
}
EOH5
        action :run
        only_if <<-EOH6
$ErrorActionPreference="Stop"   
ipmo "C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll"
$Namespace = "#{service_bus_namespace['Namespace']}"
$PrimaryKey = "#{service_bus_namespace['PrimaryKey']}"
$SecondaryKey = "#{service_bus_namespace['SecondaryKey']}"
$KeyName = "RootManageSharedAccessKey"

$SBNamespace = Get-SBNamespace | ?{$_.Name -eq $Namespace}
if ($SBNamespace) {
    $SBAuthorizationRule = Get-SBAuthorizationRule -NamespaceName $Namespace | ?{$_.KeyName -eq $KeyName}

    if (!$SBAuthorizationRule) {
        if ($SBAuthorizationRule.PrimaryKey -ne $PrimaryKey -or $SBAuthorizationRule.SecondaryKey -ne $SecondaryKey) {
            return $true
        } else {
            return $false
        }
    } else {
        return $true
    }
} else {
    return $true
}
return $false
EOH6
    end    
end