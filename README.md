# Entra-LicensingReport

PowerShell tooling to report Microsoft 365 / Entra **tenant licensing inventory** (purchased vs assigned), with friendly product names.

There are three entry points. Pick the one that matches how controlled your license catalog is and whether you need Graph connect/export built in.

## Which script should I use?

| Script | Friendly names | Graph connection | Best for |
|--------|----------------|------------------|----------|
| **[standalone/](standalone/)** | Downloads Microsoft’s product-names CSV each run | Built in (Interactive, DeviceCode, ManagedIdentity, or existing session) | Sharing with other admins; unknown or changing SKU catalogs; CSV export |
| **[Get-LicensingReportV2.ps1](Get-LicensingReportV2.ps1)** | Downloads Microsoft’s product-names CSV each run | You connect first (`Connect-MgGraph`) | Local/Automation helpers when Graph is already connected |
| **[Get-LicensingReport-V1.ps1](Get-LicensingReport-V1.ps1)** | **Sample** hardcoded map of `SkuPartNumber` → display name (no CSV download) | Managed identity (`Connect-MgGraph -Identity`) | Tenants with **tight control** over which licenses are purchased; offline-friendly name mapping; Automation + email report pattern |

**Rule of thumb**

- **Loose or evolving purchases / multi-tenant / public share** → use **standalone** (or V2 if you already handle auth).
- **You only buy a known, stable set of SKUs and maintain that list** → **V1** is appropriate: no dependency on Microsoft’s downloadable licensing table, and unknown SKUs simply do not appear in the report.

**V1 is a sample.** The embedded SKU map, recipients, and automation account are examples—change them for your tenant and procurement list.

---

## Repository layout

| Path | Role |
|------|------|
| [standalone/Get-LicensingReport.ps1](standalone/Get-LicensingReport.ps1) | Shareable end-to-end report (PowerShell 7.2+) |
| [standalone/README.md](standalone/README.md) | Full docs for the standalone script (auth, parameters, troubleshooting) |
| [Get-LicensingReportV2.ps1](Get-LicensingReportV2.ps1) | Modular V2 helper: download map → get SKUs → join usage |
| [Get-LicensingReport-V1.ps1](Get-LicensingReport-V1.ps1) | V1 **sample**: embedded friendly-name map, managed identity, HTML email report (customize for your tenant) |

---

## Standalone (recommended for sharing)

Self-contained script for other tenants: connects to Graph, maps SKUs via Microsoft’s official CSV, prints a table, optionally writes CSV.

### Prerequisites

- PowerShell **7.2+** (Windows, macOS, or Linux)
- Modules: `Microsoft.Graph.Authentication`, `Microsoft.Graph.Identity.DirectoryManagement`
- Graph permission: **`Organization.Read.All`**
- Network access to Graph and Microsoft’s product-names download

```powershell
Install-Module Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement -Scope CurrentUser

cd ./standalone
./Get-LicensingReport.ps1 -OutputPath ./LicensingReport.csv
```

Other modes: `-AuthMode DeviceCode`, `-AuthMode ManagedIdentity`, `-AuthMode None` (existing session), `-TenantId`, `-Disconnect`.

Details: **[standalone/README.md](standalone/README.md)**.

### Report columns (standalone)

| Column | Description |
|--------|-------------|
| `ProductName` | Friendly name from Microsoft’s product-names CSV |
| `SkuPartNumber` | Raw SKU part number (e.g. `ENTERPRISEPACK`) |
| `SkuId` | SKU GUID |
| `PurchasedUnits` | Prepaid enabled units |
| `ConsumedUnits` | Assigned licenses |
| `AvailableUnits` | Purchased − consumed |
| `SuspendedUnits` / `WarningUnits` | Prepaid suspended / warning units |
| `PercentageUsed` | Numeric percent (or empty if purchased is 0) |

---

## V2 — dynamic product table (existing Graph session)

`Get-LicensingReportV2.ps1` downloads Microsoft’s [product names and service plan identifiers](https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference) CSV, reads `Get-MgSubscribedSku`, and returns usage with friendly names.

- **Does not** call `Connect-MgGraph` for you.
- Good when Automation or your profile already connected Graph.
- Covers any SKU present in Microsoft’s published table (not only a hand-maintained list).

```powershell
Connect-MgGraph -Scopes 'Organization.Read.All'
. ./Get-LicensingReportV2.ps1
# or run the script so Get-M365TenantLicensingUsage executes
```

Requires network access to download the product-names CSV on each run.

---

## V1 — sample with embedded friendly names (tight license control)

`Get-LicensingReport-V1.ps1` is a **sample / starting point**, not a fixed catalog for every tenant. It maps licenses with a **built-in friendly-name table** (`SkuPartNumber` → display name). It does **not** download Microsoft’s licensing table.

**Customize it for your needs:** add or remove SKUs in the map, change display names, swap auth if you are not using managed identity, and update email recipients and the sending account. The SKUs and placeholders in the repo are illustrative of one controlled-procurement pattern.

### When V1 makes sense

Use V1 (adapted to your environment) when:

- Procurement is controlled — you know exactly which SKUs the tenant buys.
- You maintain the map (or accept that only listed SKUs are reported).
- You want to avoid a dependency on the public product-names CSV (air-gapped runs, download failures, or policy).
- You run under **managed identity** and want the original Automation-style flow (connect → report → HTML email via Graph).

### Important behaviors

- Only SKUs listed in the embedded friendly-name map are included. **Unmapped SKUs are omitted** (not shown under a raw part number).
- Friendly names are whatever you put in the map; extend or trim that map as purchases change.
- Report fields: `SkuId`, friendly name (`SkuPartNumber`), `ConsumedUnits`, `PurchasedUnits`, **`AvailableUnits`** (purchased − consumed), `PercentageUsed`.
- Sample design uses `Connect-MgGraph -Identity` (managed identity); change if your host differs.
- Builds an HTML body and sends a **Tenant Licensing Report** email (sample recipients and sender in the script **must** be replaced for your environment).

### Prerequisites (V1)

- Microsoft Graph PowerShell modules appropriate for your host
- App / managed identity permissions sufficient for:
  - Reading subscribed SKUs (`Organization.Read.All` or equivalent)
  - Sending mail if you keep the email section (`Mail.Send` or your org’s equivalent)
- Friendly-name map, recipient addresses, and any Automation variables customized for your tenant

```powershell
# Typical Automation / managed-identity host
./Get-LicensingReport-V1.ps1
```

Before production use, edit the email `ToRecipients` (and any other org-specific values) in the script.

---

## Common requirements (all versions)

| Need | Notes |
|------|--------|
| Graph access to subscribed SKUs | Typically **`Organization.Read.All`** |
| Least privilege for reporting | Global Reader (or similar) is enough for inventory; admin consent may still be required once for the app |
| What these scripts do **not** do | Per-user assignment waste, last sign-in, billing/cost, or full service-plan breakdown (except as implied by the SKU) |

---

## Choosing a path (summary)

```text
Need to share with other tenants / unknown SKUs?
  └─ Yes → standalone/

Already connected to Graph, want dynamic Microsoft names?
  └─ Yes → Get-LicensingReportV2.ps1

Tight control over purchases; maintain your own name map; no CSV download?
  └─ Yes → Get-LicensingReport-V1.ps1
```

---

## License

See [LICENSE](LICENSE) if present in the repository; otherwise refer to the project’s published license on GitHub.
