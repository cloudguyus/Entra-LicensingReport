# Entra-LicensingReport

PowerShell tooling to report Microsoft 365 / Entra tenant licensing inventory (purchased vs assigned), with friendly product names from Microsoft’s official mapping CSV.

## Scripts

| Location | Description |
|----------|-------------|
| **[standalone/](standalone/)** | **Recommended for sharing.** Connects to Microsoft Graph, prints a table, optional CSV export. Requires PowerShell 7.2+. See [standalone/README.md](standalone/README.md). |
| [Get-LicensingReportV2.ps1](Get-LicensingReportV2.ps1) | Original script. Expects an existing Graph session (`Connect-MgGraph` already done). Left unchanged for known-good use. |

## Quick start (standalone)

```powershell
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser

cd ./standalone
./Get-LicensingReport.ps1 -OutputPath ./LicensingReport.csv
```

Requires **PowerShell 7.2+** and Graph permission **Organization.Read.All**. Details, auth modes, and troubleshooting: [standalone/README.md](standalone/README.md).
