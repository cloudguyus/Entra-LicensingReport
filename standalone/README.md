# Get-M365LicensingReport (standalone)

A shareable PowerShell script that reports Microsoft 365 / Entra **tenant licensing status** for the signed-in tenant: purchased, assigned (consumed), available, and percent used — with Microsoft’s official friendly product names.

This folder is the **self-contained** version intended for other admins to run. The original working script remains at the repository root (`Get-LicensingReportV2.ps1`).

## Install from the PowerShell Gallery

Once published (see [Publishing](#publishing-to-the-powershell-gallery) below):

```powershell
Install-Script -Name Get-M365LicensingReport -Scope CurrentUser
# Ensure Graph modules are available
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser

Get-M365LicensingReport.ps1 -OutputPath ./LicensingReport.csv
```

Scripts install under your PowerShell scripts path (for example `~/Documents/PowerShell/Scripts` on macOS/Linux, or the equivalent under Documents on Windows). That path is normally on `$env:PATH` after install.

## What you get

| Column | Description |
|--------|-------------|
| `ProductName` | Friendly name from Microsoft’s product-names CSV |
| `SkuPartNumber` | Raw SKU part number (e.g. `ENTERPRISEPACK`) |
| `SkuId` | SKU GUID |
| `PurchasedUnits` | Prepaid **Enabled** units |
| `ConsumedUnits` | Assigned licenses |
| `AvailableUnits` | Purchased − Consumed |
| `SuspendedUnits` | Prepaid suspended units |
| `WarningUnits` | Prepaid warning units |
| `PercentageUsed` | Numeric percent (consumed ÷ purchased × 100), or empty if purchased is 0 |

This is a **tenant SKU inventory** report. It does not list per-user assignments, last sign-in, or cost.

## Prerequisites

1. **PowerShell 7.2 or later** (Windows, macOS, or Linux — required; Windows PowerShell 5.1 is not supported)
2. **Microsoft Graph PowerShell** modules:

   ```powershell
   Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser
   ```

3. **Microsoft Graph permission:** `Organization.Read.All`
   - Interactive / device code: consent when prompted (or pre-consent as admin)
   - Managed identity / app: grant **application** permission `Organization.Read.All` and admin-consent
4. Network access to:
   - Microsoft Graph (`graph.microsoft.com`)
   - Microsoft’s product-names download (for friendly names)

**Least privilege:** Global Reader (or any role that can read organization subscribed SKUs) is enough. Global Admin is not required for the report itself (only for first-time admin consent if your tenant requires it).

## Quick start

```powershell
cd path/to/Entra-LicensingReport/standalone
./Get-M365LicensingReport.ps1
```

Sign in with an account that has access to the target tenant. The script prints a table and also returns objects to the pipeline.

### Export CSV

```powershell
./Get-M365LicensingReport.ps1 -OutputPath ./LicensingReport.csv
```

### Specific tenant

```powershell
./Get-M365LicensingReport.ps1 -TenantId contoso.onmicrosoft.com -OutputPath ./contoso-licenses.csv
```

### Device code (remote / no browser UI)

```powershell
./Get-M365LicensingReport.ps1 -AuthMode DeviceCode
```

### Existing Graph session

```powershell
Connect-MgGraph -Scopes 'Organization.Read.All'
./Get-M365LicensingReport.ps1 -AuthMode None -OutputPath ./report.csv
```

### Managed identity (Azure Automation, VM, App Service)

```powershell
./Get-M365LicensingReport.ps1 -AuthMode ManagedIdentity -OutputPath ./LicensingReport.csv
```

Ensure the identity has **application** permission `Organization.Read.All` on Microsoft Graph (admin consented).

### Disconnect when finished

```powershell
./Get-M365LicensingReport.ps1 -OutputPath ./report.csv -Disconnect
```

`-Disconnect` only ends the session if **this script** created the connection (not when `-AuthMode None`).

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-TenantId` | _(none)_ | Tenant GUID or verified domain for `Connect-MgGraph` |
| `-AuthMode` | `Interactive` | `Interactive`, `DeviceCode`, `ManagedIdentity`, or `None` |
| `-ClientId` | _(Graph PowerShell app)_ | Optional custom public client ID |
| `-OutputPath` | _(none)_ | Write UTF-8 CSV to this path |
| `-Disconnect` | off | Disconnect Graph if this script connected |

## How it works

1. Connects to Microsoft Graph (unless `-AuthMode None`).
2. Downloads Microsoft’s [Product names and service plan identifiers for licensing](https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference) CSV to a temp file, imports it, then deletes the temp file.
3. Reads all subscribed SKUs via `Get-MgSubscribedSku`.
4. Maps `SkuId` → `Product_Display_Name`, computes available units and percent used.
5. Prints a summary table, optionally exports CSV, and returns full objects.

## Capturing output in scripts

The host table is written with `Out-Host` so it does not pollute the pipeline. Pipeline objects are the full report:

```powershell
$report = ./Get-M365LicensingReport.ps1 -AuthMode None
$report | Where-Object { $_.AvailableUnits -lt 5 } | Format-Table ProductName, AvailableUnits
```

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Module / `#Requires` errors | Install PowerShell 7.2+ and the modules listed above |
| Consent / 403 on SKUs | Grant or consent `Organization.Read.All`; confirm the account can read org licenses |
| “No active Microsoft Graph connection” | Use default Interactive mode, or `Connect-MgGraph` then `-AuthMode None` |
| Product CSV download failed | Firewall/proxy blocking `download.microsoft.com`; URL may have changed — update `$script:ProductNamesCsvUrl` in the script |
| Friendly name falls back to part number | SKU not in Microsoft’s CSV yet; raw `SkuPartNumber` is still correct |
| Managed identity fails | App role `Organization.Read.All` assigned to the identity and admin-consented |

## Relation to root script

| Path | Role |
|------|------|
| `../Get-LicensingReportV2.ps1` | Original script (unchanged); assumes Graph is already connected |
| `./Get-M365LicensingReport.ps1` | Standalone version with connect, export, and clearer output |

## Publishing to the PowerShell Gallery (local)

This script is packaged as a **Gallery script**: metadata lives in the `<#PSScriptInfo ... #>` block at the top of `Get-M365LicensingReport.ps1`.

| Field | Notes |
|-------|--------|
| Gallery name | File name without extension: **`Get-M365LicensingReport`** |
| Version | `.VERSION` in `PSScriptInfo` (bump for every publish; Gallery rejects reuse) |
| GUID | Stable forever — do not regenerate after first publish |
| Dependencies | Declared in `.EXTERNALMODULEDEPENDENCIES` |

### One-time setup

1. Create a [PowerShell Gallery](https://www.powershellgallery.com/) account.
2. Create an API key under account settings.
3. Keep the key out of git (use an environment variable or secret store).

### Publish from your machine

```powershell
# From the repository root (PowerShell 7.2+)
# Optional: install/update PowerShellGet if needed
# Install-Module PowerShellGet -Force -AllowClobber -Scope CurrentUser

Test-ScriptFileInfo -Path ./standalone/Get-M365LicensingReport.ps1

# Prefer env var so the key is not in shell history as often
$env:PSGALLERY_API_KEY = 'your-api-key-here'   # or set this outside the session

Publish-Script `
  -Path ./standalone/Get-M365LicensingReport.ps1 `
  -NuGetApiKey $env:PSGALLERY_API_KEY `
  -Repository PSGallery
```

After a successful publish:

```powershell
Find-Script -Name Get-M365LicensingReport -Repository PSGallery
Install-Script -Name Get-M365LicensingReport -Scope CurrentUser
```

### Updating a later version

1. Bump `.VERSION` in the `PSScriptInfo` block (e.g. `1.0.0` → `1.0.1`).
2. Update `.RELEASENOTES` if useful.
3. Leave the **GUID** unchanged.
4. Run `Test-ScriptFileInfo` and `Publish-Script` again.

## License

Same as the repository root (`LICENSE`).
