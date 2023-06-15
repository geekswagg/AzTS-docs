<###
# Overview:
    This script is used to remediate GuestConfiguration on Virtual Machine in a Subscription.

# Control ID:
    Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension

# Display Name:
    Guest Configuration extension must be deployed to the VM using Azure Policy assignment.

# Prerequisites:
    Contributor or higher priviliged role on the Virtual Machine(s) is required for remediation.

# Steps performed by the script:
    To remediate:
        1. Validating and installing the modules required to run the script and validating the user.
        2. Get the list of Virtual Machine(s) in a Subscription that does not Guest Configuration Extension .
        3. Back up details of Virtual Machine(s) that are to be remediated.
        4. Remediate Guest Configuration Extension on Virtual Machine(s) in the Subscription.

    To roll back:
        1. Validate and install the modules required to run the script and validating the user.
        2. Get the list of Virtual Machine(s) in a Subscription, the changes made to which previously, are to be rolled back.
        3. Roll back port on all Virtual Machine(s) in the Subscription.

# Instructions to execute the script:
    To remediate:
        1. Download the script.
        2. Load the script in a PowerShell session. Refer https://aka.ms/AzTS-docs/RemediationscriptExcSteps to know more about loading the script.
        3. Execute the script to remediate Guest Configuration Extension on Virtual Machine(s) in the Subscription. Refer `Examples`, below.

    To roll back:
        1. Download the script.
        2. Load the script in a PowerShell session. Refer https://aka.ms/AzTS-docs/RemediationscriptExcSteps to know more about loading the script.
        3. Execute the script to remove access to security scanner identity on all Virtual Machine(s) in the Subscription. Refer `Examples`, below.

# Examples:
    To remediate:
        1. To review the Virtual Machine(s) in a Subscription that will be remediated:
    
           Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -DryRun

        2. Install Guest Configuration Extension on Virtual Machine(s) in the Subscription:
       
           Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck

        3. Install Guest Configuration Extension on Virtual Machine(s) in the Subscription, from a previously taken snapshot:
       
           Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\202205200418\VirtualMachineGuestConfigExtension\NonCompliantVirtualMachineGuestConfig.csv

        To know more about the options supported by the remediation command, execute:
        
        Get-Help Set-VirtualMachineGuestConfigExtension -Detailed

    To roll back:
        1. Revert back Guest Configuration Extension on Virtual Machine(s) in the Subscription, from a previously taken snapshot:
           Reset-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\VirtualMachineGuestConfigExtension\RemediatedVirtualMachine.csv
       
        To know more about the options supported by the roll back command, execute:
        
        Get-Help Reset-VirtualMachineGuestConfigExtension-Detailed        
###>


function Setup-Prerequisites {
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
    $requiredModules = @("Az.Accounts", "Az.Compute")

    Write-Host "Required modules: $($requiredModules -join ', ')" -ForegroundColor $([Constants]::MessageType.Info)
    Write-Host "Checking if the required modules are present..."

    $availableModules = $(Get-Module -ListAvailable $requiredModules -ErrorAction Stop)

    # Check if the required modules are installed.
    $requiredModules | ForEach-Object {
        if ($availableModules.Name -notcontains $_) {
            Write-Host "Installing [$($_)] module..." -ForegroundColor $([Constants]::MessageType.Info)
            Install-Module -Name $_ -Scope CurrentUser -Repository 'PSGallery' -ErrorAction Stop
            Write-Host "[$($_)] module is installed." -ForegroundColor $([Constants]::MessageType.Update)
        }
        else {
            Write-Host "[$($_)] module is present." -ForegroundColor $([Constants]::MessageType.Update)
        }
    }
    Write-Host "All required modules are present." -ForegroundColor $([Constants]::MessageType.Update)
    Write-Host $([Constants]::SingleDashLine)
}


function Set-VirtualMachineGuestConfigExtension {
    <#
        .SYNOPSIS
        Remediates 'Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension' Control.

        .DESCRIPTION
        Remediates 'Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension' Control.
        Install Guest Configuration Extension on Virtual Machine(s). 
        
        .PARAMETER SubscriptionId
        Specifies the ID of the Subscription to be remediated.
        
        .PARAMETER Force
        Specifies a forceful remediation without any prompts.
        
        .Parameter PerformPreReqCheck
        Specifies validation of prerequisites for the command.
        
        .PARAMETER DryRun
        Specifies a dry run of the actual remediation.
        
        .PARAMETER FilePath
        Specifies the path to the file to be used as input for the remediation.
        
        .PARAMETER SkipBackup
        Specifies that no back up will be taken by the script before remediation.

        .PARAMETER Path
        Specifies the path to the file to be used as input for the remediation when AutoRemediation switch is used.

        .PARAMETER TimeStamp
        Specifies the time of creation of file to be used for logging remediation details when AutoRemediation switch is used.

        .INPUTS
        None. You cannot pipe objects to Set-VirtualMachineGuestConfigExtension.

        .OUTPUTS
        None. Set-VirtualMachineGuestConfigExtension does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -DryRun

        .EXAMPLE
        PS> Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck

        .EXAMPLE
        PS> Set-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\202205200418\VirtualMachineGuestConfigExtension\NonCompliantVirtualMachineGuestConfig.csv

        .LINK
        None
    #>

    param (
        [String]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage = "Specifies the ID of the Subscription to be remediated")]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $true, HelpMessage = "Specifies the ID of the Subscription to be remediated")]
        $SubscriptionId,

        [Switch]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies a forceful remediation without any prompts")]
        $Force,

        [Switch]
        [Parameter(ParameterSetName = "DryRun", HelpMessage = "Specifies validation of prerequisites for the command")]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies validation of prerequisites for the command")]
        $PerformPreReqCheck,

        [Switch]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage = "Specifies a dry run of the actual remediation")]
        $DryRun,

        [Switch]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies no back up will be taken by the script before remediation")]
        $SkipBackup,

        [String]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies the path to the file to be used as input for the remediation")]
        $FilePath,

        [String]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies the path to the file to be used as input for the remediation when AutoRemediation switch is used")]
        $Path,

        [String]
        [Parameter(ParameterSetName = "WetRun", HelpMessage = "Specifies the time of creation of file to be used for logging remediation details when AutoRemediation switch is used")]
        $TimeStamp
    )

    Write-Host $([Constants]::DoubleDashLine)

    if ($PerformPreReqCheck) {
        try {
            Write-Host "[Step 1 of 4] Validating and installing the modules required to run the script and validating the user..."
            Write-Host $([Constants]::SingleDashLine)
            Write-Host "Setting up prerequisites..."
            Setup-Prerequisites
        }
        catch {
            Write-Host "Error occurred while setting up prerequisites. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            break
        }
    }
    else {
        Write-Host "[Step 1 of 4] Validating the user... "
    }

    # Connect to Azure account
    $context = Get-AzContext

    if ([String]::IsNullOrWhiteSpace($context)) {
        Write-Host $([Constants]::SingleDashLine)
        Write-Host "Connecting to Azure account..."
        Connect-AzAccount -Subscription $SubscriptionId -ErrorAction Stop | Out-Null
        Write-Host "Connected to Azure account." -ForegroundColor $([Constants]::MessageType.Update)
    }

    # Setting up context for the current Subscription.
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    
    
    Write-Host "Current context has been set to below details: " -ForegroundColor $([Constants]::MessageType.Update)
    Write-Host "Subscription Name: [$($context.Subscription.Name)]"
    Write-Host "Subscription ID: [$($context.Subscription.SubscriptionId)]"
    Write-Host "Account Name: [$($context.Account.Id)]"
    Write-Host "Account Type: [$($context.Account.Type)]"
    Write-Host $([Constants]::SingleDashLine)
    
    Write-Host "***To install GuestConfiguration extension on Virtual Machine in a Subscription, Contributor or higher privileges  are required.***" -ForegroundColor $([Constants]::MessageType.Warning)
   
    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "[Step 2 of 4] Preparing to fetch all Virtual Machine(s)..."
    Write-Host $([Constants]::SingleDashLine)
    
    # list to store resource details.   
    $VirtualMachineDetails = @()

    # To keep track of remediated and skipped resources
    $logRemediatedResources = @()
    $logSkippedResources = @()

    #Control id for the control
    $controlIds = "Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension"

     
    
    # No file path provided as input to the script. Fetch all Virtual Machine(s) in the Subscription.
    if ([String]::IsNullOrWhiteSpace($FilePath)) {
        try {
            Write-Host "Fetching all Virtual Machine(s) in Subscription: $($context.Subscription.SubscriptionId)" -ForegroundColor $([Constants]::MessageType.Info)

            # Get all Virtual Machine(s) in a Subscription
            $VirtualMachineDetails = Get-AzVM -ErrorAction Stop

            # Seperating required properties
            $VirtualMachineDetails = $VirtualMachineDetails | Select-Object @{N = 'ResourceId'; E = { $_.Id } },
            @{N = 'ResourceGroupName'; E = { $_.ResourceGroupName } },
            @{N = 'ResourceName'; E = { $_.Name } },
            @{N = 'OsType'; E = { $_.StorageProfile.OsDisk.OsType } }
        }
        catch {
            Write-Host "Error fetching Virtual Machine(s) from the subscription. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            $logResource = @{}
            $logResource.Add("SubscriptionID", ($SubscriptionId))
            $logResource.Add("Reason", "Error fetching Virtual Machine(s) information from the subscription.")    
            $logSkippedResources += $logResource
        }    
    }
    else {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Host "ERROR: Input file - $($FilePath) not found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
            break
        }

        Write-Host "Fetching all Virtual Machine(s) from [$($FilePath)]..." 

        $VirtualMachineResources = Import-Csv -LiteralPath $FilePath
        $validVirtualMachineResources = $VirtualMachineResources | Where-Object { ![String]::IsNullOrWhiteSpace($_.ResourceId) }
        $VirtualMachineDetails = $validVirtualMachineResources 
    }
    

    $totalVirtualMachine = ($VirtualMachineDetails | Measure-Object).Count

    if ($totalVirtualMachine -eq 0) {
        Write-Host "No Virtual Machine(s) found. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
        break
    }
  
    Write-Host "Found [$($totalVirtualMachine)] Virtual Machine(s)." -ForegroundColor $([Constants]::MessageType.Update)
                                                                          
    Write-Host $([Constants]::SingleDashLine)
    
    # list for storing Virtual Machine(s) where required Guest Configuration is not installed
    $NonCompliantVirtualMachineGustExt = @()


    Write-Host "Separating Virtual Machine(s) for which Guest Configuration is not installed..."

    $VirtualMachineDetails | ForEach-Object {
        
        if ([String]::IsNullOrWhiteSpace($FilePath)) {
            $_ | Add-Member -NotePropertyName isSystemAssignedManagedIdentityPresent -NotePropertyValue $false
            $_ | Add-Member -NotePropertyName isGuestConfigurationExtensionPresent -NotePropertyValue $false
        }
        $VirtualMachine = $_

        $IsExtPresent = $false;
        #Getting list of extensions
        if (![System.Convert]::ToBoolean($_.isGuestConfigurationExtensionPresent) ) {
            $VMExtension = Get-AzVMExtension -ResourceGroupName $_.ResourceGroupName -VMName $_.ResourceName
            $VMExtension | ForEach-Object {

                if (!$IsExtPresent) {           
                    if ($VMExtension.Publisher -contains ("Microsoft.GuestConfiguration")) {
                        $logResource = @{}
                        $logResource.Add("ResourceGroupName", ($_.ResourceGroupName))
                        $logResource.Add("ResourceName", ($_.ResourceName))
                        $logResource.Add("Reason", "Guest Configuration is installed on Virtual Machine.")    
                        $logSkippedResources += $logResource
                        
                    }
                    else {
                        $NonCompliantVirtualMachineGustExt += $VirtualMachine
                        $IsExtPresent = $true;
                    }
                }
            }
        }
        if (!$IsExtPresent) {
            $_.isGuestConfigurationExtensionPresent = $true
        }

        #Checking if System Managed Identity is present 
        if (![System.Convert]::ToBoolean($_.isSystemAssignedManagedIdentityPresent)  ) {
            $VMDetail = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.ResourceName

            if ($VMDetail.Identity.Type -contains "SystemAssignedUserAssigned" -or $VMDetail.Identity.Type -contains "SystemAssigned") {
                $_.isSystemAssignedManagedIdentityPresent = $true
            }
            else {
                $NonCompliantVirtualMachineGustExt += $VirtualMachine
            }
        }
    }
   
    $totalNonCompliantVirtualMachineGustExt = ($NonCompliantVirtualMachineGustExt | Measure-Object).Count

    if ($totalNonCompliantVirtualMachineGustExt -eq 0) {
        Write-Host "No VirtualMachine(s) found without Guest Configuration.. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
        break
    }

    Write-Host "Found [$($totalNonCompliantVirtualMachineGustExt)] Virtual Machine(s) with non compliant for Guest Extension not installed:" -ForegroundColor $([Constants]::MessageType.Update)

    $colsProperty = @{Expression = { $_.ResourceName }; Label = "ResourceName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceGroupName }; Label = "ResourceGroupName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceId }; Label = "ResourceId"; Width = 50; Alignment = "left" },
    @{Expression = { $_.OsType }; Label = "OsType"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isSystemAssignedManagedIdentityPresent }; Label = "isSystemAssignedManagedIdentityPresent"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isGuestConfigurationExtensionPresent }; Label = "isGuestConfigurationExtensionPresent"; Width = 10; Alignment = "left" }

        
    $NonCompliantVirtualMachineGustExt | Format-Table -Property $colsProperty -Wrap

    # Back up snapshots to `%LocalApplicationData%'.
    $backupFolderPath = "$([Environment]::GetFolderPath('LocalApplicationData'))\AzTS\Remediation\Subscriptions\$($context.Subscription.SubscriptionId.replace('-','_'))\$($(Get-Date).ToString('yyyyMMddhhmm'))\VirtualMachineGuestConfigExtension"

    if (-not (Test-Path -Path $backupFolderPath)) {
        New-Item -ItemType Directory -Path $backupFolderPath | Out-Null
    }
 
    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "[Step 3 of 4] Backing up Virtual Machine(s) details..."
    Write-Host $([Constants]::SingleDashLine)

    if ([String]::IsNullOrWhiteSpace($FilePath)) {
        # Backing up Virtual Machine(s) details.
        $backupFile = "$($backupFolderPath)\NonCompliantVirtualMachineGuestConfig.csv"

        $NonCompliantVirtualMachineGustExt | Export-CSV -Path $backupFile -NoTypeInformation

        Write-Host "Virtual Machine(s) details have been backed up to" -NoNewline
        Write-Host " [$($backupFile)]" -ForegroundColor $([Constants]::MessageType.Update)
    }
    else {
        Write-Host "Skipped as -FilePath is provided" -ForegroundColor $([Constants]::MessageType.Warning)
    }

    if (-not $DryRun) {
        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "[Step 4 of 4] Remediating non compliant Azure Virtual Machine..." 
        Write-Host $([Constants]::SingleDashLine)
        
         
        if (-not $Force) {
            Write-Host "Found total [$($totalNonCompliantVirtualMachineGustExt)] Virtual Machine(s) without Guest Configuration Extension. Guest Configuration Extension for these resources can not be reverted back after remediation." -ForegroundColor $([Constants]::MessageType.Warning)
            Write-Host "This step will install Guest Configuration Extension for all non-complaint [$($totalNonCompliantVirtualMachineGustExt)] Virtual Machine(s)." -ForegroundColor $([Constants]::MessageType.Warning)
            Write-Host "Do you want to Continue? " -ForegroundColor $([Constants]::MessageType.Warning)
            
            $userInput = Read-Host -Prompt "(Y|N)"

            if ($userInput -ne "Y") {
                Write-Host "Guest Configuration Extension will not be installed on Virtual Machine(s) in the Subscription. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
                break
            }
        }
        else {
            Write-Host "'Force' flag is provided. Guest Configuration Extension will be installed on Virtual Machine(s) in the Subscription without any further prompts." -ForegroundColor $([Constants]::MessageType.Warning)
        }
        

        # List for storing remediated Virtual Machine(s)
        $VirtualMachineRemediated = @()

        # List for storing skipped Virtual Machine(s)
        $VirtualMachineSkipped = @()

        Write-Host "Installing Guest Configuration Extension on Virtual Machine(s)." -ForegroundColor $([Constants]::MessageType.Info)
        Write-Host $([Constants]::SingleDashLine)

        # Loop through the list of VirtualMachine(s) which needs to be remediated.
        $NonCompliantVirtualMachineGustExt | ForEach-Object {
            $isGuestConfigurationExtInstallSuccessful = $false
            $isManagedIdentityInstallSuccessful = $false

            $VirtualMachine = $_
            $VirtualMachine | Add-Member -NotePropertyName isGuestConfigurationInstalledByRemediation -NotePropertyValue $false
            $VirtualMachine | Add-Member -NotePropertyName isSystemManagedIdenityInstalledByRemediation -NotePropertyValue $false

           

            try {
                

                if ($_.ResourceName -ieq "v-rahkumaTestVM" -or $_.ResourceName -ieq "v-rahkumaTestVM2" ) {
                    #checking the System Assigned Managed Identity
                    $VMResponse = @()
                    
                    if (![System.Convert]::ToBoolean($_.isSystemAssignedManagedIdentityPresent)) {
                        Write-Host "Installing System Assigned Managed Idenity on [$($_.ResourceName)]." -ForegroundColor $([Constants]::MessageType.Info)
                        $VMDetail = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.ResourceName
                        $VMResponse = Update-AzVM -ResourceGroupName $_.ResourceGroupName -VM $VMDetail  -IdentityType SystemAssigned
                        if ($VMResponse.IsSuccessStatusCode) {
                            $isGuestConfigurationExtInstallSuccessful = $true
                        }

                    }
                    else {
                        $isGuestConfigurationExtInstallSuccessful = $true
                    }

                    if (![System.Convert]::ToBoolean($_.isGuestConfigurationExtensionPresent)) {
                        Write-Host "Installing Guest Configuration on [$($_.ResourceName)]." -ForegroundColor $([Constants]::MessageType.Info)

                        #check os type before installing
                        if ($_.OsType -ieq "Windows") {
                            $VirtualMachineResources = Set-AzVMExtension -Publisher 'Microsoft.GuestConfiguration' -ExtensionType 'ConfigurationforWindows' -TypeHandlerVersion 1.0 -Name 'AzurePolicyforWindows' -ResourceGroupName $_.ResourceGroupName  -VMName $_.ResourceName -EnableAutomaticUpgrade $true;
                        }
                        else {
                            $VirtualMachineResources = Set-AzVMExtension -Publisher 'Microsoft.GuestConfiguration' -ExtensionType 'ConfigurationForLinux' -Name 'AzurePolicyforLinux' -TypeHandlerVersion 1.0 -ResourceGroupName $_.ResourceGroupName -VMName $_.ResourceName -EnableAutomaticUpgrade $true;
                        }

                        if ($VirtualMachineResources.IsSuccessStatusCode) {
                            $isManagedIdentityInstallSuccessful = $true
                        }
                    }
                    else {
                        $isManagedIdentityInstallSuccessful = $true
                    }
                }

                #to be reviewed
                if ($isGuestConfigurationExtInstallSuccessful -and $isManagedIdentityInstallSuccessful) {

                    if (![System.Convert]::ToBoolean($_.isSystemAssignedManagedIdentityPresent)) {
                        $VirtualMachine.isSystemManagedIdenityInstalledByRemediation = $true
                    }
                    if (![System.Convert]::ToBoolean($_.isGuestConfigurationExtensionPresent)) {
                        $VirtualMachine.isGuestConfigurationInstalledByRemediation = $true
                    }
                    
                    $VirtualMachineRemediated += $VirtualMachine                  
                    $logResource = @{}
                    $logResource.Add("ResourceGroupName", ($_.ResourceGroupName))
                    $logResource.Add("ResourceName", ($_.ResourceName))
                    $logRemediatedResources += $logResource
                    Write-Host "Successfully installed Guest Configuration Extension for the resource [$($_.ResourceName)]." -ForegroundColor $([Constants]::MessageType.Update)
                    Write-Host $([Constants]::SingleDashLine)
                }
                else {
                    if ($isGuestConfigurationExtInstallSuccessful) {
                        $VirtualMachine.isGuestConfigurationInstalledByRemediation = $true
                    }
                    else {
                        $VirtualMachine.isGuestConfigurationInstalledByRemediation = $false

                    }
                    if ($isManagedIdentityInstallSuccessful) {
                        $VirtualMachine.isSystemManagedIdenityInstalledByRemediation = $true
                    }
                    else {
                        $VirtualMachine.isSystemManagedIdenityInstalledByRemediation = $false
                    }

                    $VirtualMachineSkipped += $VirtualMachine
                    $logResource = @{}
                    $logResource.Add("ResourceGroupName", ($_.ResourceGroupName))
                    $logResource.Add("ResourceName", ($_.ResourceName))
                    $logResource.Add("Reason", "Error occured while instlling Guest Configuration Extension on VM.")
                    $logSkippedResources += $logResource
                    Write-Host "Skipping this Virtual Machine resource." -ForegroundColor $([Constants]::MessageType.Warning)
                    Write-Host $([Constants]::SingleDashLine)
                }  
            }
            catch {
                $VirtualMachineSkipped += $VirtualMachine
                Write-Host $([Constants]::SingleDashLine)
                $logResource = @{}
                $logResource.Add("ResourceGroupName", ($_.ResourceGroupName))
                $logResource.Add("ResourceName", ($_.ResourceName))
                $logResource.Add("Reason", "Error occured while instlling Guest Configuration Extension on VM.")
                $logSkippedResources += $logResource
                Write-Host "Skipping this Virtual Machine resource." -ForegroundColor $([Constants]::MessageType.Warning)
                Write-Host $([Constants]::SingleDashLine)
            }
        }

        $colsPropertyRemediated = @{Expression = { $_.ResourceName }; Label = "ResourceName"; Width = 30; Alignment = "left" },
        @{Expression = { $_.ResourceGroupName }; Label = "ResourceGroupName"; Width = 30; Alignment = "left" },
        @{Expression = { $_.ResourceId }; Label = "ResourceId"; Width = 50; Alignment = "left" },
        @{Expression = { $_.OsType }; Label = "OsType"; Width = 10; Alignment = "left" },
        @{Expression = { $_.isGuestConfigurationInstalledByRemediation }; Label = "isGuestConfigurationInstalledByRemediation"; Width = 10; Alignment = "left" }

        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "Remediation Summary: " -ForegroundColor $([Constants]::MessageType.Info)

        if ($($VirtualMachineRemediated | Measure-Object).Count -gt 0) {
            Write-Host "Guest Configuration Extension installed on the following Virtual Machine(s) in the subscription:" -ForegroundColor $([Constants]::MessageType.Update)
           
            $VirtualMachineRemediated | Format-Table -Property $colsPropertyRemediated -Wrap

            # Write this to a file.
            $VirtualMachineRemediatedFile = "$($backupFolderPath)\RemediatedVirtualMachine.csv"
            $VirtualMachineRemediated | Export-CSV -Path $VirtualMachineRemediatedFile -NoTypeInformation

            Write-Host "This information has been saved to" -NoNewline
            Write-Host " [$($VirtualMachineRemediatedFile)]" -ForegroundColor $([Constants]::MessageType.Update) 
            Write-Host "Use this file for any roll back that may be required." -ForegroundColor $([Constants]::MessageType.Info)
        }

        if ($($VirtualMachineSkipped | Measure-Object).Count -gt 0) {
            Write-Host "Error while installing Guest Configuration Extension on the following Virtual Machine(s) in the subscription: " -ForegroundColor $([Constants]::MessageType.Error)
            $VirtualMachineSkipped | Format-Table -Property $colsProperty -Wrap
            # Write this to a file.
            $VirtualMachineSkippedFile = "$($backupFolderPath)\SkippedVirtualMachine.csv"
            $VirtualMachineSkipped | Export-CSV -Path $VirtualMachineSkippedFile -NoTypeInformation
            Write-Host "This information has been saved to"  -NoNewline
            Write-Host " [$($VirtualMachineSkippedFile)]" -ForegroundColor $([Constants]::MessageType.Update)
        }
    }
    else {
        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "[Step 4 of 4]  Remediating non compliant Azure Virtual Machine..."
        Write-Host $([Constants]::SingleDashLine)
        Write-Host "Skipped as -DryRun switch is provided." -ForegroundColor $([Constants]::MessageType.Warning)
        Write-Host $([Constants]::DoubleDashLine)

        Write-Host "Next steps:" -ForegroundColor $([Constants]::MessageType.Info)
        Write-Host "Run the same command with -FilePath $($backupFile) and without -DryRun, install Guest Configuration Extension on VirtualMachine(s) listed in the file."
    }
}

function Reset-VirtualMachineGuestConfigExtension {
    <#
        .SYNOPSIS
        Rolls back remediation done for 'Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension' Control.

        .DESCRIPTION
        Rolls back remediation done for 'Azure_VirtualMachine_SI_Deploy_GuestConfig_Extension' Control.
        Install Guest Configuration Extension for Virtual Machine. 
        
        .PARAMETER SubscriptionId
        Specifies the ID of the Subscription that was previously remediated.
        
        .PARAMETER Force
        Specifies a forceful roll back without any prompts.
        
        .Parameter PerformPreReqCheck
        Specifies validation of prerequisites for the command.
      
        .PARAMETER FilePath
        Specifies the path to the file to be used as input for the roll back.

        .INPUTS
        None. You cannot pipe objects to Reset-VirtualMachineGuestConfigExtension.

        .OUTPUTS
        None. Reset-VirtualMachineGuestConfigExtension does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Reset-VirtualMachineGuestConfigExtension -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\202109131040\VirtualMachineGuestConfigExtension\NonCompliantVirtualMachineGuestConfig.csv

        .LINK
        None
    #>

    param (
        [String]
        [Parameter(Mandatory = $true, HelpMessage = "Specifies the ID of the Subscription that was previously remediated.")]
        $SubscriptionId,

        [Switch]
        [Parameter(HelpMessage = "Specifies a forceful roll back without any prompts")]
        $Force,

        [Switch]
        [Parameter(HelpMessage = "Specifies validation of prerequisites for the command")]
        $PerformPreReqCheck,

        [String]
        [Parameter(Mandatory = $true, HelpMessage = "Specifies the path to the file to be used as input for the roll back")]
        $FilePath
    )

    if ($PerformPreReqCheck) {
        try {
            Write-Host "[Step 1 of 3] Validating and installing the modules required to run the script and validating the user..."
            Write-Host $([Constants]::SingleDashLine)
            Write-Host "Setting up prerequisites..."
            Setup-Prerequisites
        }
        catch {
            Write-Host "Error occurred while setting up prerequisites. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            break
        }
    }
    else {
        Write-Host "[Step 1 of 3] Validating the user..." 
    }  

    # Connect to Azure account
    $context = Get-AzContext

    if ([String]::IsNullOrWhiteSpace($context)) {
        Write-Host $([Constants]::SingleDashLine)
        Write-Host "Connecting to Azure account..."
        Connect-AzAccount -Subscription $SubscriptionId -ErrorAction Stop | Out-Null
        Write-Host "Connected to Azure account." -ForegroundColor $([Constants]::MessageType.Update)
    }

    # Setting up context for the current Subscription.
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    
    Write-Host $([Constants]::SingleDashLine)
    Write-Host "Subscription Name: [$($context.Subscription.Name)]"
    Write-Host "Subscription ID: [$($context.Subscription.SubscriptionId)]"
    Write-Host "Account Name: [$($context.Account.Id)]"
    Write-Host "Account Type: [$($context.Account.Type)]"
    Write-Host $([Constants]::SingleDashLine)

    Write-Host "*** To install GuestConfiguration extension on Virtual Machine in a Subscription, Contributor or higher privileges  are required***" -ForegroundColor $([Constants]::MessageType.Warning)

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "[Step 2 of 3] Preparing to fetch all Virtual Machine(s)..."
    Write-Host $([Constants]::SingleDashLine)
    
    if (-not (Test-Path -Path $FilePath)) {
        Write-Host "ERROR: Input file - [$($FilePath)] not found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
        break
    }

    Write-Host "Fetching all Virtual Machine(s) from" -NoNewline
    Write-Host " [$($FilePath)]..." -ForegroundColor $([Constants]::MessageType.Update)
    $VirtualMachineDetails = Import-Csv -LiteralPath $FilePath

    $validVirtualMachineDetails = $VirtualMachineDetails | Where-Object { ![String]::IsNullOrWhiteSpace($_.ResourceId) -and ![String]::IsNullOrWhiteSpace($_.ResourceGroupName) -and ![String]::IsNullOrWhiteSpace($_.ResourceName) }

    $totalVirtualMachine = $(($validVirtualMachineDetails | Measure-Object).Count)

    if ($totalVirtualMachine -eq 0) {
        Write-Host "No Virtual Machine(s) found. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
        break
    }

    Write-Host "Found [$(($totalVirtualMachine|Measure-Object).Count)] Virtual Machine(s)." -ForegroundColor $([Constants]::MessageType.Update)

    $colsProperty = @{Expression = { $_.ResourceName }; Label = "ResourceName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceGroupName }; Label = "ResourceGroupName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceId }; Label = "ResourceId"; Width = 50; Alignment = "left" },
    @{Expression = { $_.OsType }; Label = "OsType"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isSystemAssignedManagedIdentityPresent }; Label = "isSystemAssignedManagedIdentityPresent"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isGuestConfigurationExtensionPresent }; Label = "isGuestConfigurationExtensionPresent"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isGuestConfigurationInstalledByRemediation }; Label = "isGuestConfigurationInstalledByRemediation"; Width = 10; Alignment = "left" },
    @{Expression = { $_.isSystemManagedIdenityInstalledByRemediation }; Label = "isSystemManagedIdenityInstalledByRemediation"; Width = 10; Alignment = "left" }  

        
    $validVirtualMachineDetails | Format-Table -Property $colsProperty -Wrap
    
    # Back up snapshots to `%LocalApplicationData%'.
    $backupFolderPath = "$([Environment]::GetFolderPath('LocalApplicationData'))\AzTS\Remediation\Subscriptions\$($context.Subscription.SubscriptionId.replace('-','_'))\$($(Get-Date).ToString('yyyyMMddhhmm'))\Rollback"

    if (-not (Test-Path -Path $backupFolderPath)) {
        New-Item -ItemType Directory -Path $backupFolderPath | Out-Null
    }
 
  
    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "[Step 3 of 3] Rolling back Guest Configuration Extension for all Virtual Machine(s) in the Subscription..."
    Write-Host $([Constants]::SingleDashLine)

    if ( -not $Force) {
        Write-Host "Do you want to continue roll back operation?"  -ForegroundColor $([Constants]::MessageType.Warning)
        $userInput = Read-Host -Prompt "(Y|N)"

        if ($userInput -ne "Y") {
            Write-Host "Guest Configuration Extension will not be rolled back for any Virtual Machine(s) in the Subscription. Exiting..." -ForegroundColor $([Constants]::MessageType.Warning)
            break
        }
    }
    else {
        Write-Host "'Force' flag is provided. Guest Configuration Extension will be rolled back for any Virtual Machine(s) in the Subscription without any further prompts." -ForegroundColor $([Constants]::MessageType.Warning)
    }

    # List for storing rolled back Virtual Machine resource.
    $VirtualMachineRolledBack = @()

    # List for storing skipped rolled back Virtual Machine resource.
    $VirtualMachineForGuestConfigExtensionSkipped = @()
    $VirtualMachineForManagedIdentitySkipped = @()
    $IsManagedIdentityRolledback = $false;
    $IsGuestConfigurationExtensionRolledback = $false;



    Write-Host "Starting Roll back operation..." -ForegroundColor $([Constants]::MessageType.Info)
    Write-Host $([Constants]::SingleDashLine)

    $validVirtualMachineDetails | ForEach-Object {
        $VirtualMachine = $_
        $SkippedUserAssignedIdentitiesKeys = @()
        $VirtualMachine | Add-Member -NotePropertyName isGuestConfigExtensionRolledback -NotePropertyValue $false
        $VirtualMachine | Add-Member -NotePropertyName isSystemManagedIdenityRolledback -NotePropertyValue $false
        $VirtualMachine | Add-Member -NotePropertyName skippedUserAssignedIdentitiesKeys -NotePropertyValue "-"

        try {
            
            Write-Host "Rolling back Guest Configuration Extension on Virtual Machine(s) - [$($_.ResourceName)]" -ForegroundColor $([Constants]::MessageType.Info)
            if ($_.isGuestConfigurationInstalledByRemediation -or $_.isSystemManagedIdenityInstalledByRemediation) {
                if ($_.ResourceName -ieq "v-rahkumaTestVM" -or $_.ResourceName -ieq "v-rahkumaTestVM2" ) { 

                    if ([System.Convert]::ToBoolean($_.isGuestConfigurationInstalledByRemediation)) {
                        if ($_.OsType -ieq "Windows") {
                            $VirtualMachineResource = Remove-AzVMExtension -ResourceGroupName $_.ResourceGroupName -VMName  $_.ResourceName -Name 'AzurePolicyforWindows'
                        }
                        else {
                            $VirtualMachineResource = Remove-AzVMExtension -ResourceGroupName $_.ResourceGroupName -VMName  $_.ResourceName -Name 'AzurePolicyforLinux'
                        }

                        if ($VirtualMachineResource.IsSuccessStatusCode) {
                            $IsGuestConfigurationExtensionRolledback = $true
                        }
                    }
                    else {
                        $IsGuestConfigurationExtensionRolledback = $true
                    }
                    if ([System.Convert]::ToBoolean($_.isSystemManagedIdenityInstalledByRemediation)) {
                        $VMDetail = Get-AzVM -ResourceGroupName $_.ResourceGroupName -Name $_.ResourceName
                        $UserAssignedIdentityKey = $VMDetail.Identity.UserAssignedIdentities.Keys -split (' ')
                        #key add in excel
                        try {
                            #removing all the identity 
                            $VirtualMachineIdentityResponse = Update-AzVM -ResourceGroupName $_.ResourceGroupName -VM $VMDetail  -IdentityType "None"
                            $IsManagedIdentityRolledback = $VirtualMachineIdentityResponse.IsSuccessStatusCode                       
                            if ($IsManagedIdentityRolledback) {
                                #Reassigning all the User Managed Identity
                                $UserAssignedIdentityKey | ForEach-Object {
                                    Write-Host $UserAssignedIdentityKey
                                  
                                    $VirtualMachineIdentityResponse = Update-AzVM -ResourceGroupName $_.ResourceGroupName -VM $VMDetail  -IdentityType "UserAssigned" -IdentityId $UserAssignedIdentityKey
                                    if (!$VirtualMachineIdentityResponse.IsSuccessStatusCode) {
                                        $IsManagedIdentityRolledback = $false;
                                    }
                                    else {
                                        $SkippedUserAssignedIdentitiesKeys += " " + $UserAssignedIdentityKey
                                    }
                                   
                                }
                            }
                        }
                        catch {
                            $VirtualMachineForManagedIdentitySkipped += $VirtualMachine
                        }
                    }
                    else {
                        $IsManagedIdentityRolledback = $true
                    }

                }
        
                if ($IsGuestConfigurationExtensionRolledback -and $IsManagedIdentityRolledback) {
                    Write-Host "Succesfully rolled back Guest Configuration Extension on VirtualMachine(s) - [$($_.ResourceName)]" -ForegroundColor $([Constants]::MessageType.Update)
                    Write-Host $([Constants]::SingleDashLine) 
                    if ([System.Convert]::ToBoolean($_.isGuestConfigurationInstalledByRemediation)) {
                        $VirtualMachine.isGuestConfigurationInstalledByRemediation = $false
                        $VirtualMachine.isGuestConfigExtensionRolledback = $true
                    }
                    if ([System.Convert]::ToBoolean($_.isSystemManagedIdenityInstalledByRemediation)) {
                        $VirtualMachine.isSystemManagedIdenityRolledback = $true;
                        $VirtualMachine.isSystemManagedIdenityInstalledByRemediation = $false;
                    }
                    $VirtualMachineRolledBack += $VirtualMachine    
                }
                elseif (!$VirtualMachineResource.IsSuccessStatusCode) {
                    $VirtualMachine.isGuestConfigExtensionRolledback = $false
                    $VirtualMachineForGuestConfigExtensionSkipped += $VirtualMachine

                }
                elseif (!IsManagedIdentityRolledback) {
                    $VirtualMachine.isSystemManagedIdenityRolledback = $false
                    $VirtualMachine.skippedUserAssignedIdentitiesKeys = $SkippedUserAssignedIdentitiesKeys

                    $VirtualMachineForManagedIdentitySkipped += $VirtualMachine
                }
               
            }
            
        }
        catch {
            $VirtualMachineForGuestConfigExtensionSkipped += $VirtualMachine
        }
    }

    $colsPropertyRollBack = @{Expression = { $_.ResourceName }; Label = "ResourceName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceGroupName }; Label = "ResourceGroupName"; Width = 30; Alignment = "left" },
    @{Expression = { $_.ResourceId }; Label = "ResourceId"; Width = 50; Alignment = "left" },
    @{Expression = { $_.isGuestConfigurationInstalledByRemediation }; Label = "isGuestConfigurationInstalledByRemediation"; Width = 50; Alignment = "left" },
    @{Expression = { $_.isGuestConfigExtensionRolledback }; Label = "isGuestConfigExtensionRolledback"; Width = 50; Alignment = "left" },
    @{Expression = { $_.isSystemManagedIdenityInstalledByRemediation }; Label = "isSystemManagedIdenityInstalledByRemediation"; Width = 50; Alignment = "left" },
    @{Expression = { $_.isSystemManagedIdenityRolledback }; Label = "isSystemManagedIdenityRolledback"; Width = 50; Alignment = "left" },
    @{Expression = { $_.skippedUserAssignedIdentitiesKeys }; Label = "skippedUserAssignedIdentitiesKeys"; Width = 50; Alignment = "left" }


    if ($($VirtualMachineRolledBack | Measure-Object).Count -gt 0 -or $($VirtualMachineForGuestConfigExtensionSkipped | Measure-Object).Count -gt 0 -or $($VirtualMachineForManagedIdentitySkipped | Measure-Object).Count -gt 0) {
        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "Rollback Summary: " -ForegroundColor $([Constants]::MessageType.Info)
        
        if ($($VirtualMachineRolledBack | Measure-Object).Count -gt 0) {
            Write-Host "Guest Configuration Extension is rolled back successfully on following Virtual Machine(s) in the Subscription: " -ForegroundColor $([Constants]::MessageType.Update)
            $VirtualMachineRolledBack | Format-Table -Property $colsPropertyRollBack -Wrap

            # Write this to a file.
            $VirtualMachineRolledBackFile = "$($backupFolderPath)\RolledBackVirtualMachine.csv"
            $VirtualMachineRolledBack | Export-CSV -Path $VirtualMachineRolledBackFile -NoTypeInformation
            Write-Host "This information has been saved to" -NoNewline
            Write-Host " [$($VirtualMachineRolledBackFile)]" -ForegroundColor $([Constants]::MessageType.Update) 
            Write-Host $([Constants]::SingleDashLine)
        }

        if ($($VirtualMachineForGuestConfigExtensionSkipped | Measure-Object).Count -gt 0) {
            Write-Host "Error uninstalling Guest Configuration on following Virtual Machine(s) in the Subscription: " -ForegroundColor $([Constants]::MessageType.Warning)
            
            $VirtualMachineForGuestConfigExtensionSkipped | Format-Table -Property $colsProperty -Wrap
            
            # Write this to a file.
            $VirtualMachineForGuestConfigExtensionSkippedFile = "$($backupFolderPath)\RollbackSkippedVirtualMachineForGuestConfigExtension.csv"
            $VirtualMachineForGuestConfigExtensionSkipped | Export-CSV -Path $VirtualMachineForGuestConfigExtensionSkippedFile -NoTypeInformation
            Write-Host "This information has been saved to" -NoNewline
            Write-Host " [$($VirtualMachineForGuestConfigExtensionSkippedFile)]" -ForegroundColor $([Constants]::MessageType.Update)  
            Write-Host $([Constants]::SingleDashLine)

        }

        if ($($VirtualMachineForManagedIdentitySkipped | Measure-Object).Count -gt 0) {
            Write-Host "Error uninstalling Guest Configuration on following Virtual Machine(s) in the Subscription: " -ForegroundColor $([Constants]::MessageType.Warning)
            
            $VirtualMachineForManagedIdentitySkipped | Format-Table -Property $colsProperty -Wrap
            
            # Write this to a file.
            $VirtualMachineForManagedIdentitySkippedFile = "$($backupFolderPath)\RollbackSkippedVirtualMachineForManagedIdentity.csv"
            $VirtualMachineForManagedIdentitySkipped | Export-CSV -Path $VirtualMachineForManagedIdentitySkippedFile -NoTypeInformation
            Write-Host "This information has been saved to" -NoNewline
            Write-Host " [$($VirtualMachineForManagedIdentitySkippedFile)]" -ForegroundColor $([Constants]::MessageType.Update)  
            Write-Host $([Constants]::SingleDashLine)

        }
    }
}

# Defines commonly used constants.
class Constants {
    # Defines commonly used colour codes, corresponding to the severity of the log.
    static [Hashtable] $MessageType = @{
        Error   = [System.ConsoleColor]::Red
        Warning = [System.ConsoleColor]::Yellow
        Info    = [System.ConsoleColor]::Cyan
        Update  = [System.ConsoleColor]::Green
        Default = [System.ConsoleColor]::White
    }

    static [String] $DoubleDashLine = "========================================================================================================================"
    static [String] $SingleDashLine = "------------------------------------------------------------------------------------------------------------------------"
}
