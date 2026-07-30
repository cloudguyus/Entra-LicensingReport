function Get-M365LicensingTable {
    param(
    )
    # Download and parse the CSV mapping file
    $csvUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"
    try {
        mkdir "LicensingTableDownload"
        Invoke-WebRequest -Uri $csvUrl -UseBasicParsing -OutFile .\LicensingTableDownload\M365LicensingTable.CSV
        $M365LicensingTable = Import-Csv .\LicensingTableDownload\M365LicensingTable.csv
        Remove-Item -Path .\LicensingTableDownload\M365LicensingTable.csv
        Remove-Item "LicensingTableDownload" 
        Return $M365LicensingTable;
    }
    catch {
        Write-Error "Failed to retrieve or parse the CSV file. Please check your internet connection or the URL."
    }
}
function Get-M365TenantSkus {
    # Retrieve all subscribed SKUs
    try {
        $MsolSkusRAW = Get-MgSubscribedSku -All -Property @("SkuId", "SkuPartNumber", "ConsumedUnits", "PrepaidUnits") | 
        Select-Object *, @{Name = "ActiveUnits"; Expression = { $_.PrepaidUnits.Enabled } } |
        Select-Object SkuId, SkuPartNumber, ActiveUnits, ConsumedUnits
        return $MsolSkusRAW;
    }
    catch {
        Write-Output -InputObject "No Connection to Microsoft Graph Found!"
    }
}
function Get-M365LicensingUsage{
    param (
        [Parameter(Mandatory)]
        [array]
        $M365LicensingTable,
        [Parameter(Mandatory)]
        [array]
        $TenantSkus
    )

    $friendlyNameLookup = @{}
    foreach ($row in $M365LicensingTable) {
        if ($row.GUID) {
            # or $row.SkuId — use your actual column name
            $friendlyNameLookup[$row.GUID] = $row.Product_Display_Name
        }
    }
    # Initialize an array to hold the cleaned SKU data
    $M365LicensingUsage = @()

    # Process each SKU and map to its friendly name
    foreach ($sku in $TenantSkus) {
        $friendlyName = if ($friendlyNameLookup.ContainsKey($sku.SkuId)) {
            $friendlyNameLookup[$sku.SkuId]
        }
        else {
            $sku.SkuPartNumber
        }
        # Calculate percentage used, handling division by zero
        $percentageUsed = if ($sku.ActiveUnits -ne 0) {
            "{0:P2}" -f ($sku.ConsumedUnits / $sku.ActiveUnits)
        }
        else {
            "N/A"
        }

        # Create a custom object for the SKU
        $item = [PSCustomObject]@{
            SkuId          = $sku.SkuId
            SkuPartNumber  = $friendlyName
            ConsumedUnits  = $sku.ConsumedUnits
            PurchasedUnits = $sku.ActiveUnits
            PercentageUsed = $percentageUsed
        }

        # Add the item to the array
        $M365LicensingUsage += $item
    }

    # Return the cleaned SKU data
    return $M365LicensingUsage
}
function Get-M365TenantLicensingUsage {
    param (
    )
$M365LicensingTable = Get-M365LicensingTable
$TenantLicensing = Get-M365TenantSkus
Get-M365LicensingUsage -M365LicensingTable $M365LicensingTable -TenantSkus $TenantLicensing
}
Get-M365TenantLicensingUsage