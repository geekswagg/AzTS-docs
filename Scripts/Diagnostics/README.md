# Azure Tenant Scanner Powershell Utility Scripts

This readme describes the functions available in the PowerShell based diagnostic scripts files.

The functions are intended to help remediation of Azure Tenant Scanner controls. Controls and provided functions are listed below. Each control's diagnostics functions are in a .ps1 file named for that control ID, e.g. `Azure_KeyVault_NetSec_Disable_Public_Network_Access.ps1`.

- Important: These scripts have been developed for the purpose of aiding the AzTS support team in diagnosing control failures. If you have any inquiries from an end-user standpoint, please don't hesitate to contact our support team at aztssup@microsoft.com or open an issue.

We extend our gratitude to [Patrick](https://github.com/plzm/azure-tenant-scanner) for generously sharing these resources!

<br />

## Contents

- [Pre-Requisites](#pre-requisites)
- [How to use](#how-to-use)
  - [Powershell Execution Policy](#powershell-execution-policy)
- [Controls and Functions](#controls-and-functions)
  - [Utility](#utility)
  - [Azure\_AppService\_DP\_Use\_Secure\_FTP\_Deployment](#azure_appservice_dp_use_secure_ftp_deployment)
  - [Azure\_DBForMYSQLFlexibleServer\_DP\_Enable\_SSL](#azure_dbformysqlflexibleserver_dp_enable_ssl)
  - [Azure_DBForMySQLFlexibleServer_DP_Use_Secure_TLS_Version](#azure_dbformysqlflexibleserver_dp_use_secure_tls_version)
  - [Azure\_KeyVault\_NetSec\_Disable\_Public\_Network\_Access](#azure_keyvault_netsec_disable_public_network_access)
  - [Azure\_SQLManagedInstance\_DP\_Use\_Secure\_TLS\_Version](#azure_sqlmanagedinstance_dp_use_secure_tls_version)
  - [Azure\_Subscription\_AuthZ\_Remove\_Deprecated\_Accounts](#azure_subscription_authz_remove_deprecated_accounts)
  - [Azure_VirtualMachine_SI_Enable_Antimalware](#azure_virtualmachine_si_enable_antimalware)

<br />

## Pre-Requisites

- [Powershell 7.x+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
- [Azure Powershell](https://learn.microsoft.com/powershell/azure/install-az-ps)

Note that you can also use the [Azure Cloud Shell](https://shell.azure.com) (select Powershell, not Bash), which has all required pre-requisites already installed.

<br />

## How to use

1. Ensure you meet the pre-requisites above.
2. Log into Azure with [Connect-AzAccount](https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount)
3. Download the appropriate {control name}.ps1 file(s).
4. Open a Powershell prompt in the folder where you downloaded AzTSUtility.ps1.
5. Dot-source the .ps1 file - example: `. ./Azure_KeyVault_NetSec_Disable_Public_Network_Access.ps1`
    1. Note the leading period!
    2. Dot-sourcing lets you run the functions in the file at the command line.
6. Now you can run the functions with their required parameters - see below/
7. You can also run `Get-Help` for any of the functions to see more information about it. Example: `Get-Help Get-AppServiceFtpState`

### Powershell Execution Policy

To run this or other downloaded scripts, you may need to set your Powershell execution policy.
Reference: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies

Example to run script and functions in a downloaded file like AzTSUtility.ps1:
<br />`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser`

Example to then reset the execution policy either to default (Restricted) or RemoteSigned:
<br />`Set-ExecutionPolicy -ExecutionPolicy Default -Scope CurrentUser`
<br />`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

<br />

## Controls and Functions

### Utility

`Install-AzPowershell()`
<br />Purpose: install the latest version of Azure Powershell.
<br />Parameters: None.

`Uninstall-AzPowershell()`
<br />Purpose: easily uninstalls all versions of installed Azure Powershell packages.
<br />Parameters: None.

<br />

### Azure_AppService_DP_Use_Secure_FTP_Deployment

`Get-AppServiceFtpState()`
<br />Purpose: Lists the App Service's production slot and all non-production slots, each with its current FTP state.
<br />Parameters: SubscriptionId, ResourceGroupName, AppServiceName

`Set-AppServiceFtpState()`
<br />Purpose: Sets the specified App Service slot's FTP state.
<br />Parameters: SubscriptionId, ResourceGroupName, AppServiceName, SlotName, FtpState

`Get-FTPAuthSetting`
<br />Purpose: Gets FTP Basic Auth setting value for App Service.
<br />Parameters: ResourceId
<br />

### Azure_DBForMYSQLFlexibleServer_DP_Enable_SSL

`Get-MySqlFlexServerSslState()`
<br />Purpose: Show the MySQL Flexible Server's current SSL state configured via the `require_secure_transport` server parameter.
<br />Parameters: SubscriptionId, ResourceGroupName, ServerName

`Set-MySqlFlexServerSslState()`
<br />Purpose: Sets the MySQL Flexible Server's SSL state configured via the `require_secure_transport` server parameter.
<br />Parameters: SubscriptionId, ResourceGroupName, ServerName, SslSetting

<br />

### Azure_DBForMySQLFlexibleServer_DP_Use_Secure_TLS_Version

`Get-MySqlFlexServerTlsVersion()`
<br />Purpose: Show the MySQL Flexible Server's current minimum TLS version configured via the `tls_version` server parameter.
<br />Parameters: SubscriptionId, ResourceGroupName, ServerName

`Set-MySqlFlexServerTlsVersion()`
<br />Purpose: Sets the MySQL Flexible Server's minimum TLS version configured via the `tls_version` server parameter.
<br />Parameters: SubscriptionId, ResourceGroupName, ServerName, TlsVersion
<br />NOTE: this command will restart the MySQL Flexible Server! This will briefly affect availability.

<br />

### Azure_KeyVault_NetSec_Disable_Public_Network_Access

`Set-KeyVaultNetworkRulesFromServiceTags()`
<br />Purpose: Sets Key Vault network access rules for the CIDRs in the specified Azure Service Tags. Supports merge with or replacement of existing network access rules. Supports CIDR consolidation if the CIDRs exceed Key Vault's limit of 1,000 network access rules.
<br />Parameters: SubscriptionId, ResourceGroupName, KeyVaultName, ServiceTags, Action, ConsolidateCidrsIfNeeded

`Set-KeyVaultNetworkRulesFromCidrs()`
<br />Purpose: Sets Key Vault network access rules for the specified CIDRs. Supports merge with or replacement of existing network access rules. Supports CIDR consolidation if the CIDRs exceed Key Vault's limit of 1,000 network access rules.
<br />Parameters: SubscriptionId, ResourceGroupName, KeyVaultName, Cidrs, Action, ConsolidateCidrsIfNeeded

`Remove-KeyVaultNetworkAccessRuleForIpAddress()`
<br />Purpose: Removes a network access rule for the provided public IP address from the Key Vault.
<br />Parameters: SubscriptionId, ResourceGroupName, KeyVaultName, PublicIpAddress

`Set-KeyVaultSecurePublicNetworkSettings()`
<br />Purpose: Updates an existing Key Vault to enable public network access with default action Deny, and to allow trusted Azure services.
<br />Parameters: SubscriptionId, ResourceGroupName, KeyVaultName

`Set-KeyVaultPublicNetworkAccessEnabledForMe()`
<br />Purpose: Adds a network access rule to the Key Vault for the public IP address which you are currently using. Uses a third-party web site to get your egress public IP.
<br />Parameters: SubscriptionId, ResourceGroupName, KeyVaultName

`Get-AppServiceAllPossibleOutboundPublicIps()`
<br />Purpose: Show the App Service's possible outbound public IPs, which can be used to create Azure Key Vault network access rules. **This is not reliable for Consumption or Premium Plan App Services!**
<br />Parameters: SubscriptionId, ResourceGroupName, AppServiceName

`Get-AppServiceAllCurrentOutboundPublicIps()`
<br />Purpose: Show the App Service's current outbound public IPs. These will be a subset of all _possible_ outbound public IPs, so `Get-AppServiceAllPossibleOutboundPublicIps()` is the better function to use, but this is included for reference and comparison. **This is not reliable for Consumption or Premium Plan App Services!**
<br />Parameters: SubscriptionId, ResourceGroupName, AppServiceName

`ConvertFrom-BinaryIpAddress()`
<br />Purpose: Utility method used by other Network Utility functions
<br />Parameters: IpAddressBinary

`ConvertTo-BinaryIpAddress()`
<br />Purpose: Utility method used by other Network Utility functions
<br />Parameters: IpAddress

`ConvertTo-Binary()`
<br />Purpose: Utility method used by ConvertTo-BinaryIpAddress
<br />Parameters: RawValue, Padding

`Get-CidrRangeBetweenIps()`
<br />Purpose: Gets the CIDR or a passed set  of IP addresses.
<br />Parameters: IpAddresses

`Get-CidrRanges()`
<br />Purpose: Gets CIDRs for a set of start/end IPs.
<br />Parameters: IpAddresses, MaxSizePrefix, AddCidrToSingleIPs

`Get-CondensedCidrRanges()`
<br />Purpose: Gets consolidated CIDRs for a set of CIDRs. Goal is to reduce the number of items in a list of CIDRs to a shorter number of bigger CIDRs that include all the passed CIDRs. This can help with Key Vault's limit of 1,000 network access rules for CIDRs.
<br />Parameters: CidrRanges, MaxSizePrefix, AddCidrToSingleIPs

`Get-EndIpForCidr()`
<br />Purpose: Gets the end IP address for the specified CIDR.
<br />Parameters: Cidr

`Get-EndIp()`
<br />Purpose: Gets the end IP address for the specified start IP and prefix.
<br />Parameters: StartIp, Prefix

`Get-MyPublicIpAddress()`
<br />Purpose: gets my public IP address as Azure/internet would see me. Uses a third-party web site.
<br />Parameters: None.

`Get-AzurePublicIpRanges()`
<br />Purpose: gets the weekly updated Microsoft Azure public IPs file and returns the IP ranges therein. Goal is to make automation scenarios (e.g. update Key Vault network access rules) much easier.
<br />Parameters: None.

`Get-AzurePublicIpv4RangesForServiceTags()`
<br />Purpose: given an array of service tags (e.g. AzureCloud.westus), returns the IPv4 CIDRs in the service tags.
<br />Parameters: ServiceTags

`Test-IsIpInCidr()`
<br />Purpose: checks if the specified IP address is in the specified CIDR.
<br />Parameters: IpAddress, Cidr

`Get-ServiceTagsForAzurePublicIp()`
<br />Purpose: gets the Azure service tags which include the specified Azure public IP address.
<br />Parameters: IpAddress

<br />

### Azure_SQLManagedInstance_DP_Use_Secure_TLS_Version

`Get-SqlManagedInstanceMinimumTlsVersion()`
<br />Purpose: Show the Azure SQL DB Managed Instance's current minimum TLS version.
<br />Parameters: SubscriptionId, ResourceGroupName, SqlInstanceName

`Set-SqlManagedInstanceMinimumTlsVersion()`
<br />Purpose: Sets the Azure SQL DB Managed Instance's minimum TLS version.
<br />Parameters: SubscriptionId, ResourceGroupName, SqlInstanceName, MinimalTlsVersion

<br />

### Azure_Subscription_AuthZ_Remove_Deprecated_Accounts

`Get-DeletedUser()`
<br />Purpose: Retrieves the recently deleted object from Microsoft Graph's deleted objects. Useful when trying to match a name to a deleted object ID (e.g. user or service principal GUID).
<br />Parameters: DeletedObjectId
<br />NOTE: This command requires the Microsoft.Graph SDK. See installation instructions: https://learn.microsoft.com/powershell/microsoftgraph/installation?view=graph-powershell-1.0#installation

<br/>

### Azure_VirtualMachine_SI_Enable_Antimalware
- Note: Below functions can be used for Virtual Machines with 'Windows' OS type only.

`Get-MDEPreferences()`
<br />Purpose: While RDPed onto a VM, run this to show current configuration preferences for Microsoft Defender for Endpoint.
<br />Parameters: None

`Get-MDEStatus()`
<br />Purpose: While RDPed onto a VM, run this to show current status for Microsoft Defender for Endpoint.
<br />Parameters: None

`Set-MDESignatureUpdateScheduledTask()`
<br />Purpose: While RDPed onto a VM, run this to create an hourly scheduled task to run Microsoft Defender for Endpoints signature update. Normally, this should not be needed, but can be useful when investigating possible signature update timing/scheduling issues.
<br />Parameters: None

<br />
