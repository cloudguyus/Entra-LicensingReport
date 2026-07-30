<#PSScriptInfo
.VERSION 1.0.0
.GUID 8e6c8ab7-0ea3-4749-bde0-f9b090d2794d
.AUTHOR cloudguyus
.COMPANYNAME
.COPYRIGHT
.TAGS Microsoft365 Entra Graph Licensing M365 Sku
.LICENSEURI https://github.com/cloudguyus/Entra-LicensingReport/blob/main/LICENSE
.PROJECTURI https://github.com/cloudguyus/Entra-LicensingReport
.ICONURI
.EXTERNALMODULEDEPENDENCIES Microsoft.Graph.Authentication,Microsoft.Graph.Identity.DirectoryManagement
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
Initial release as Get-M365LicensingReport. Graph-connected M365/Entra licensing inventory with optional CSV export.
.PRIVATEDATA
#>

#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement

<#
.SYNOPSIS
    Reports Microsoft 365 / Entra subscribed SKU licensing usage for a tenant.

.DESCRIPTION
    Connects to Microsoft Graph, downloads Microsoft's product-name mapping CSV,
    and returns (and optionally exports) license inventory: purchased, consumed,
    available, and percent used — with friendly product names.

    Requires PowerShell 7.2 or later (Windows, macOS, or Linux).

    Install from the PowerShell Gallery (after publish):
      Install-Script -Name Get-M365LicensingReport -Scope CurrentUser

.PARAMETER TenantId
    Optional Entra tenant ID (GUID) or verified domain. Used when connecting.

.PARAMETER AuthMode
    How to authenticate to Microsoft Graph:
      Interactive     - Browser sign-in (default)
      DeviceCode      - Device code flow (headless / remote sessions)
      ManagedIdentity - Azure managed identity (Automation, VM, App Service)
      None            - Use an existing Connect-MgGraph session

.PARAMETER ClientId
    Optional app (client) ID for Interactive or DeviceCode when using a
    custom public client registration. Defaults to the Microsoft Graph
    PowerShell multi-tenant app when omitted.

.PARAMETER OutputPath
    Optional path to write a CSV report (e.g. ./LicensingReport.csv).

.PARAMETER Disconnect
    Disconnect the Graph session when the script finishes (only if this
    script established the connection).

.EXAMPLE
    ./Get-M365LicensingReport.ps1

    Interactive sign-in; prints a table to the host.

.EXAMPLE
    Get-M365LicensingReport.ps1 -TenantId contoso.onmicrosoft.com -OutputPath ./report.csv

.EXAMPLE
    Connect-MgGraph -Scopes 'Organization.Read.All'
    Get-M365LicensingReport.ps1 -AuthMode None

.EXAMPLE
    Get-M365LicensingReport.ps1 -AuthMode ManagedIdentity -OutputPath ./report.csv
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [ValidateSet('Interactive', 'DeviceCode', 'ManagedIdentity', 'None')]
    [string]$AuthMode = 'Interactive',

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$Disconnect
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Graph permission required for Get-MgSubscribedSku
$script:RequiredScopes = @('Organization.Read.All')

# Official Microsoft product names / service plan identifiers CSV
$script:ProductNamesCsvUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'

$script:ConnectedByThisScript = $false

function Connect-LicensingReportGraph {
    [CmdletBinding()]
    param(
        [string]$TenantId,
        [ValidateSet('Interactive', 'DeviceCode', 'ManagedIdentity', 'None')]
        [string]$AuthMode,
        [string]$ClientId
    )

    if ($AuthMode -eq 'None') {
        $context = Get-MgContext
        if (-not $context) {
            throw "AuthMode is 'None' but there is no active Microsoft Graph connection. Run Connect-MgGraph first, or use -AuthMode Interactive."
        }
        Write-Verbose "Using existing Graph session for tenant '$($context.TenantId)' as '$($context.Account)'."
        return
    }

    $connectParams = @{
        NoWelcome = $true
    }

    if ($TenantId) {
        $connectParams['TenantId'] = $TenantId
    }

    if ($ClientId) {
        $connectParams['ClientId'] = $ClientId
    }

    switch ($AuthMode) {
        'Interactive' {
            $connectParams['Scopes'] = $script:RequiredScopes
            Write-Verbose 'Connecting to Microsoft Graph (interactive)...'
        }
        'DeviceCode' {
            $connectParams['Scopes'] = $script:RequiredScopes
            $connectParams['UseDeviceCode'] = $true
            Write-Verbose 'Connecting to Microsoft Graph (device code)...'
        }
        'ManagedIdentity' {
            $connectParams['Identity'] = $true
            Write-Verbose 'Connecting to Microsoft Graph (managed identity)...'
        }
    }

    try {
        Connect-MgGraph @connectParams | Out-Null
    }
    catch {
        throw "Failed to connect to Microsoft Graph ($AuthMode). $_"
    }

    $script:ConnectedByThisScript = $true
    $context = Get-MgContext
    if (-not $context) {
        throw 'Connect-MgGraph completed but no Graph context is available.'
    }

    Write-Verbose "Connected to tenant '$($context.TenantId)'."
}

function Get-M365LicensingTable {
    [CmdletBinding()]
    param()

    $tempFile = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("M365LicensingTable_{0}.csv" -f [guid]::NewGuid().ToString('N'))

    try {
        Write-Verbose 'Downloading product names CSV from Microsoft...'
        Invoke-WebRequest -Uri $script:ProductNamesCsvUrl -UseBasicParsing -OutFile $tempFile

        $table = Import-Csv -LiteralPath $tempFile
        if (-not $table -or @($table).Count -eq 0) {
            throw 'Product names CSV downloaded but contained no rows.'
        }

        $sample = $table | Select-Object -First 1
        $props = $sample.PSObject.Properties.Name
        foreach ($required in @('GUID', 'Product_Display_Name')) {
            if ($props -notcontains $required) {
                throw "Product names CSV is missing expected column '$required'. Columns found: $($props -join ', ')"
            }
        }

        return $table
    }
    catch {
        throw "Failed to retrieve or parse Microsoft product names CSV from '$($script:ProductNamesCsvUrl)'. $_"
    }
    finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-M365TenantSkus {
    [CmdletBinding()]
    param()

    try {
        $skus = Get-MgSubscribedSku -All -Property @('SkuId', 'SkuPartNumber', 'ConsumedUnits', 'PrepaidUnits')
    }
    catch {
        throw "Failed to read subscribed SKUs from Microsoft Graph. Ensure you are connected and have Organization.Read.All. $_"
    }

    if (-not $skus) {
        Write-Warning 'No subscribed SKUs were returned for this tenant.'
        return @()
    }

    foreach ($sku in $skus) {
        [PSCustomObject]@{
            SkuId          = $sku.SkuId
            SkuPartNumber  = $sku.SkuPartNumber
            ConsumedUnits  = [int]$sku.ConsumedUnits
            EnabledUnits   = [int]$(if ($null -ne $sku.PrepaidUnits.Enabled) { $sku.PrepaidUnits.Enabled } else { 0 })
            SuspendedUnits = [int]$(if ($null -ne $sku.PrepaidUnits.Suspended) { $sku.PrepaidUnits.Suspended } else { 0 })
            WarningUnits   = [int]$(if ($null -ne $sku.PrepaidUnits.Warning) { $sku.PrepaidUnits.Warning } else { 0 })
        }
    }
}

function Get-M365LicensingUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$M365LicensingTable,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$TenantSkus
    )

    $friendlyNameLookup = @{}
    foreach ($row in $M365LicensingTable) {
        if ($row.GUID) {
            $friendlyNameLookup[$row.GUID] = $row.Product_Display_Name
        }
    }

    $usage = foreach ($sku in $TenantSkus) {
        $productName = if ($friendlyNameLookup.ContainsKey([string]$sku.SkuId)) {
            $friendlyNameLookup[[string]$sku.SkuId]
        }
        else {
            $sku.SkuPartNumber
        }

        $enabled = [int]$sku.EnabledUnits
        $consumed = [int]$sku.ConsumedUnits
        $available = $enabled - $consumed

        $percentageUsed = if ($enabled -ne 0) {
            [math]::Round(($consumed / $enabled) * 100, 2)
        }
        else {
            $null
        }

        [PSCustomObject]@{
            ProductName    = $productName
            SkuPartNumber  = $sku.SkuPartNumber
            SkuId          = $sku.SkuId
            PurchasedUnits = $enabled
            ConsumedUnits  = $consumed
            AvailableUnits = $available
            SuspendedUnits = [int]$sku.SuspendedUnits
            WarningUnits   = [int]$sku.WarningUnits
            PercentageUsed = $percentageUsed
        }
    }

    # Sort by product name for a stable, readable report
    $usage | Sort-Object -Property ProductName
}

function Export-LicensingReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Report,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $directory = Split-Path -Parent -Path $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $Report | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding utf8
    Write-Host "Report exported to: $Path"
}

# --- Main ---
try {
    Connect-LicensingReportGraph -TenantId $TenantId -AuthMode $AuthMode -ClientId $ClientId

    $licensingTable = Get-M365LicensingTable
    $tenantSkus = @(Get-M365TenantSkus)
    $report = @(Get-M365LicensingUsage -M365LicensingTable $licensingTable -TenantSkus $tenantSkus)

    if ($OutputPath) {
        Export-LicensingReport -Report $report -Path $OutputPath
    }

    # Host-friendly view; full objects still returned for piping
    $report |
        Select-Object ProductName, SkuPartNumber, PurchasedUnits, ConsumedUnits, AvailableUnits, PercentageUsed |
        Format-Table -AutoSize |
        Out-Host

    # Return objects to the pipeline for further processing
    $report
}
finally {
    if ($Disconnect -and $script:ConnectedByThisScript) {
        Write-Verbose 'Disconnecting Microsoft Graph session...'
        Disconnect-MgGraph | Out-Null
    }
}
