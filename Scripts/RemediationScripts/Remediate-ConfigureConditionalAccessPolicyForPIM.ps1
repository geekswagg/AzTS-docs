﻿<###
# Overview:
    This script is used to configure Conditional Access (CA) policy to restrict PIM elevation from SAW for all built-in roles and all custom roles except for a few built-in roles in a Subscription.
    Following is the list of excluded built-in role definitions:
    [ Azure Front Door Domain Contributor, Azure Front Door Domain Reader, Azure Front Door Profile Reader,
      Azure Front Door Secret Contributor, Azure Front Door Secret Reader, Defender for Storage Data Scanner,
      AzureML Compute Operator, Cognitive Services Usages Reader, Key Vault Crypto Service Release User ]

# Control ID:
    Azure_Subscription_AuthZ_Configure_Conditional_Access_for_PIM

# Display Name:
    Enable policy to require PIM elevation from SAW for admin roles in Azure subscriptions

# Prerequisites:
    'Owner' or 'User Access Administrator' role is required at Subscription level.

# Steps performed by the script:
    To remediate:
        1. Validate and install the modules required to run the script.
        2. Get the roles where the Conditional Access policy is not configured in a Subscription.
        3. Back up details of currently configured Conditional Access policy that are to be remediated.
        4. Configure Conditional Access (CA) policy for eligible roles in the Subscription.

    To rollback:
        1. Validate and install the modules required to run the script.
        2. Get the roles where the Conditional Access policy was confiured and, are to be rolled back.
        3. Disable Conditional Access (CA) policy for eligible roles in the Subscription.

# Instructions to execute the script:
    To remediate:
        1. Download the script.
        2. Load the script in a PowerShell session. Refer https://aka.ms/AzTS-docs/RemediationscriptExcSteps to know more about loading the script.
        3. Execute the script to configure conditional access policy for eligible roles in the Subscription. Refer `Examples`, below.

# Examples:
    To remediate:
        1. To review all the roles where Conditional Access policy is not configured:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -DryRun [-PerformPreReqCheck]

        2. To configure Conditional Access (CA) policy in Subscription, from a previously taken snapshot:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -FilePath 'C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\2022010101121\CA_Policy_Details\CA_Policy_Details.csv'
                
        3. To configure Conditional Access (CA) policy for all the eligible roles (all built-in and custom roles except few built-in roles) in Subscription:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' 
        
        4. To configure Conditional Access (CA) policy only for 'Owner' role in Subscription:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'Owner' 

        5. To configure Conditional Access (CA) policy only for 'Contributor' role in Subscription:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'Contributor'

        6. To configure Conditional Access (CA) policy only for 'User Access Administrator' role in Subscription:
                Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'User Access Administrator'

        To know more about the options supported by the remediation command, execute:
        Get-Help Configure-ConditionalAccessPolicyForPIM -Detailed
        
    To rollback:
        1. To disable Conditional Access (CA) policy in Subscription, from a previously remediated snapshot:
                Disable-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -FilePath 'C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\2022010101121\CA_Policy_Details\ConfiguredCAPolicy.csv'
        
###>


function Setup-Prerequisites
{
    <#
        .SYNOPSIS
        Checks if the prerequisites are met, else, sets them up.

        .DESCRIPTION
        Checks if the prerequisites are met, else, sets them up.
        Includes installing any required Azure modules.

        .INPUTS
        None. You cannot pipe objects to Setup-Prerequisites.

        .OUTPUTS
        None. Setup-Prerequisites does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Setup-Prerequisites

        .LINK
        None
    #>

    # List of required modules
    $requiredModules = @("Az.Accounts", "Az.Resources", "AzureAD")

    Write-Host "Required modules: $($requiredModules -join ', ')" -ForegroundColor $([Constants]::MessageType.Info)
    Write-Host "Checking if the required modules are present..."

    $availableModules = $(Get-Module -ListAvailable $requiredModules -ErrorAction Stop)

    # Check if the required modules are installed.
    if($availableModules.Name -contains "AZ.Accounts")
    {
        $module = Get-Module "Az.Accounts"
        if($module.Version -ge "2.7.6")
        {
            Write-Host "Az.Accounts module is present." -ForegroundColor $([Constants]::MessageType.Update)
        }
        else
        {
             Write-Host "Installing Az.Accounts module..." -ForegroundColor $([Constants]::MessageType.Info)
             Install-Module -Name "Az.Accounts" -MinimumVersion 2.7.6 -Scope CurrentUser -Repository 'PSGallery' -Force  -AllowClobber -ErrorAction Stop
             Write-Host "Az.Accounts module is installed." -ForegroundColor $([Constants]::MessageType.Update) 
        }    
    }
    else
    {
        Write-Host "Installing Az.Accounts module...." -ForegroundColor $([Constants]::MessageType.Info)
        Install-Module -Name "Az.Accounts" -MinimumVersion 2.7.6 -Scope CurrentUser -Repository 'PSGallery' -Force -AllowClobber -ErrorAction Stop
        Write-Host "Az.Accounts module is installed." -ForegroundColor $([Constants]::MessageType.Update) 
    }


    if ($availableModules.Name -contains "Az.Resources")
    {
        $module = Get-Module "Az.Resources"
        if($module.Version -ge "5.5.0")
        {
            Write-Host "Az.Resources module is present." -ForegroundColor $([Constants]::MessageType.Update)        
        }
        else
        {
            Write-Host "Installing Az.Resources module..." -ForegroundColor $([Constants]::MessageType.Info)
            Install-Module -Name "Az.Resources" -MinimumVersion 5.6.0 -Scope CurrentUser -Repository 'PSGallery'  -AllowClobber -Force -ErrorAction Stop 
            Write-Host "Az.Resources module is installed." -ForegroundColor $([Constants]::MessageType.Update)  
        }
    }
    else
    {
        Write-Host "Installing Az.Resources module...." -ForegroundColor $([Constants]::MessageType.Info)
        Install-Module -Name "Az.Resources"  -MinimumVersion 5.6.0 -Scope CurrentUser -Repository 'PSGallery' -Force  -AllowClobber -ErrorAction Stop
        Write-Host "Az.Resources module is installed." -ForegroundColor $([Constants]::MessageType.Update)
    }


    if($availableModules.Name -contains "AzureAD")
    {
        Write-Host "AzureAD module is present." -ForegroundColor $([Constants]::MessageType.Update)
    }
    else
    {
        Write-Host "Installing AzureAD module...." -ForegroundColor $([Constants]::MessageType.Info)
        Install-Module -Name AzureAD -Scope CurrentUser -Repository "PSGallery" -Force -AllowClobber -ErrorAction Stop
        Write-Host "AzureAD module is installed." -ForegroundColor $([Constants]::MessageType.Update)
    }

    Write-Host $([Constants]::DoubleDashLine)
}


function Configure-ConditionalAccessPolicyForPIM
{
    <#
        .SYNOPSIS
        Remediates 'Azure_Subscription_Configure_Conditional_Access_for_PIM' Control.

        .DESCRIPTION
        Remediates 'Azure_Subscription_Configure_Conditional_Access_for_PIM' Control.
        Configure Conditional Access (CA) policy for eligible roles in the Subscription.
        
        .PARAMETER SubscriptionId
        Specifies the ID of the Subscription to be remediated.
        
        .Parameter PerformPreReqCheck
        Specifies validation of prerequisites for the command.

        .INPUTS
        None. You cannot pipe objects to Configure-ConditionalAccessPolicyForPIM.

        .OUTPUTS
        None. Configure-ConditionalAccessPolicyForPIM does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -DryRun.

        .EXAMPLE
        PS> Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -FilePath 'C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\2022010101121\CA_Policy_Details\CA_Policy_Details.csv'.

        .EXAMPLE
        PS> Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'Owner'.

        .EXAMPLE
        PS> Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'Contributor'.

        .EXAMPLE
        PS> Configure-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -RoleName 'User Access Administrator'.

        .LINK
        None
    #>

    param (
        [String]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be remediated")]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be remediated")]
        $SubscriptionId,

        [Switch]
        [Parameter(ParameterSetName = "DryRun", HelpMessage="Specifies validation of prerequisites for the command")]
        [Parameter(ParameterSetName = "WetRun", HelpMessage="Specifies validation of prerequisites for the command")]
        $PerformPreReqCheck,

        [String]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $false, HelpMessage="Specifies the role name on which CA policy needs to be configured")]
        $RoleName,
        
        [Switch]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage="Specifies a dry run of the actual remediation")]
        $DryRun,

        [String]
        [Parameter(ParameterSetName = "WetRun", HelpMessage="Specifies the path to the file to be used as input for the remediation")]
        $FilePath
    )

    # These are the roles which are excluded by the control. If no parameter for role name is provided then all roles (built-in and custom)
    # will be fetched and these roles will be excluded from the list.
    $excludedRoles = @(
        "Azure Front Door Domain Contributor",
        "Azure Front Door Domain Reader",
        "Azure Front Door Profile Reader",
        "Azure Front Door Secret Contributor",
        "Azure Front Door Secret Reader",
        "Defender for Storage Data Scanner",
        "AzureML Compute Operator",
        "Cognitive Services Usages Reader",
        "Key Vault Crypto Service Release User"
    )

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 1 of 5] Preparing to configure Conditional Access (CA) policy in Subscription [$($SubscriptionId)]"

    if ($PerformPreReqCheck)
    {
        try
        {
            Write-Host "Setting up prerequisites..."
            Setup-Prerequisites
        }
        catch
        {
            Write-Host "Error occurred while setting up prerequisites. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            return
        }
    }

    # Connect to AzAccount
    $isContextSet = Get-AzContext
    if ([string]::IsNullOrEmpty($isContextSet))
    {       
        Write-Host "Connecting to AzAccount..."
        Connect-AzAccount -ErrorAction Stop
        Write-Host "Connected to AzAccount" -ForegroundColor Green
    }

    # Setting context for current subscription.
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop

    # Safe Check: Checking whether the current account is of type 'User'.
    if($context.Account.Type -ne "User")
    {
        Write-Host "WARNING: This script can only be run by 'User' account type." -ForegroundColor $([Constants]::MessageType.Warning)
        return;
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 2 of 5] Validating whether the current user [$($context.Account.Id)] has required permissions to run the script for subscription [$($SubscriptionId)]..."

    # Safe Check: Current user need to be either UAA or Owner for the subscription.
    $currentLoginRoleAssignments = Get-AzRoleAssignment -SignInName $context.Account.Id -WarningAction Ignore

    Write-Host "`n*** To configure Conditional Access (CA) policy in a Subscription, user must have [Owner/User Access Administrator] role at subscription. ***" -ForegroundColor $([Constants]::MessageType.Info)

    Write-Host "**Metadata Details:**"
    Write-Host "Subscription Name: [$($context.Subscription.Name)]"
    Write-Host "Subscription ID: [$($context.Subscription.SubscriptionId)]"
    Write-Host "Account Name: [$($context.Account.Id)]"
    Write-Host "Account Type: [$($context.Account.Type)]"

    $requiredRoleDefinitionName = @("Owner", "User Access Administrator")

    if(($currentLoginRoleAssignments | Where { $_.RoleDefinitionName -in $requiredRoleDefinitionName -and ($_.Scope -eq "/subscriptions/$($SubscriptionId)" -or $_.Scope -contains "/providers/Microsoft.Management/managementGroups") } | Measure-Object).Count -le 0 )
    {
        Write-Host "WARNING: This script can only be run by an [$($requiredRoleDefinitionName -join ", ")]. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
        return;
    }
    else
    {
        Write-Host "Current user [$($context.Account.Id)] has the required permission for subscription [$($SubscriptionId)].`n" -ForegroundColor $([Constants]::MessageType.Update)
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 3 of 5] Checking if for all eligible roles Conditional Access (CA) policy has been configured for the subscription [$($SubscriptionId)]..."

    $policyAssignments = Get-AzRoleManagementPolicyAssignment -Scope "subscriptions/$($SubscriptionId)"
    $policyDetailsCollection = Get-AzRoleManagementPolicy -Scope "subscriptions/$($SubscriptionId)"

    # The Hash Table below will contain key-value pair of the form (role Id, mfa Rule) if MFA is enabled for that role Id. 
    $mfaEnabledRoles = @{}
    $eligibleRoles

    # No file path provided as input to the script. Fetch currently configured Conditional Access (CA) policy in the subscription.
    if ([String]::IsNullOrWhiteSpace($FilePath))
    {
        $roleDefinitions = $policyAssignments | Select-Object -ExpandProperty RoleDefinitionDisplayName
        
        if (-not $RoleName)
        {   
            # Remove excluded roles from the role definition collection.
            $eligibleRoles = $roleDefinitions | Where-Object { $_ -notin $excludedRoles }
        }
        else
        {
            # Validate if RoleName is a valid for the particular subscription (role name can be subscription specific for custom roles).
            if (-not $roleDefinitions.Contains($RoleName))
            {
                Write-Host "The role ($($RoleName)) provided does not exist for the subsciption ($($SubscriptionId)). Exiting..."
                return
            }

            $eligibleRoles = @($RoleName)
        }

        # Fetch all the CA policies and check if for all the eligible roles, policy has been assigned.
        $nonCompliantRoles = @()
        $nonCompliantRolesCount = 0
        $configuredPolicyDetails = New-Object -TypeName PSObject

        # Find for all roles if MFA has been enabled.
        $eligibleRoles | ForEach-Object {
            $role = $_
            $policyId = $policyAssignments | Where-Object {$_.RoleDefinitionDisplayName -contains $role}
            $roleId = $policyId.PolicyId.Split('/')
            $policyDetails = $policyDetailsCollection | Where-Object { $_.Name -eq $roleId[-1] }
            $configuredPolicyDetail = $policyDetails.EffectiveRule | Where-Object {($_.claimValue -eq "c1" -and $_.IsEnabled -eq $true) -or ($_.claimValue -eq "urn:microsoft:req1" -and $_.IsEnabled -eq $true)}
            if ([String]::IsNullOrWhiteSpace($configuredPolicyDetail))
            {
                $nonCompliantRoles += $role
                $nonCompliantRolesCount += 1
                $nonCompliantRolesStr = $nonCompliantRoles -join ','
            }
        }
    
        if (![String]::IsNullOrWhiteSpace($nonCompliantRolesStr))
        {
            $configuredPolicyDetails | Add-Member -NotePropertyName SubscriptionId -NotePropertyValue $SubscriptionId
            $configuredPolicyDetails | Add-Member -NotePropertyName NonCompliantRoles -NotePropertyValue $nonCompliantRolesStr
            Write-Host "Conditional Access policy has not been correctly configured for [$($nonCompliantRolesCount)] role(s)." -ForegroundColor $([Constants]::MessageType.Update)
        }
        else
        {
            Write-Host "Conditional Access policy has been correctly configured for all eligible roles. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
            return
        }
    }
    else
    {
        Write-Host "File path is specified. Fetching policy details from $($FilePath)"

        if (-not (Test-Path -Path $FilePath))
        {
            Write-Host "ERROR: Input file - $($FilePath) not found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
            return
        }
 
        $configuredPolicyDetails = Import-Csv -LiteralPath $FilePath
        $eligibleRoles = $configuredPolicyDetails.NonCompliantRoles.Split(',')

        if (($configuredPolicyDetails | Measure-Object).Count -gt 0)
        {
            Write-Host "Successfully fetched Conditional Access (CA) policy details for subscription [$($SubscriptionId)]" -ForegroundColor $([Constants]::MessageType.Update)
        }
    }

    # Check if MFA is enabled for this particular role
    $eligibleRoles | ForEach-Object {
        $role = $_
        $policyId = $policyAssignments | Where-Object {$_.RoleDefinitionDisplayName -contains $role}
        $roleId = $policyId.PolicyId.Split('/')
        $policyDetails = $policyDetailsCollection | Where-Object { $_.Name -eq $roleId[-1] }

        # Need to check for MFA as MFA and Conditional Access Policy can't be enabled simultaneously.
        $targetRuleForMFA = $policyDetails.EffectiveRule | Where-Object { $_.Id -eq 'Enablement_EndUser_Assignment' -and $_.RuleType -eq 'RoleManagementPolicyEnablementRule' }
        if (![String]::IsNullOrWhiteSpace($targetRuleForMFA))
        {
            if ($targetRuleForMFA.EnabledRule -match 'MultiFactorAuthentication')
            {
                # MFA is enabled on this role.
                $mfaEnabledRoles[$roleId[-1]] = $targetRuleForMFA
            }
        }
    }

    # Back up snapshots to `%LocalApplicationData%'.
    $backupFolderPath = "$([Environment]::GetFolderPath('LocalApplicationData'))\AzTS\Remediation\Subscriptions\$($context.Subscription.SubscriptionId.replace('-','_'))\$($(Get-Date).ToString('yyyyMMddhhmm'))\CA_Policy_Details"

    if (-not (Test-Path -Path $backupFolderPath))
    {
        New-Item -ItemType Directory -Path $backupFolderPath | Out-Null
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 4 of 5] Backing up Conditional Access policy details..."

    # Backing up currently configured Conditional Access policy.
    $backupFile = "$($backupFolderPath)\CA_Policy_Details.csv"
    $configuredPolicyDetails | Export-CSV -Path $backupFile -NoTypeInformation
    Write-Host "Conditional Access policy details have been successful backed up to $($backupFolderPath)" -ForegroundColor $([Constants]::MessageType.Update)
 
    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 5 of 5] Configuring Conditional Access (CA) policy for subscription [$($SubscriptionId)]..."

    if (-not $DryRun)
    {
        # It is a wet run, hence we need to create policy assignments for the roles for which CA policy is not there.
        try
        {
            $remediatedRoles = @()
            $skippedRoles = @()
            $mfaConfiguredRoleNames = @()
            $remediationSummary = New-Object -TypeName PSObject

            Write-Host "`nThis script will disable Multi Factor Authentication (if applied for a role) and configure a Conditional Access (CA) policy for all eligible and non-compliant role(s) in your Azure Subscription ($($SubscriptionId)). After running this script, you will be required to use both a Standard Azure Workstation and a Security-Compliant Access Level Token (SC-ALT) account to elevate your access for all the non-compliant roles. Please ensure that you have necessary permissions to access this subscription post run of this script. Do you want to continue? " -ForegroundColor $([Constants]::MessageType.Warning) -NoNewline
            
            $userInput = Read-Host -Prompt "(Y|N)"
            if($userInput -ne "Y")
            {
                Write-Host "Conditional Access policy will not be configured for non-compliant role(s) [User permission denied]. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
                return
            }

            $totalRolesCount = $configuredPolicyDetails.NonCompliantRoles.Split(',').Count;
            $currentRoleIndex = 1
            foreach ($role in $configuredPolicyDetails.NonCompliantRoles.Split(','))
            {
                $policyId = $policyAssignments | Where-Object {$_.RoleDefinitionDisplayName -contains $role}
                $roleId = $policyId.PolicyId.Split('/')
                Write-Host "`n[$currentRoleIndex/$totalRolesCount]"

                # Before configuring CA Policy we need to check if Multi Factor Authentication is enabled for the current role
                # MFA and CA Policies can't be enabled simultaneously
                Write-Host "Checking if Multi Factor Authentication (MFA) is enabled for [$($role)] role..."
                if ($mfaEnabledRoles.ContainsKey($roleId[-1]))
                {
                    Write-Host "MFA is enabled for [$($role)] role, disabling MFA..."
                    $mfaRule = $mfaEnabledRoles[$roleId[-1]]
                    $mfaConfiguredRoleNames += $role

                    # Remove MFA from the enabled rules and update the policy with the current rule.
                    $mfaRule.EnabledRule = $mfaRule.EnabledRule | Where-Object { $_ -ne "MultiFactorAuthentication" }
                    Update-AzRoleManagementPolicy -Name $roleId[-1] -Scope "subscriptions/$($SubscriptionId)" -Rule $mfaRule | Out-Null
                    Write-Host "Successfully disabled MFA for [$($role)] role."
                }
                else
                {
                    Write-Host "MFA is not enabled for [$($role)] role."
                }
        
                Write-Host "Updating Conditional Access Policy for [$($role)] role..."
                $body = @'
	            {
	                "isEnabled": true,
	                "claimValue": "c1",
	                "id": "AuthenticationContext_EndUser_Assignment",
	                "ruleType": "RoleManagementPolicyAuthenticationContextRule",
	                "target": {
	                    "caller": "EndUser",
	                    "operations": [
	                    "All"
	                    ],
	                    "level": "Assignment"
	                }
	            }
'@

                $updatedPolicyDetail = Update-AzRoleManagementPolicy -Name $roleId[-1] -Scope "subscriptions/$($SubscriptionId)" -Rule $body

                $configuredPolicyDetail = $updatedPolicyDetail.EffectiveRule | Where-Object {$_.claimValue -eq "c1" -and $_.IsEnabled -eq $true}

                if (![String]::IsNullOrWhiteSpace($configuredPolicyDetail))
                {
                    $remediatedRoles += $role
                    $remediatedRolesStr = $remediatedRoles -join ','
                    Write-Host "Successfully updated Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Update)
                }
                else
                {
                    $skippedRoles += $role
                    $skippedRolesStr = $skippedRoles -join ','
                    Write-Host "Error while configuring Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Error)
                }

                $currentRoleIndex += 1
                Write-Host "`n"
            }
        }
        catch
        {
            $skippedRoles += $role
            $skippedRolesStr = $skippedRoles -join ','
            Write-Host "Error while configuring Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Error)
        }
        
        $remediationSummary | Add-Member -NotePropertyName SubscriptionId -NotePropertyValue $SubscriptionId

        if (![String]::IsNullOrWhiteSpace($remediatedRolesStr))
        {
            $remediationSummary | Add-Member -NotePropertyName RemediatedRoles -NotePropertyValue $remediatedRolesStr
        }

        if (![String]::IsNullOrWhiteSpace($skippedRolesStr))
        {
            $remediationSummary | Add-Member -NotePropertyName SkippedRoles -NotePropertyValue $skippedRolesStr
        }

        # Adding all the roles under the heading 'MFAEnabledRoles' which have MFA enabled, it would help while roll back.
        $mfaConfiguredRoleNamesStr = $mfaConfiguredRoleNames -join ','
        $remediationSummary | Add-Member -NotePropertyName MFAEnabledRoles -NotePropertyValue $mfaConfiguredRoleNamesStr

        $remediatedRolesCount = $remediatedRoles.Count
        $skippedRolesCount = $skippedRoles.Count
        $colsProperty = @{Expression={$_.SubscriptionId};Label="Subscription ID";Width=40;Alignment="left"},
                        @{Expression={$remediatedRolesCount};Label="Remediated Roles Count";Width=20;Alignment="center";},
                        @{Expression={$skippedRolesCount};Label="Skipped Roles Count";Width=20;Alignment="center";}

        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "`nRemediation Summary:`n" -ForegroundColor $([Constants]::MessageType.Info)
        
        $remediationSummary | Format-Table -Property $colsProperty -Wrap

        # Write this to a file.
        $remediationSummaryFile = "$($backupFolderPath)\ConfiguredCAPolicy.csv"
        $remediationSummary | Export-CSV -Path $remediationSummaryFile -NoTypeInformation
        Write-Host "This information has been saved to $($remediationSummaryFile)" -ForegroundColor $([Constants]::MessageType.Info)
        Write-Host "Use this file for any roll back that may be required." -ForegroundColor $([Constants]::MessageType.Info)
    }
    else
    {
        Write-Host $([Constants]::SingleDashLine)
        Write-Host "Skipped as -DryRun switch is provided." -ForegroundColor $([Constants]::MessageType.Warning)
        Write-Host $([Constants]::DoubleDashLine)

        Write-Host "`n**Next steps:**" -ForegroundColor $([Constants]::MessageType.Info)
        Write-Host "Run the same command with -FilePath $($backupFile) and without -DryRun, to configure Conditional Access policy for all listed roles in the file." -ForegroundColor $([Constants]::MessageType.Info)
    }
}

function Disable-ConditionalAccessPolicyForPIM
{
    <#
        .SYNOPSIS
        Remediates 'Azure_Subscription_Configure_Conditional_Access_for_PIM' Control.

        .DESCRIPTION
        Remediates 'Azure_Subscription_Configure_Conditional_Access_for_PIM' Control.
        Disable Conditional Access (CA) policy for previously remediated role(s) in the Subscription.
        
        .PARAMETER SubscriptionId
        Specifies the ID of the Subscription to be remediated.
        
        .Parameter PerformPreReqCheck
        Specifies validation of prerequisites for the command.
        
        .INPUTS
        None. You cannot pipe objects to Disable-ConditionalAccessPolicyForPIM.

        .OUTPUTS
        None. Disable-ConditionalAccessPolicyForPIM does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Disable-ConditionalAccessPolicyForPIM -SubscriptionId '00000000-xxxx-0000-xxxx-000000000000' -FilePath 'C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\2022010101121\CA_Policy_Details\ConfiguredCAPolicy.csv'.

        .LINK
        None
    #>

    param (
        [String]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be rolled back")]
        [Parameter(ParameterSetName = "CustomConfig", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be rolled back")]
        $SubscriptionId,

        [Switch]
        [Parameter(ParameterSetName = "WetRun", HelpMessage="Specifies validation of prerequisites for the command")]
        [Parameter(ParameterSetName = "CustomConfig", HelpMessage="Specifies validation of prerequisites for the command")]
        $PerformPreReqCheck,

        [String]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $true, HelpMessage="Specifies the path to the file to be used as input for the rollback")]
        $FilePath
    )

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "[Step 1 of 4] Preparing to disable Conditional Access (CA) policy in Subscription [$($SubscriptionId)]"

    if ($PerformPreReqCheck)
    {
        try
        {
            Write-Host "Setting up prerequisites..."
            Setup-Prerequisites
        }
        catch
        {
            Write-Host "Error occurred while setting up prerequisites. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            return
        }
    }

    # Connect to AzAccount
    $isContextSet = Get-AzContext
    if ([string]::IsNullOrEmpty($isContextSet))
    {       
        Write-Host "Connecting to AzAccount..."
        Connect-AzAccount -ErrorAction Stop
        Write-Host "Connected to AzAccount" -ForegroundColor Green
    }

    # Setting context for current subscription.
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop

    # Safe Check: Checking whether the current account is of type 'User'.
    if($context.Account.Type -ne "User")
    {
        Write-Host "WARNING: This script can only be run by 'User' account type." -ForegroundColor $([Constants]::MessageType.Warning)
        return;
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 2 of 4] Validating whether the current user [$($context.Account.Id)] has required permissions to run the script for subscription [$($SubscriptionId)]..."

    # Safe Check: Current user need to be either UAA or Owner for the subscription.
    $currentLoginRoleAssignments = Get-AzRoleAssignment -SignInName $context.Account.Id -WarningAction Ignore

    Write-Host "`n*** To disable Conditional Access (CA) policy in a Subscription, user must have [Owner/User Access Administrator] role at subscription. ***" -ForegroundColor $([Constants]::MessageType.Info)

    Write-Host "**Metadata Details:**"
    Write-Host "Subscription Name: [$($context.Subscription.Name)]"
    Write-Host "Subscription ID: [$($context.Subscription.SubscriptionId)]"
    Write-Host "Account Name: [$($context.Account.Id)]"
    Write-Host "Account Type: [$($context.Account.Type)]"

    $requiredRoleDefinitionName = @("Owner", "User Access Administrator")
    if(($currentLoginRoleAssignments | Where { $_.RoleDefinitionName -in $requiredRoleDefinitionName -and ($_.Scope -eq "/subscriptions/$($SubscriptionId)" -or $_.Scope -contains "/providers/Microsoft.Management/managementGroups") } | Measure-Object).Count -le 0 )
    {
        Write-Host "WARNING: This script can only be run by an [$($requiredRoleDefinitionName -join ", ")]. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
        return;
    }
    else
    {
        Write-Host "Current user [$($context.Account.Id)] has the required permission for subscription [$($SubscriptionId)].`n" -ForegroundColor $([Constants]::MessageType.Update)
    }

    if (-not (Test-Path -Path $FilePath))
    {
        Write-Host "ERROR: Input file - $($FilePath) not found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
        return
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 3 of 4] Fetching currently configured Conditional Access (CA) policy for subscription [$($SubscriptionId)] from $($FilePath)"

    $configuredPolicyDetails = Import-Csv -LiteralPath $FilePath
    $totalRolesCount = $configuredPolicyDetails.RemediatedRoles.Split(',').Count
    Write-Host "Fetched $($totalRolesCount) roles which were remediated." -ForegroundColor $([Constants]::MessageType.Update)

    # Back up snapshots to `%LocalApplicationData%'.
    $backupFolderPath = "$([Environment]::GetFolderPath('LocalApplicationData'))\AzTS\Remediation\Subscriptions\$($context.Subscription.SubscriptionId.replace('-','_'))\$($(Get-Date).ToString('yyyyMMddhhmm'))\CA_Policy_Details"

    if (-not (Test-Path -Path $backupFolderPath))
    {
        New-Item -ItemType Directory -Path $backupFolderPath | Out-Null
    }

    try
    {
        $policyDetailsCollection = Get-AzRoleManagementPolicy -Scope "subscriptions/$($SubscriptionId)"
        $policyAssignments = Get-AzRoleManagementPolicyAssignment -Scope "subscriptions/$($SubscriptionId)"

        $rolledBackRoles = @()
        $skippedRoles = @()
        $rolledBackSummary = New-Object -TypeName PSObject
        $mfaConfiguredRoleNames = $configuredPolicyDetails.MFAEnabledRoles.Split(',')

        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "`n[Step 4 of 4] Disabling Conditional Access (CA) policy for subscription [$($SubscriptionId)]..."
        Write-Host "`nRunning this script will disable all the Conditional Access (CA) policies for the previously remediated role(s). Do you want to continue? " -ForegroundColor $([Constants]::MessageType.Warning) -NoNewline
        $userInput = Read-Host -Prompt "(Y|N)"
        if($userInput -ne "Y")
        {
            Write-Host "Conditional Access policy will not be disabled for any of the roles [User permission denied]. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
            return
        }
        
        $currentRoleIndex = 1
        foreach ($role in $configuredPolicyDetails.RemediatedRoles.Split(','))
        {
            $policyId = $policyAssignments | Where-Object {$_.RoleDefinitionDisplayName -contains $role}
            $roleId = $policyId.PolicyId.Split('/')

            Write-Host "`n[$currentRoleIndex/$totalRolesCount]"
            Write-Host "Disabling Conditional Access Policy for [$($role)] role..."
            $body = @'
	        {
	            "isEnabled": false,
	            "claimValue": "c1",
	            "id": "AuthenticationContext_EndUser_Assignment",
	            "ruleType": "RoleManagementPolicyAuthenticationContextRule",
	            "target": {
	                "caller": "EndUser",
	                "operations": [
	                "All"
	                ],
	                "level": "Assignment"
	            }
	        }
'@

            $updatedPolicyDetail = Update-AzRoleManagementPolicy -Name $roleId[-1] -Scope "subscriptions/$($SubscriptionId)" -Rule $body

            # Also, we need to check if there was MFA enabled on the subscription before remediation, if it was then we need to configure while rolling back.
            if ($mfaConfiguredRoleNames.Contains($role))
            {
                # Configure MFA here.
                $policyDetails = $policyDetailsCollection | Where-Object { $_.Name -eq $roleId[-1] }
                $targetRuleForMFA = $policyDetails.EffectiveRule | Where-Object { $_.Id -eq 'Enablement_EndUser_Assignment' -and $_.RuleType -eq 'RoleManagementPolicyEnablementRule' }
                if ($targetRuleForMFA -and !($targetRuleForMFA.EnabledRule -match 'MultiFactorAuthentication'))
                {
                    $targetRuleForMFA.EnabledRule += 'MultiFactorAuthentication'
                    Update-AzRoleManagementPolicy -Name $roleId[-1] -Scope "subscriptions/$($SubscriptionId)" -Rule $targetRuleForMFA | Out-Null
                }
            }

            $configuredPolicyDetail = $updatedPolicyDetail.EffectiveRule | Where-Object {$_.claimValue -eq "c1" -and $_.IsEnabled -eq $false}

            if (![String]::IsNullOrWhiteSpace($configuredPolicyDetail))
            {
                $rolledBackRoles += $role
                $rolledBackRolesStr = $rolledBackRoles -join ','
                Write-Host "Successfully disabled Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Update)
            }
            else
            {
                $skippedRoles += $role
                $skippedRolesStr = $skippedRoles -join ','
                Write-Host "Error while disabling Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Error)
            }

            $currentRoleIndex += 1
            Write-Host "`n"
        }
    }
    catch
    {
        $skippedRoles += $role
        $skippedRolesStr = $skippedRoles -join ','
        Write-Host "Error while disabling Conditional Access Policy for [$($role)] role." -ForegroundColor $([Constants]::MessageType.Error)
    }

    $rolledBackSummary | Add-Member -NotePropertyName SubscriptionId -NotePropertyValue $SubscriptionId

    if (![String]::IsNullOrWhiteSpace($rolledBackRolesStr))
    {
        $rolledBackSummary | Add-Member -NotePropertyName RolledBackRoles -NotePropertyValue $rolledBackRolesStr
    }

    if (![String]::IsNullOrWhiteSpace($skippedRolesStr))
    {
        $rolledBackSummary | Add-Member -NotePropertyName SkippedRoles -NotePropertyValue $skippedRolesStr
    }

    $rolledBackRolesCount = $rolledBackRoles.Count
    $skippedRolesCount = $skippedRoles.Count
    $colsProperty = @{Expression={$_.SubscriptionId};Label="Subscription ID";Width=40;Alignment="left"},
                    @{Expression={$rolledBackRolesCount};Label="Rolled Back Roles Count";Width=20;Alignment="center"},
                    @{Expression={$skippedRolesCount};Label="Skipped Roles Count";Width=20;Alignment="center"}

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`nRollback Summary:" -ForegroundColor $([Constants]::MessageType.Info)
        
    $rolledBackSummary | Format-Table -Property $colsProperty -Wrap

    # Write this to a file.
    $rolledBackSummaryFile = "$($backupFolderPath)\RolledbackCAPolicy.csv"
    $rolledBackSummary | Export-CSV -Path $rolledBackSummaryFile -NoTypeInformation
    Write-Host "This information has been saved to $($rolledBackSummaryFile)" -ForegroundColor $([Constants]::MessageType.Info)
}

# Defines commonly used constants.
class Constants
{
    # Defines commonly used colour codes, corresponding to the severity of the log.
    static [Hashtable] $MessageType = @{
        Error = [System.ConsoleColor]::Red
        Warning = [System.ConsoleColor]::Yellow
        Info = [System.ConsoleColor]::Cyan
        Update = [System.ConsoleColor]::Green
        Default = [System.ConsoleColor]::White
    }

    static [String] $DoubleDashLine = "========================================================================================================================"
    static [String] $SingleDashLine = "------------------------------------------------------------------------------------------------------------------------"
}