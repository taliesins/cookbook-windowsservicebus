#
# Cookbook Name:: windowsservicebus
# Recipe:: default
#
# Copyright (C) 2015 Taliesin Sisson
#
# All rights reserved - Do Not Redistribute
#

if node['windowsservicebus']['database']['account'] == ""
    raise "Please configure Windows Service Bus database account attribute is configured"
end

# Run the SQL file only if the 'learnchef' database has not yet been created.
powershell_script 'Initialize database' do
  code <<-EOH
$ErrorActionPreference = "Stop"

Function Get-SQLInstance {  
    <#
        .SYNOPSIS
            Retrieves SQL server information from a local or remote servers.

        .DESCRIPTION
            Retrieves SQL server information from a local or remote servers. Pulls all 
            instances from a SQL server and detects if in a cluster or not.

        .PARAMETER Computername
            Local or remote systems to query for SQL information.

        .NOTES
            Name: Get-SQLInstance
            Author: Boe Prox
            DateCreated: 07 SEPT 2013

        .EXAMPLE
            Get-SQLInstance -Computername DC1

            SQLInstance   : MSSQLSERVER
            Version       : 10.0.1600.22
            isCluster     : False
            Computername  : DC1
            FullName      : DC1
            isClusterNode : False
            Edition       : Enterprise Edition
            ClusterName   : 
            ClusterNodes  : {}
            Caption       : SQL Server 2008

            SQLInstance   : MINASTIRITH
            Version       : 10.0.1600.22
            isCluster     : False
            Computername  : DC1
            FullName      : DC1\MINASTIRITH
            isClusterNode : False
            Edition       : Enterprise Edition
            ClusterName   : 
            ClusterNodes  : {}
            Caption       : SQL Server 2008

            Description
            -----------
            Retrieves the SQL information from DC1
    #>
    [cmdletbinding()] 
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('__Server','DNSHostName','IPAddress')]
        [string[]]$ComputerName = $env:COMPUTERNAME
    ) 
    Process {
        ForEach ($Computer in $Computername) {
            $Computer = $computer -replace '(.*?)\..+','$1'
            Write-Verbose ("Checking {0}" -f $Computer)
            Try { 
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer) 
                $baseKeys = "SOFTWARE\\Microsoft\\Microsoft SQL Server",
                "SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server"
                If ($reg.OpenSubKey($basekeys[0])) {
                    $regPath = $basekeys[0]
                } ElseIf ($reg.OpenSubKey($basekeys[1])) {
                    $regPath = $basekeys[1]
                } Else {
                    Continue
                }
                $regKey= $reg.OpenSubKey("$regPath")
                If ($regKey.GetSubKeyNames() -contains "Instance Names") {
                    $regKey= $reg.OpenSubKey("$regpath\\Instance Names\\SQL" ) 
                    $instances = @($regkey.GetValueNames())
                } ElseIf ($regKey.GetValueNames() -contains 'InstalledInstances') {
                    $isCluster = $False
                    $instances = $regKey.GetValue('InstalledInstances')
                } Else {
                    Continue
                }
                If ($instances.count -gt 0) { 
                    ForEach ($instance in $instances) {
                        $nodes = New-Object System.Collections.Arraylist
                        $clusterName = $Null
                        $isCluster = $False
                        $instanceValue = $regKey.GetValue($instance)
                        $instanceReg = $reg.OpenSubKey("$regpath\\$instanceValue")
                        If ($instanceReg.GetSubKeyNames() -contains "Cluster") {
                            $isCluster = $True
                            $instanceRegCluster = $instanceReg.OpenSubKey('Cluster')
                            $clusterName = $instanceRegCluster.GetValue('ClusterName')
                            $clusterReg = $reg.OpenSubKey("Cluster\\Nodes")                            
                            $clusterReg.GetSubKeyNames() | ForEach {
                                $null = $nodes.Add($clusterReg.OpenSubKey($_).GetValue('NodeName'))
                            }
                        }
                        $instanceRegSetup = $instanceReg.OpenSubKey("Setup")
                        Try {
                            $edition = $instanceRegSetup.GetValue('Edition')
                        } Catch {
                            $edition = $Null
                        }
                        Try {
                            $ErrorActionPreference = 'Stop'
                            #Get from filename to determine version
                            $servicesReg = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services")
                            $serviceKey = $servicesReg.GetSubKeyNames() | Where {
                                $_ -match "$instance"
                            } | Select -First 1
                            $service = $servicesReg.OpenSubKey($serviceKey).GetValue('ImagePath')
                            $file = $service -replace '^.*(\w:\\.*\\sqlservr.exe).*','$1'
                            $version = (Get-Item ("\\$Computer\$($file -replace ":","$")")).VersionInfo.ProductVersion
                        } Catch {
                            #Use potentially less accurate version from registry
                            $Version = $instanceRegSetup.GetValue('Version')
                        } Finally {
                            $ErrorActionPreference = 'Continue'
                        }
                        New-Object PSObject -Property @{
                            Computername = $Computer
                            SQLInstance = $instance
                            Edition = $edition
                            Version = $version
                            Caption = {Switch -Regex ($version) {
                                "^16" {'SQL Server 2016';Break}
                                "^14" {'SQL Server 2014';Break}
                                "^11" {'SQL Server 2012';Break}
                                "^10\.5" {'SQL Server 2008 R2';Break}
                                "^10" {'SQL Server 2008';Break}
                                "^9"  {'SQL Server 2005';Break}
                                "^8"  {'SQL Server 2000';Break}
                                Default {'Unknown'}
                            }}.InvokeReturnAsIs()
                            isCluster = $isCluster
                            isClusterNode = ($nodes -contains $Computer)
                            ClusterName = $clusterName
                            ClusterNodes = ($nodes -ne $Computer)
                            FullName = {
                                If ($Instance -eq 'MSSQLSERVER') {
                                    $Computer
                                } Else {
                                    "$($Computer)\$($instance)"
                                }
                            }.InvokeReturnAsIs()
                        }
                    }
                }
            } Catch { 
                Write-Warning ("{0}: {1}" -f $Computer,$_.Exception.Message)
            }  
        }   
    }
}

function Invoke-SafeSqlcmd($ServerInstance, $Username, $Password, $Query) {
    if (!$Username) {
        if (!$ServerInstance) {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $Query
        } else {
            return Invoke-Sqlcmd -Query $Query
        }
    } else {
        if (!$ServerInstance) {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $Username -Password $Password -Query $Query
        } else {
            return Invoke-Sqlcmd -Username $Username -Password $Password -Query $Query
        }
    }
}

$Hostname = '#{node['windowsservicebus']['database']['host']}'
$Username = '#{node['windowsservicebus']['database']['username']}'
$Password = '#{node['windowsservicebus']['database']['password']}'
$Account = '#{node['windowsservicebus']['database']['account']}''
$Roles = @(#{node['windowsservicebus']['database']['sys_roles'].map { |i| "'" + i.to_s + "'" }.join(",")})

$MicrosoftSqlPath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft SQL Server'

$SqlPsPath = Get-ChildItem $MicrosoftSqlPath -recurse -Filter "SQLPS" -Exclude @("Data", "JOBS", "Log") -ErrorAction SilentlyContinue | Select-Object -Last 1

if (!($SqlPsPath)){
    throw "No SQLPS directory detected. Please install SQLPS."
}
    
$SqlPsPath = $SqlPsPath.FullName

Push-Location
Import-Module $SqlPsPath -DisableNamechecking
Pop-Location

if (!$Hostname) {
    $sqlInstance = Get-SQLInstance
    $Hostname = $sqlInstance.FullName
}

if (!$Username){
    $Username = $null
    $Password = $null
}

$SqlResult = $null

try {
    $sql = "select * from sys.server_principals where name='$Account'" 
    $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
}
catch { 
    throw "Unable to add user account to SQL Server due to exception: $($_.Exception)" 
}

if (!$SqlResult){
    #Create account as it does not exist
    try {
        $sql = "CREATE LOGIN [$Account] FROM WINDOWS;" 
        $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
    }
    catch { 
        throw "Unable to add user account to SQL Server due to exception: $($_.Exception)" 
    }
}

$Roles | %{
    $Role = $_

    try {
        $sql = @"
SELECT sys.server_role_members.role_principal_id, role.name AS RoleName,   
    sys.server_role_members.member_principal_id, member.name AS MemberName  
FROM sys.server_role_members  
JOIN sys.server_principals AS role  
    ON sys.server_role_members.role_principal_id = role.principal_id  
JOIN sys.server_principals AS member  
    ON sys.server_role_members.member_principal_id = member.principal_id
WHERE
    role.Name='$Role' AND member.name = '$Account';
"@        

        $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
    }
    catch { 
        throw "Unable to get server role for user account due to exception: $($_.Exception)" 
    }

    if (!$SqlResult){
        #Create account as it does not exist
        try {
            $sql = "EXEC master..sp_addsrvrolemember @loginame = N'$Account', @rolename = N'$Role';"
            $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
        }
        catch { 
            throw "Unable to add user account to server role to SQL Role due to exception: $($_.Exception)" 
        }
    }
}
  EOH
  guard_interpreter :powershell_script
  only_if <<-EOH
$ErrorActionPreference = "Stop"

Function Get-SQLInstance {  
    <#
        .SYNOPSIS
            Retrieves SQL server information from a local or remote servers.

        .DESCRIPTION
            Retrieves SQL server information from a local or remote servers. Pulls all 
            instances from a SQL server and detects if in a cluster or not.

        .PARAMETER Computername
            Local or remote systems to query for SQL information.

        .NOTES
            Name: Get-SQLInstance
            Author: Boe Prox
            DateCreated: 07 SEPT 2013

        .EXAMPLE
            Get-SQLInstance -Computername DC1

            SQLInstance   : MSSQLSERVER
            Version       : 10.0.1600.22
            isCluster     : False
            Computername  : DC1
            FullName      : DC1
            isClusterNode : False
            Edition       : Enterprise Edition
            ClusterName   : 
            ClusterNodes  : {}
            Caption       : SQL Server 2008

            SQLInstance   : MINASTIRITH
            Version       : 10.0.1600.22
            isCluster     : False
            Computername  : DC1
            FullName      : DC1\MINASTIRITH
            isClusterNode : False
            Edition       : Enterprise Edition
            ClusterName   : 
            ClusterNodes  : {}
            Caption       : SQL Server 2008

            Description
            -----------
            Retrieves the SQL information from DC1
    #>
    [cmdletbinding()] 
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('__Server','DNSHostName','IPAddress')]
        [string[]]$ComputerName = $env:COMPUTERNAME
    ) 
    Process {
        ForEach ($Computer in $Computername) {
            $Computer = $computer -replace '(.*?)\..+','$1'
            Write-Verbose ("Checking {0}" -f $Computer)
            Try { 
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer) 
                $baseKeys = "SOFTWARE\\Microsoft\\Microsoft SQL Server",
                "SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server"
                If ($reg.OpenSubKey($basekeys[0])) {
                    $regPath = $basekeys[0]
                } ElseIf ($reg.OpenSubKey($basekeys[1])) {
                    $regPath = $basekeys[1]
                } Else {
                    Continue
                }
                $regKey= $reg.OpenSubKey("$regPath")
                If ($regKey.GetSubKeyNames() -contains "Instance Names") {
                    $regKey= $reg.OpenSubKey("$regpath\\Instance Names\\SQL" ) 
                    $instances = @($regkey.GetValueNames())
                } ElseIf ($regKey.GetValueNames() -contains 'InstalledInstances') {
                    $isCluster = $False
                    $instances = $regKey.GetValue('InstalledInstances')
                } Else {
                    Continue
                }
                If ($instances.count -gt 0) { 
                    ForEach ($instance in $instances) {
                        $nodes = New-Object System.Collections.Arraylist
                        $clusterName = $Null
                        $isCluster = $False
                        $instanceValue = $regKey.GetValue($instance)
                        $instanceReg = $reg.OpenSubKey("$regpath\\$instanceValue")
                        If ($instanceReg.GetSubKeyNames() -contains "Cluster") {
                            $isCluster = $True
                            $instanceRegCluster = $instanceReg.OpenSubKey('Cluster')
                            $clusterName = $instanceRegCluster.GetValue('ClusterName')
                            $clusterReg = $reg.OpenSubKey("Cluster\\Nodes")                            
                            $clusterReg.GetSubKeyNames() | ForEach {
                                $null = $nodes.Add($clusterReg.OpenSubKey($_).GetValue('NodeName'))
                            }
                        }
                        $instanceRegSetup = $instanceReg.OpenSubKey("Setup")
                        Try {
                            $edition = $instanceRegSetup.GetValue('Edition')
                        } Catch {
                            $edition = $Null
                        }
                        Try {
                            $ErrorActionPreference = 'Stop'
                            #Get from filename to determine version
                            $servicesReg = $reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Services")
                            $serviceKey = $servicesReg.GetSubKeyNames() | Where {
                                $_ -match "$instance"
                            } | Select -First 1
                            $service = $servicesReg.OpenSubKey($serviceKey).GetValue('ImagePath')
                            $file = $service -replace '^.*(\w:\\.*\\sqlservr.exe).*','$1'
                            $version = (Get-Item ("\\$Computer\$($file -replace ":","$")")).VersionInfo.ProductVersion
                        } Catch {
                            #Use potentially less accurate version from registry
                            $Version = $instanceRegSetup.GetValue('Version')
                        } Finally {
                            $ErrorActionPreference = 'Continue'
                        }
                        New-Object PSObject -Property @{
                            Computername = $Computer
                            SQLInstance = $instance
                            Edition = $edition
                            Version = $version
                            Caption = {Switch -Regex ($version) {
                                "^16" {'SQL Server 2016';Break}
                                "^14" {'SQL Server 2014';Break}
                                "^11" {'SQL Server 2012';Break}
                                "^10\.5" {'SQL Server 2008 R2';Break}
                                "^10" {'SQL Server 2008';Break}
                                "^9"  {'SQL Server 2005';Break}
                                "^8"  {'SQL Server 2000';Break}
                                Default {'Unknown'}
                            }}.InvokeReturnAsIs()
                            isCluster = $isCluster
                            isClusterNode = ($nodes -contains $Computer)
                            ClusterName = $clusterName
                            ClusterNodes = ($nodes -ne $Computer)
                            FullName = {
                                If ($Instance -eq 'MSSQLSERVER') {
                                    $Computer
                                } Else {
                                    "$($Computer)\$($instance)"
                                }
                            }.InvokeReturnAsIs()
                        }
                    }
                }
            } Catch { 
                Write-Warning ("{0}: {1}" -f $Computer,$_.Exception.Message)
            }  
        }   
    }
}

function Invoke-SafeSqlcmd($ServerInstance, $Username, $Password, $Query) {
    if (!$Username) {
        if (!$ServerInstance) {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $Query
        } else {
            return Invoke-Sqlcmd -Query $Query
        }
    } else {
        if (!$ServerInstance) {
            return Invoke-Sqlcmd -ServerInstance $ServerInstance -Username $Username -Password $Password -Query $Query
        } else {
            return Invoke-Sqlcmd -Username $Username -Password $Password -Query $Query
        }
    }
}

$Hostname = '#{node['windowsservicebus']['database']['host']}'
$Username = '#{node['windowsservicebus']['database']['username']}'
$Password = '#{node['windowsservicebus']['database']['password']}'
$Account = '#{node['windowsservicebus']['database']['account']}''
$Roles = @(#{node['windowsservicebus']['database']['sys_roles'].map { |i| "'" + i.to_s + "'" }.join(",")})

$MicrosoftSqlPath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft SQL Server'

$SqlPsPath = Get-ChildItem $MicrosoftSqlPath -recurse -Filter "SQLPS" -Exclude @("Data", "JOBS", "Log") -ErrorAction SilentlyContinue | Select-Object -Last 1

if (!($SqlPsPath)){
    throw "No SQLPS directory detected. Please install SQLPS."
}
    
$SqlPsPath = $SqlPsPath.FullName

Push-Location
Import-Module $SqlPsPath -DisableNamechecking
Pop-Location

if (!$Hostname) {
    $sqlInstance = Get-SQLInstance
    $Hostname = $sqlInstance.FullName
}

if (!$Username){
    $Username = $null
    $Password = $null
}

$SqlResult = $null

try {
    $sql = "select * from sys.server_principals where name='$Account'" 
    $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
}
catch { 
    throw "Unable to add user account to SQL Server due to exception: $($_.Exception)" 
}

if (!$SqlResult){
    return $true
}

$Roles | %{
    $Role = $_

    try {
        $sql = @"
SELECT sys.server_role_members.role_principal_id, role.name AS RoleName,   
    sys.server_role_members.member_principal_id, member.name AS MemberName  
FROM sys.server_role_members  
JOIN sys.server_principals AS role  
    ON sys.server_role_members.role_principal_id = role.principal_id  
JOIN sys.server_principals AS member  
    ON sys.server_role_members.member_principal_id = member.principal_id
WHERE
    role.Name='$Role' AND member.name = '$Account';
"@        

        $SqlResult = Invoke-SafeSqlcmd -ServerInstance $Hostname -Username $Username -Password $Password -Query $sql
    }
    catch { 
        throw "Unable to get server role for user account due to exception: $($_.Exception)" 
    }

    if (!$SqlResult){
        return $true
    }
}  

return $false
  EOH
end