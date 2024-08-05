# Powershell Profile

Add following lines to current user profile to avoid providing scope each time `install` is executed:


```powershell
$PSDefaultParameterValues['Install-Module:Scope'] = 'CurrentUser'
```

Make sure the execution policy was set to allow code execution (require `admin` rights):

```powershell
Set-ExecutionPolicy RemoteSigned
```


## PSScriptAnalyzer

PSScriptAnalyzer is a static code checker for PowerShell modules and scripts that can be integrated into pre-commit hooks.

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

To analyze existing modules (from current working directory):

```powershell
powershell.exe -Command "Import-Module PSScriptAnalyzer; Invoke-ScriptAnalyzer -Path . -Recurse"
```

Sample output:

```
RuleName                            Severity     ScriptName Line  Message
--------                            --------     ---------- ----  -------
PSAvoidUsingWriteHost               Warning      Export-Roo 54    File 'Export-RootCACerts.ps1' uses Write-Host. Avoid using
                                                 tCACerts.p       Write-Host because it might not work in all hosts, does not
                                                 s1               work when there is no host, and (prior to PS 5.0) cannot be
                                                                  suppressed, captured, or redirected. Instead, use
                                                                  Write-Output, Write-Verbose, or Write-Information.
PSAvoidUsingWriteHost               Warning      Export-Roo 61    File 'Export-RootCACerts.ps1' uses Write-Host. Avoid using
                                                 tCACerts.p       Write-Host because it might not work in all hosts, does not
                                                 s1               work when there is no host, and (prior to PS 5.0) cannot be
                                                                  suppressed, captured, or redirected. Instead, use
                                                                  Write-Output, Write-Verbose, or Write-Information.
PSUseSingularNouns                  Warning      Export-Roo 23    The cmdlet 'Export-RootCACerts' uses a plural noun. A
                                                 tCACerts.p       singular noun should be used instead.
                                                 s1
```


# Resources
- Format code with [PowerShell-Beautifier](https://github.com/DTW-DanWard/PowerShell-Beautifier)
