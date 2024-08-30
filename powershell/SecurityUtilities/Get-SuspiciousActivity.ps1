<#
.SYNOPSIS
  Checks for suspicious activity on the system.

.DESCRIPTION
  The Get-SuspiciousActivity function checks for suspicious activity on the system by performing various checks on running processes, startup programs, installed services, and network connections. It searches for keylogger-related names and keywords to identify potential threats.

.PARAMETER KeyloggerNames
  Specifies an array of keylogger-related names or keywords to search for. The default values include "winlogon.exe", "keylogger", "keylog", "logger", "sniffer", and "watchdog".

.PARAMETER CheckProcesses
  Specifies whether to check for suspicious processes. By default, this parameter is set to $true.

.PARAMETER CheckStartup
  Specifies whether to check for suspicious startup programs. By default, this parameter is set to $true.

.PARAMETER CheckServices
  Specifies whether to check for suspicious installed services. By default, this parameter is set to $true.

.PARAMETER CheckNetwork
  Specifies whether to check for suspicious network connections. By default, this parameter is set to $true.

.OUTPUTS
  The function outputs the suspicious items found in each category, including processes, startup programs, installed services, and network connections.

.EXAMPLE
  Get-SuspiciousActivity -CheckProcesses -CheckStartup
  Checks for suspicious processes and startup programs on the system.

.EXAMPLE
  Get-SuspiciousActivity -KeyloggerNames "keylogger", "watchdog" -CheckServices
  Checks for suspicious installed services with the specified keylogger-related names.

.NOTES
  This function requires administrative privileges to access certain system information.

.LINK
  https://github.com/patryk-gpl/shell-utils/blob/main/powershell/SecurityUtilities/Get-SuspiciousActivity.ps1
#>
function Get-SuspiciousActivity {
    [CmdletBinding()]
    param (
        [string[]]$KeyloggerNames = @(
            "winlogon.exe", "keylogger", "keylog", "logger", "sniffer", "watchdog"
        ),
        [switch]$CheckProcesses = $true,
        [switch]$CheckStartup = $true,
        [switch]$CheckServices = $true,
        [switch]$CheckNetwork = $true
    )

    function Write-SectionHeader($message) {
        Write-Host "`n$message" -ForegroundColor Cyan
    }

    function Format-SuspiciousResults($results, $columns) {
        if ($results) {
            $results | Select-Object $columns | Format-Table -AutoSize
        } else {
            Write-Host "No suspicious items found." -ForegroundColor Green
        }
    }

    function Get-SuspiciousProcesses {
        Write-SectionHeader "Checking running processes..."
        $processes = Get-Process | Where-Object {
            $KeyloggerNames -contains $_.Name -or $_.Name -like "*log*"
        }
        Format-SuspiciousResults $processes @('Id', 'ProcessName')
    }

    function Get-SuspiciousStartupItems {
        Write-SectionHeader "Checking startup programs..."
        $startupItems = Get-CimInstance Win32_StartupCommand | Where-Object {
            $KeyloggerNames -contains $_.Name -or $_.Command -like "*log*"
        }
        Format-SuspiciousResults $startupItems @('Name', 'Command', 'Location')
    }

    function Get-SuspiciousServices {
        Write-SectionHeader "Checking installed services..."
        $services = Get-Service | Where-Object {
            $KeyloggerNames -contains $_.Name -or $_.DisplayName -like "*log*"
        }
        Format-SuspiciousResults $services @('Name', 'DisplayName', 'Status')
    }

    function Get-SuspiciousNetworkConnections {
        Write-SectionHeader "Checking network connections..."
        $netConnections = Get-NetTCPConnection | Where-Object {
            $_.State -eq "Established" -and $_.RemotePort -ne 443 -and $_.RemoteAddress -ne "127.0.0.1"
        }
        Format-SuspiciousResults $netConnections @('LocalAddress', 'LocalPort', 'RemoteAddress', 'RemotePort', 'State')
    }

    if ($CheckProcesses) { Get-SuspiciousProcesses }
    if ($CheckStartup) { Get-SuspiciousStartupItems }
    if ($CheckServices) { Get-SuspiciousServices }
    if ($CheckNetwork) { Get-SuspiciousNetworkConnections }

    Write-Host "`nCmdlet execution completed." -ForegroundColor Yellow
}

Export-ModuleMember -Function Get-SuspiciousActivity
