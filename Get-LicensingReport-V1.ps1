<#  This script will pull the current licensing usage for the tenant. It is broken down in to 3 sections.
    1. Pull All of the licenses in the tenant, match them to the Friendly Name, weed out the default ones, and return the SkuID, "Friendly Name", Consumed, Purchased, Available, and Percentage Used.
    2. Pull the current Numbers of each Licensing Group within the Tenant
    3. Email a report to the selected recipients containing all of the information gathered.

    Friendly names are embedded (no Microsoft product-names CSV download). Only SKUs listed in the map are reported.
    AvailableUnits = PurchasedUnits - ConsumedUnits.
#>
#Function To Get all of the licenses in the tenant and return the Friendly Names in a Table
function Get-LicensingUsage
{
    # Only SKUs present in this map are included in the report (tight license control).
    $friendlyNames = @{
        'RMBASIC'                                              = 'Rights Management Service Basic Content Protection'
        'EXCHANGEENTERPRISE_GOV'                               = 'Exchange Online (Plan 2) for GCC'
        'PROJECTPROFESSIONAL_GOV'                              = 'Project Plan 3 for GCC'
        'EMSPREMIUM_GOV'                                       = 'Enterprise Mobility + Security G5 GCC'
        'M365_F1_GOV'                                          = 'Microsoft 365 F3 GCC'
        'MDATP_SERVER_GCC'                                     = 'Microsoft Defender for Endpoint Server GCC'
        'VISIOCLIENT_GOV'                                      = 'Visio Plan 2 for GCC'
        'PROJECTPREMIUM_GOV'                                   = 'Project Plan 5 for GCC'
        'M365_G5_GCC'                                          = 'Microsoft 365 GCC G5'
        'STANDARDPACK_GOV'                                     = 'Office 365 G1 GCC'
        'ADALLOM_STANDALONE'                                   = 'Microsoft Cloud App Security'
        'ATA'                                                  = 'Microsoft Defender for Identity'
        'Microsoft_Teams_Premium'                              = 'Microsoft Teams Premium Introductory Pricing'
        'MEETING_ROOM'                                         = 'Microsoft Teams Rooms Standard'
        'MTR_PREM'                                             = 'Teams Rooms Premium'
        'VISIOONLINE_PLAN1'                                    = 'Visio Online Plan 1'
        'PROJECTPROFESSIONAL'                                  = 'Project Plan 3'
        'SPE_F1'                                               = 'Microsoft 365 F3'
        'Microsoft_Teams_Audio_Conferencing_select_dial_out'   = 'Microsoft Teams Audio Conferencing with dial-out to USA/CAN'
        'SPE_F5_SECCOMP'                                       = 'Microsoft 365 F5 Security + Compliance Add-on'
        'VIVA'                                                 = 'Microsoft Viva Suite'
    }

    $msolSkusClean = @()
    $MsolSkusRAW = Get-MgSubscribedSKU -All -Property @('SkuId', 'SkuPartNumber', 'ConsumedUnits', 'PrepaidUnits') |
        Select-Object *, @{ Name = 'ActiveUnits'; Expression = { ($_ | Select-Object -ExpandProperty PrepaidUnits).Enabled } } |
        Select-Object SkuId, SkuPartNumber, ActiveUnits, ConsumedUnits

    # Matching the Raw Sku Data to the Friendly Name of the Sku (embedded map; no CSV download)
    # Reference: https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference
    foreach ($sku in $MsolSkusRAW)
    {
        if (-not $friendlyNames.ContainsKey($sku.SkuPartNumber))
        {
            continue
        }

        $purchased = [int]$sku.ActiveUnits
        $consumed = [int]$sku.ConsumedUnits
        $available = $purchased - $consumed

        $percentageUsed = if ($purchased -ne 0)
        {
            ($consumed / $purchased).ToString('P')
        }
        else
        {
            'N/A'
        }

        $item = [PSCustomObject]@{
            SkuId           = $sku.SkuId
            SkuPartNumber   = $friendlyNames[$sku.SkuPartNumber]
            ConsumedUnits   = $consumed
            PurchasedUnits  = $purchased
            AvailableUnits  = $available
            PercentageUsed  = $percentageUsed
        }
        $msolSkusClean += $item
    }

    return $msolSkusClean
}
# This function gets back all of the Licensing Groups within the tenant and returns the Name, Description, and Number of Users in the Group.
function  Connect-ToTenant
{
    try {
        # Get token and connect to MgGraph
        Connect-MgGraph -Identity
    } catch {
        Write-Host "Could Not Connect to the Tenant!"
        Write-Error -Message $_.Exception -ErrorAction Stop
        throw $_.Exception
    }
}
#Main Script Execution
Connect-ToTenant -ErrorAction Stop
$tenantLicensingDetails = Get-LicensingUsage
# Create HTML Instances for the Body Payload
    $Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@
    $data1html = $tenantLicensingDetails |ConvertTo-Html -Head $Header
    $body ="<h2>Licensing Details</h2>" + $data1html
    # Create the Email in JSON Format
    $params = @{
        Message = @{
            Subject = "Tenant Licensing Report"
            Body = @{
                ContentType = "html"
                Content = $body
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = "dl-Name@example.com"
                    }
                }
                @{
                    EmailAddress = @{
                        Address = "user.name@example.com"
                    }
                }
            )
        }
        SaveToSentItems = "false"
    }
    # Sending the Email
    Send-MgUserMail -UserId "automation-Account@example.com" -BodyParameter $params
