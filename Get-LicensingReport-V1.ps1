<#  This script will pull the current licensing usage for the tenant. It is broken down in to 3 sections.
    1. Pull All of the licenses in the tenant, match them to the Friendly Name, weed out the default ones, and return the SkuID, "Friendly Name", Consumed, Purchased, and Percentage Used.
    2. Pull the current Numbers of each Licensing Group within the Tenant
    3. Email a report to the selected recipients containing all of the information gathered.
#>
#Function To Get all of the licenses in the tenant and return the Friendly Names in a Table
function Get-LicensingUsage
{
$msolSkusClean = @()
$MsolSkusRAW = Get-MgSubscribedSKU -All -Property @("SkuId","SkuPartNumber", "ConsumedUnits", "PrepaidUnits") | Select-Object *, @{Name = "ActiveUnits"; Expression = { ($_ | Select-Object -ExpandProperty PrepaidUnits).Enabled } } |Select-Object SkuId,SkuPartNumber, ActiveUnits, ConsumedUnits
#Matching the Raw Sku Data to the Friendly Name of the Sku from the following table https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
foreach ($sku in $MsolSkusRAW)
{
     switch ($sku.SkuPartNumber)
    {
        "RMBASIC"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Rights Management Service Basic Content Protection"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }   
        "EXCHANGEENTERPRISE_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Exchange Online (Plan 2) for GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "PROJECTPROFESSIONAL_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Project Plan 3 for GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "EMSPREMIUM_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Enterprise Mobility + Security G5 GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "M365_F1_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft 365 F3 GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "MDATP_SERVER_GCC"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Defender for Endpoint Server GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "VISIOCLIENT_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Visio Plan 2 for GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "PROJECTPREMIUM_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Project Plan 5 for GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "M365_G5_GCC"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft 365 GCC G5"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "STANDARDPACK_GOV"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Office 365 G1 GCC"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "ADALLOM_STANDALONE"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Cloud App Security"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "ATA"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Defender for Identity"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "Microsoft_Teams_Premium"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Teams Premium Introductory Pricing"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        } 
        "MEETING_ROOM"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Teams Rooms Standard"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        } 
        "MTR_PREM"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Teams Rooms Premium"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "VISIOONLINE_PLAN1"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Visio Online Plan 1"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "PROJECTPROFESSIONAL"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Project Plan 3"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "SPE_F1"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft 365 F3"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "Microsoft_Teams_Audio_Conferencing_select_dial_out"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Teams Audio Conferencing with dial-out to USA/CAN"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        "SPE_F5_SECCOMP"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft 365 F5 Security + Compliance Add-on"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
         "VIVA"{ 
            $item = New-Object pscustomobject
            $item | Add-Member -MemberType NoteProperty -Name 'SkuId' -Value $sku.SkuId
            $item | Add-Member -MemberType NoteProperty -Name 'SkuPartNumber' -Value "Microsoft Viva Suite"
            $item | Add-Member -MemberType NoteProperty -Name 'ConsumedUnits' -Value $sku.ConsumedUnits
            $item | Add-Member -MemberType NoteProperty -Name 'PurchasedUnits' -Value $sku.ActiveUnits
            $PercetageUsed = ($sku.ConsumedUnits / $sku.ActiveUnits).ToString("P")
            $item | Add-Member -MemberType NoteProperty -Name "PercentageUsed" -Value $PercetageUsed
        $msolSkusClean+=$item
        }
        
}
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