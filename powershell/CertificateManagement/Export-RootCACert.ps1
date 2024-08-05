<#
.SYNOPSIS
Exports root CA certificates based on an optional organization filter and format.

.DESCRIPTION
The Export-RootCACert function exports root CA certificates from the LocalMachine\Root certificate store. It provides an optional organization filter to export certificates belonging to a specific organization and allows selecting the export format. The exported certificates are saved with appropriate file extensions in the specified export path.

.PARAMETER OrganizationFilter
Specifies the organization name to filter the root certificates. Only certificates with a subject containing the specified organization name will be exported. This parameter is optional.

.PARAMETER ExportPath
Specifies the path where the exported certificates will be saved. The default export path is the "certs" directory in the user's profile. This parameter is optional.

.PARAMETER Format
Specifies the format for exporting certificates. Valid options are 'PEM' (default) and 'DER'. This parameter is optional.

.EXAMPLE
Export-RootCACert -OrganizationFilter "Contoso" -ExportPath "C:\Certificates" -Format "DER"
Exports root CA certificates belonging to the organization "Contoso" in DER format and saves them in the "C:\Certificates" directory.

.EXAMPLE
Export-RootCACert
Exports all root CA certificates in PEM format and saves them in the default "certs" directory in the user's profile.

#>
function Export-RootCACert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$OrganizationFilter,

        [Parameter(Mandatory=$false)]
        [string]$ExportPath = (Join-Path $env:USERPROFILE "certs"),

        [Parameter(Mandatory=$false)]
        [ValidateSet("PEM", "DER")]
        [string]$Format = "PEM"
    )

    # Ensure the export directory exists
    if (-not (Test-Path $ExportPath)) {
        New-Item -ItemType Directory -Force -Path $ExportPath | Out-Null
    }

    # Get root certificates
    $rootCerts = Get-ChildItem -Path Cert:\LocalMachine\Root

    # Apply organization filter if provided
    if ($OrganizationFilter) {
        $rootCerts = $rootCerts | Where-Object { $_.Subject -like "*O=$OrganizationFilter*" }
    }

    # Export certificates
    foreach ($cert in $rootCerts) {
        $certName = ($cert.Subject -replace '[^a-zA-Z0-9]', '_').TrimStart('_')
        $extension = if ($Format -eq "PEM") { "pem" } else { "der" }
        $certFile = Join-Path $ExportPath "$certName.$extension"

        try {
            if ($Format -eq "PEM") {
                $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                $pemContent = "-----BEGIN CERTIFICATE-----`r`n"
                $pemContent += [Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
                $pemContent += "`r`n-----END CERTIFICATE-----"
                [System.IO.File]::WriteAllText($certFile, $pemContent)
            }
            else {
                $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
                [System.IO.File]::WriteAllBytes($certFile, $certBytes)
            }
            Write-Verbose "Exported certificate: $certFile"
        }
        catch {
            Write-Error "Failed to export certificate: $($cert.Subject). Error: $_"
        }
    }

    $exportedCount = (Get-ChildItem $ExportPath -Filter "*.$extension").Count
    Write-Output "Certificate export complete. Exported $exportedCount certificates to: $ExportPath"
}
