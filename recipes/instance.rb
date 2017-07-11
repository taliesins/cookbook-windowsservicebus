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
$ErrorActionPreference='Stop'

$command = @'
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$RunAsAccount = '#{node['windowsservicebus']['service']['account']}'
$RunAsPassword = convertto-securestring '#{node['windowsservicebus']['service']['password']}' -asplaintext -force
$SBFarmDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}'
$GatewayDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}'
$MessageContainerDBConnectionString = '#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}'
$FarmDns = '#{node['windowsservicebus']['instance']['FarmDns']}'

$FarmCertificateThumbprint = '#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}'
$FarmCertificatePath = '#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']}'
$FarmCertificatePassword = '#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']}'

if (!$FarmCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($FarmCertificatePath,$FarmCertificatePassword,'DefaultKeySet')
    $FarmCertificateThumbprint = $cert.Thumbprint.ToLower()
}

$EncryptionCertificateThumbprint = '#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}'
$EncryptionCertificatePath = '#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']}'
$EncryptionCertificatePassword = '#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']}'

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
    $localRunAsAccount = $localRunAsAccount -replace "#{'^\\.\\\\'}", ""
    $localRunAsAccount = $localRunAsAccount -replace "#{'^$env:COMPUTERNAME\\\\'}", ""
    
    if ($localRunAsAccount -ne $RunAsAccount -or $sbFarm.SBFarmDBConnectionString -ne $SBFarmDBConnectionString -or $sbFarm.GatewayDBConnectionString -ne $GatewayDBConnectionString -or $sbFarm.FarmDNS -ne $FarmDns) {
        Stop-SBFarm
        Set-SBFarm -RunAsAccount $RunAsAccount -SBFarmDBConnectionString $SBFarmDBConnectionString -FarmDns $FarmDns
        try {
            Update-SBHost -RunAsPassword $RunAsPassword
            Start-SBFarm
        } catch {
            Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
        }
    }
} else {
    New-SBFarm -SBFarmDBConnectionString $SBFarmDBConnectionString -GatewayDBConnectionString $GatewayDBConnectionString -MessageContainerDBConnectionString $MessageContainerDBConnectionString -RunAsAccount $RunAsAccount -FarmDns $FarmDns -FarmCertificateThumbprint $FarmCertificateThumbprint -EncryptionCertificateThumbprint $EncryptionCertificateThumbprint
    Add-SBHost -SBFarmDBConnectionString $SBFarmDBConnectionString -RunAsPassword $RunAsPassword -EnableFirewallRules $true
}
'@

function GetTempFile($file_name) {
  $path = $env:TEMP
  if (!$path){
    $path = '#{'c:\\windows\\Temp\\'}'
  }
  return Join-Path -Path $path -ChildPath $file_name
}

function SlurpStdout($out_file, $cur_line) {
  if (Test-Path $out_file) {
    get-content $out_file | select -skip $cur_line | ForEach {
      $cur_line += 1
      Write-Host "$_" 
    }
  }
  return $cur_line
}

function SlurpStderr($error_out_file, $cur_line) {
  if (Test-Path $error_out_file) {
    get-content $error_out_file | select -skip $cur_line | ForEach {
      $cur_line += 1
      Write-Error "$_" 
    }
  }
  return $cur_line
}

function RunAsScheduledTask($username, $password, $scriptFile) 
{
  $task_name = "WinRM_Elevated_Shell_Octopus"
  $stdout_file = GetTempFile('WinRM_Elevated_Shell_stdout.log')
  $stderr_file = GetTempFile('WinRM_Elevated_Shell_stderr.log')

  if (Test-Path $stdout_file) {
    Remove-Item $stdout_file | Out-Null
  }

  if (Test-Path $stderr_file) {
    Remove-Item $stderr_file | Out-Null
  }  

  $task_xml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
    <Principals>
        <Principal id="Author">
        <UserId>{username}</UserId>
        <LogonType>Password</LogonType>
        <RunLevel>HighestAvailable</RunLevel>
        </Principal>
    </Principals>
    <Settings>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
        <AllowHardTerminate>true</AllowHardTerminate>
        <StartWhenAvailable>false</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
        <IdleSettings>
        <StopOnIdleEnd>false</StopOnIdleEnd>
        <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
        <Priority>4</Priority>
    </Settings>
    <Actions Context="Author">
        <Exec>
        <Command>cmd</Command>
        <Arguments>{arguments}</Arguments>
        </Exec>
    </Actions>
</Task>
'@

  $arguments = "/c powershell.exe -NonInteractive -File $script_file >$stdout_file 2>$stderr_file"

  $task_xml = $task_xml.Replace("{arguments}", $arguments.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace('''', '&apos;'))
  $task_xml = $task_xml.Replace("{username}", $username.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace('''', '&apos;'))
  
  $schedule = New-Object -ComObject "Schedule.Service"
  $schedule.Connect()
  $task = $schedule.NewTask($null)
  $task.XmlText = $task_xml
  
  $folder = $schedule.GetFolder("#{'\\'}")
  $folder.RegisterTaskDefinition($task_name, $task, 6, $username, $password, 1, $null) | Out-Null

  $registered_task = $folder.GetTask("#{'\\'}$task_name")
  $registered_task.Run($null) | Out-Null

  $timeout = 10
  $sec = 0
  while ( (!($registered_task.state -eq 4)) -and ($sec -lt $timeout) ) {
    Start-Sleep -s 1
    $sec++
  }

  $stdout_cur_line = 0
  $stderr_cur_line = 0
  do {
    Start-Sleep -m 100
    $stdout_cur_line = SlurpStdout $stdout_file $stdout_cur_line
  } while (!($registered_task.state -eq 3))
  Start-Sleep -m 100
  $exit_code = $registered_task.LastTaskResult
  $stdout_cur_line = SlurpStdout $stdout_file $stdout_cur_line
  try{
    $stderr_cur_line = SlurpStderr $stderr_file $stderr_cur_line
  } finally {
    if (Test-Path $stdout_file) {
      Remove-Item $stdout_file | Out-Null
    }

    if (Test-Path $stderr_file) {
      Remove-Item $stderr_file | Out-Null
    } 
    
    $folder.DeleteTask($task_name, 0)
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null
  }

  return $exit_code
}

$script_file = GetTempFile('WinRM_Elevated_Shell.ps1')

if (Test-Path $script_file) {
  Remove-Item $script_file | Out-Null
}

Set-Content -Path $script_file -Value $command | Out-Null
try{
  $username = '#{node['windowsservicebus']['service']['account']}'.Replace('.#{'\\'}', $env:computername+'#{'\\'}')
  $password = '#{node['windowsservicebus']['service']['password']}'
  $exitCode = RunAsScheduledTask -username $username -password $password -script_path $script_file
  exit $exitCode
} finally {
  if (Test-Path $script_file) {
      Remove-Item $script_file | Out-Null
  }
}
	
EOH1
    
    only_if <<-EOH2
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$RunAsAccount = '#{node['windowsservicebus']['service']['account']}'
$SBFarmDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}'
$GatewayDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbGatewayDatabase']}'
$MessageContainerDBConnectionString = '#{node['windowsservicebus']['instance']['SBMessageContainers'][0]['ConnectionString']}'
$FarmDns = '#{node['windowsservicebus']['instance']['FarmDns']}'

$FarmCertificateThumbprint = '#{node['windowsservicebus']['instance']['FarmCertificateThumbprint']}'
$FarmCertificatePath = '#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_path']}'
$FarmCertificatePassword = '#{node['windowsservicebus']['certificate']['FarmCertificate']['pkcs12_passphrase']}'

if (!$FarmCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($FarmCertificatePath,$FarmCertificatePassword,'DefaultKeySet')
    $FarmCertificateThumbprint = $cert.Thumbprint.ToLower()
}

$EncryptionCertificateThumbprint = '#{node['windowsservicebus']['instance']['EncryptionCertificateThumbprint']}'
$EncryptionCertificatePath = '#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_path']}'
$EncryptionCertificatePassword = '#{node['windowsservicebus']['certificate']['EncryptionCertificate']['pkcs12_passphrase']}'

if (!$EncryptionCertificateThumbprint) {
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $cert.Import($EncryptionCertificatePath,$EncryptionCertificatePassword,'DefaultKeySet')
    $EncryptionCertificateThumbprint = $cert.Thumbprint.ToLower()
}

try{$sbFarm = get-sbfarm}catch{$sbFarm = $null}

if ($sbFarm){
    $localRunAsAccount = $sbFarm.RunAsAccount 
    $localRunAsAccount = $localRunAsAccount -replace "#{'^\\.\\\\'}", ""
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

$ErrorActionPreference='Stop'

$command = @'
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$DatabaseName = '#{service_bus_message_container['DatabaseName']}'
$ContainerDBConnectionString = '#{service_bus_message_container['ConnectionString']}'
$SBFarmDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}'

$SBMessageContainer = Get-SBMessageContainer | ?{$_.DatabaseName -eq $DatabaseName}

if (!$SBMessageContainer) {
    New-SBMessageContainer -SBFarmDBConnectionString $SBFarmDBConnectionString -ContainerDBConnectionString $ContainerDBConnectionString -Verbose
}
'@

function GetTempFile($file_name) {
  $path = $env:TEMP
  if (!$path){
    $path = '#{'c:\\windows\\Temp\\'}'
  }
  return Join-Path -Path $path -ChildPath $file_name
}

function SlurpStdout($out_file, $cur_line) {
  if (Test-Path $out_file) {
    get-content $out_file | select -skip $cur_line | ForEach {
      $cur_line += 1
      Write-Host "$_" 
    }
  }
  return $cur_line
}

function SlurpStderr($error_out_file, $cur_line) {
  if (Test-Path $error_out_file) {
    get-content $error_out_file | select -skip $cur_line | ForEach {
      $cur_line += 1
      Write-Error "$_" 
    }
  }
  return $cur_line
}

function RunAsScheduledTask($username, $password, $scriptFile) 
{
  $task_name = "WinRM_Elevated_Shell_Octopus"
  $stdout_file = GetTempFile('WinRM_Elevated_Shell_stdout.log')
  $stderr_file = GetTempFile('WinRM_Elevated_Shell_stderr.log')

  if (Test-Path $stdout_file) {
    Remove-Item $stdout_file | Out-Null
  }

  if (Test-Path $stderr_file) {
    Remove-Item $stderr_file | Out-Null
  }  

  $task_xml = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
    <Principals>
        <Principal id="Author">
        <UserId>{username}</UserId>
        <LogonType>Password</LogonType>
        <RunLevel>HighestAvailable</RunLevel>
        </Principal>
    </Principals>
    <Settings>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
        <AllowHardTerminate>true</AllowHardTerminate>
        <StartWhenAvailable>false</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
        <IdleSettings>
        <StopOnIdleEnd>false</StopOnIdleEnd>
        <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>true</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>PT2H</ExecutionTimeLimit>
        <Priority>4</Priority>
    </Settings>
    <Actions Context="Author">
        <Exec>
        <Command>cmd</Command>
        <Arguments>{arguments}</Arguments>
        </Exec>
    </Actions>
</Task>
'@

  $arguments = "/c powershell.exe -NonInteractive -File $script_file >$stdout_file 2>$stderr_file"

  $task_xml = $task_xml.Replace("{arguments}", $arguments.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace('''', '&apos;'))
  $task_xml = $task_xml.Replace("{username}", $username.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;').Replace('''', '&apos;'))
  
  $schedule = New-Object -ComObject "Schedule.Service"
  $schedule.Connect()
  $task = $schedule.NewTask($null)
  $task.XmlText = $task_xml
  
  $folder = $schedule.GetFolder("#{'\\'}")
  $folder.RegisterTaskDefinition($task_name, $task, 6, $username, $password, 1, $null) | Out-Null

  $registered_task = $folder.GetTask("#{'\\'}$task_name")
  $registered_task.Run($null) | Out-Null

  $timeout = 10
  $sec = 0
  while ( (!($registered_task.state -eq 4)) -and ($sec -lt $timeout) ) {
    Start-Sleep -s 1
    $sec++
  }

  $stdout_cur_line = 0
  $stderr_cur_line = 0
  do {
    Start-Sleep -m 100
    $stdout_cur_line = SlurpStdout $stdout_file $stdout_cur_line
  } while (!($registered_task.state -eq 3))
  Start-Sleep -m 100
  $exit_code = $registered_task.LastTaskResult
  $stdout_cur_line = SlurpStdout $stdout_file $stdout_cur_line
  try{
    $stderr_cur_line = SlurpStderr $stderr_file $stderr_cur_line
  } finally {
    if (Test-Path $stdout_file) {
      Remove-Item $stdout_file | Out-Null
    }

    if (Test-Path $stderr_file) {
      Remove-Item $stderr_file | Out-Null
    } 
    
    $folder.DeleteTask($task_name, 0)
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($schedule) | Out-Null
  }

  return $exit_code
}

$script_file = GetTempFile('WinRM_Elevated_Shell.ps1')

if (Test-Path $script_file) {
  Remove-Item $script_file | Out-Null
}

Set-Content -Path $script_file -Value $command | Out-Null
try{
  $username = '#{node['windowsservicebus']['service']['account']}'.Replace('.#{'\\'}', $env:computername+'#{'\\'}')
  $password = '#{node['windowsservicebus']['service']['password']}'
  $exitCode = RunAsScheduledTask -username $username -password $password -script_path $script_file
  exit $exitCode
} finally {
  if (Test-Path $script_file) {
      Remove-Item $script_file | Out-Null
  }
}
EOH3
        action :run
        only_if <<-EOH4
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$DatabaseName = '#{service_bus_message_container['DatabaseName']}'
$ContainerDBConnectionString = '#{service_bus_message_container['ConnectionString']}'
$SBFarmDBConnectionString = '#{node['windowsservicebus']['instance']['connectionstring']['SbManagementDB']}'

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
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$RunAsAccount = '#{node['windowsservicebus']['service']['account']}'
$Namespace = '#{service_bus_namespace['Namespace']}'
$PrimaryKey = '#{service_bus_namespace['PrimaryKey']}'
$SecondaryKey = '#{service_bus_namespace['SecondaryKey']}'
$KeyName = 'RootManageSharedAccessKey'

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
        $localRunAsAccount = $RunAsAccount -replace "#{'^\\.\\\\'}", ""
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
$ErrorActionPreference='Stop'
ipmo 'C:/Program Files/Service Bus/1.1/Microsoft.ServiceBus.Commands.dll'
$Namespace = '#{service_bus_namespace['Namespace']}'
$PrimaryKey = '#{service_bus_namespace['PrimaryKey']}'
$SecondaryKey = '#{service_bus_namespace['SecondaryKey']}'
$KeyName = 'RootManageSharedAccessKey'

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