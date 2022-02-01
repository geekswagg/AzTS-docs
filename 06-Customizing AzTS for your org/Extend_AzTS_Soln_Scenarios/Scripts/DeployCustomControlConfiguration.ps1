########### Load Common Functions And Classes ###############

class TokenProvider
{

    [PSObject] GetAuthHeader([string] $resourceAppIdUri)
    {
        [psobject] $headers = $null
        try 
        {
            $rmContext = Get-AzContext
            
            $authResult = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
            $rmContext.Account,
            $rmContext.Environment,
            $rmContext.Tenant,
            [System.Security.SecureString] $null,
            "Never",
            $null,
            $resourceAppIdUri); 
            
            $header = "Bearer " + $authResult.AccessToken
            $headers = @{"Authorization"=$header;"Content-Type"="application/json";}
        }
        catch 
        {
            Write-Host "Error occurred while fetching auth header. ErrorMessage [$($_)]" -ForegroundColor Red   
        }
        return($headers)
    }
}

function TriggerBaselineControlInv
{
    <#
	.SYNOPSIS
	This command would help in installing Azure Tenant Security Solution in your subscription. 
	.DESCRIPTION
	This command will install an Azure Tenant Security Solution which runs security scan on subscription in a Tenant.
	Security scan results will be populated in Log Analytics workspace and Azure Storage account which is configured during installation.  
	
	.PARAMETER SubscriptionId
		Subscription id in which Azure Tenant Security Solution needs to be installed.
	.PARAMETER ScanHostRGName
		Name of ResourceGroup where setup resources will be created.

	#>
    param(
        [string]
        [Parameter(Mandatory = $true, HelpMessage="Subscription id in which Azure Tenant Security Solution needs to be installed.")]
        $SubscriptionId,

        [string]
		[Parameter(Mandatory = $true, HelpMessage="Name of ResourceGroup where setup resources will be created.")]
		$ScanHostRGName,

        [switch]
        $ForceFetch
    )
    Begin
        {
            $currentContext = $null
            $contextHelper = [ContextHelper]::new()
            $currentContext = $contextHelper.SetContext($SubscriptionId)
            if(-not $currentContext)
            {
                return;
            }
            #. ".\TokenProvider.ps1"
        }
    Process
    {
        $maFunctionApp = $null
        try
        {
            Write-Host $([ScannerConstants]::DoubleDashLine)
            Write-Host "Running Azure Tenant Security Solution setup...`n" -ForegroundColor Cyan
            Write-Host $([ScannerConstants]::OnDemandScanInstructionMsg ) -ForegroundColor Cyan
            Write-Host $([ScannerConstants]::OnDemandScanWarningMsg ) -ForegroundColor Yellow
            Write-Host $([ScannerConstants]::SingleDashLine)

            $StartTimeAsString = [Datetime]::UtcNow.ToString("MM/dd/yyyy")

            $maFunctionApp = Get-AzWebApp -ResourceGroupName $ScanHostRGName | Where-Object { $_.Name -match "MetadataAggregator"} | Select -First 1
            $applicationInsight = Get-AzApplicationInsights -ResourceGroupName $ScanHostRGName | Where-Object { $_.Name -match "AzSK-AzTS-AppInsights"} | Select -First 1
            $laWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ScanHostRGName | Where-Object { $_.Name -match "AzSK-AzTS-LAWorkspace"} | Select -First 1

            if(($maFunctionApp -ne $null) -and ($applicationInsight -ne $null) -and ($laWorkspace -ne $null))
            {
                if($ForceFetch)
                {
                    Write-Host "[WARNING] Enabling forceFetch for [$($maFunctionApp.Name)] function app." -ForegroundColor Yellow
                    $StartTimeAsString = [Datetime]::UtcNow.ToString("MM/dd/yyyy, HH:mm:ss")
                    $maFunctionAppSlot = Get-AzWebAppSlot -ResourceGroupName $ScanHostRGName -Name $maFunctionApp.Name -Slot 'production'
                    $appSettings = $maFunctionAppSlot.SiteConfig.AppSettings
                    #setup the current app settings
                    $settings = @{}
                    ForEach ($isetting in $appSettings) {
                        $settings[$isetting.Name] = $isetting.Value
                    }

                    $settings['WebJobConfigurations__ForceFetch'] = $true.ToString().Tolower()
                    $updatedSlotDetails = Set-AzWebAppSlot -ResourceGroupName $ScanHostRGName -Name $maFunctionApp.Name -Slot 'production' -AppSettings $settings;
                    Write-Host "Enabled forceFetch for [$($maFunctionApp.Name)] function app." -ForegroundColor Yellow
                }
                

                $functionAppHostName  =  "https://" + $maFunctionApp.DefaultHostName;
                $functionAppKeys = GetFunctionAppKey -AppServiceResourceId $maFunctionApp.Id
                $functionAppMaterKey = $functionAppKeys.masterKey;
                $laWorkspaceId = $laWorkspace.CustomerId.Guid
                
                Write-Host "Triggering Baseline Control  Inventory" -ForegroundColor Yellow
                TriggerFunction -FunctionAppHostName $functionAppHostName -FunctionName  $([ScannerConstants]::FunctionApp.BaselineControlsInvProcessor) -FunctionAppMaterKey $functionAppMaterKey
                
                WaitForFunctionToComplete -StartTimeAsString $StartTimeAsString -FunctionName $([ScannerConstants]::FunctionApp.BaselineControlsInvProcessor) -ApplicationInsightId $applicationInsight.Id -LAWorkspaceId $laWorkspaceId                

                Write-Host "Triggering Ondemand Scan" -ForegroundColor Yellow
                TriggerFunction -FunctionAppHostName $functionAppHostName -FunctionName $([ScannerConstants]::FunctionApp.WorkItemScheduler) -FunctionAppMaterKey $functionAppMaterKey

                WaitForFunctionToComplete -StartTimeAsString $StartTimeAsString -FunctionName $([ScannerConstants]::FunctionApp.WorkItemScheduler) -ApplicationInsightId $applicationInsight.Id  -LAWorkspaceId $laWorkspaceId

                

                Write-Host "$([Constants]::DoubleDashLine)" #-ForegroundColor $([Constants]::MessageType.Info)
                Write-Host "$([ScannerConstants]::NextStepsMsg)" -ForegroundColor Cyan
                Write-Host "$([Constants]::DoubleDashLine)"

            }
            else
            {
                 Write-Host "Error occurred while triggering on-demand scan. ErrorMessage [MetadataAggregator function app, Application Insight or Log Analytics workspace not found.]" -ForegroundColor $([Constants]::MessageType.Error)
            }
        }
        catch
        {
            Write-Host "Error occurred while triggering AzTS scan. ExceptionMessage [$($_)]"
        }
        finally
        {
            if($ForceFetch -and $maFunctionApp -ne $null)
            {
                Write-Host "[WARNING] Disabling forceFetch for [$($maFunctionApp.Name)] function app." -ForegroundColor Yellow
                $maFunctionAppSlot = Get-AzWebAppSlot -ResourceGroupName $ScanHostRGName -Name $maFunctionApp.Name -Slot 'production'
                $appSettings = $maFunctionAppSlot.SiteConfig.AppSettings
                #setup the current app settings
                $settings = @{}
                ForEach ($isetting in $appSettings) {
                    $settings[$isetting.Name] = $isetting.Value
                }

                $settings['WebJobConfigurations__ForceFetch'] = $false.ToString().Tolower()
                $updatedSlotDetails = Set-AzWebAppSlot -ResourceGroupName $ScanHostRGName -Name $maFunctionApp.Name -Slot 'production' -AppSettings $settings;
            }
        }
    }
}

function WaitForFunctionToComplete
{
    param (
        [ValidateNotNullOrEmpty()] 
        [string] $FunctionName,

        [ValidateNotNullOrEmpty()] 
        [string] $StartTimeAsString,

        [ValidateNotNullOrEmpty()] 
        [string] $ApplicationInsightId,

        [ValidateNotNullOrEmpty()] 
        [string] $LAWorkspaceId
    )

    $FunctionAppStatus = [EventStatus]::NotCompleted
    $LAStatus =  [EventStatus]::NotCompleted
    Write-Host "Waiting for [$($FunctionName)] function to complete its job." -ForegroundColor Yellow
    Write-Host "This operation can take up to 15 minutes (approx)." -NoNewline -ForegroundColor Yellow
    @(1..15) | ForEach-Object {
            $FunctionAppStatus = EventProcessor -StartTimeAsString $StartTimeAsString -FunctionName $FunctionName -ApplicationInsightId $ApplicationInsightId                
            $LAStatus = LogAnalyticsEventProcessor -StartTimeAsString $StartTimeAsString -FunctionName $FunctionName -WorkspaceId $LAWorkspaceId                
            if($FunctionAppStatus -ne [EventStatus]::Completed)
            {
                Write-Host ..$($_) -NoNewline -ForegroundColor Yellow;
                Start-Sleep -Seconds 60
            }
            elseif($LAStatus -ne [EventStatus]::Completed)
            {
               Write-Host ..$($_) -NoNewline -ForegroundColor Yellow;
               Start-Sleep -Seconds 60
            }
            else
            {
                # No Action
            }
     }

      Write-Host ""
    if($FunctionAppStatus -eq [EventStatus]::Completed -and $LAStatus -eq [EventStatus]::Completed)
    {
        Write-Host "[$($FunctionName)] completed proccessing." -ForegroundColor Cyan
    }
    else
    {
         Write-Host "Exceeded max wait time. [$($FunctionName)] is taking longer than expected to process. Continue to the next step." -ForegroundColor Cyan
    }
}

function GetFunctionAppKey
{

    param (
        [ValidateNotNullOrEmpty()] 
        [string] $AppServiceResourceId
    )

   try
   {
      $functionAppListKeyURL = "https://management.azure.com/" + $AppServiceResourceId + "/host/default/listkeys?api-version=2018-11-01"
      $headers = [TokenProvider]::new().GetAuthHeader("https://management.azure.com");

      $functionAppKeysResponse = Invoke-WebRequest -UseBasicParsing -Uri $functionAppListKeyURL -Method Post -Headers $headers -Body '{}'
      
      $functionAppKeys =  $functionAppKeysResponse.Content | ConvertFrom-Json
      return $functionAppKeys
   }
   catch
   {
        throw $_
   }
}


function TriggerFunction
{
    
    param (
        [ValidateNotNullOrEmpty()] 
        [string] $FunctionName,

        [ValidateNotNullOrEmpty()] 
        [string] $FunctionAppHostName,

        [ValidateNotNullOrEmpty()] 
        [string] $FunctionAppMaterKey
    )

    $maxRetryCount = 3
    $retryCount = 0

    try
    {
        while($retryCount -lt $maxRetryCount)
        {
            try
            {
                $baseFunctionAppTriggerURL = $FunctionAppHostName + "/admin/functions/{0}";
                $functionAppTriggerURL = ([string]::Format($baseFunctionAppTriggerURL, $FunctionName));
                
                Write-Host "Starting [$($FunctionName)] function." -ForegroundColor Cyan
                $response = Invoke-WebRequest -UseBasicParsing -Uri $functionAppTriggerURL -Method Post -Headers @{ "x-functions-key" = "$($FunctionAppMaterKey)";"Content-Type"="application/json" } -Body '{}'
                Write-Host "Successfully triggered [$($FunctionName)] function." -ForegroundColor Cyan 
                $retryCount = $maxRetryCount
            }
            catch
            {
                $retryCount += 1;
                if ($retryCount -ge $maxRetryCount)
                {
                    throw $($_);
                }
                else
                {
                    Start-Sleep -Seconds (30 * $retryCount)
                }
            }
        }# WhileEnd 
    }
    catch
    {
        Write-Host "Error occurred while triggering function app [$($FunctionName)] ExceptionMessage [$($_)]. Please validate that the function is in running state and run this command again." -ForegroundColor Red
    }
}

function EventProcessor
{
    param(
        [ValidateNotNullOrEmpty()] 
        [string] $StartTimeAsString,

        [ValidateNotNullOrEmpty()] 
        [string] $FunctionName,

        [ValidateNotNullOrEmpty()] 
        [string] $ApplicationInsightId
    )
    
     $Status = [EventStatus]::NotCompleted

     $aiQueryAPI = "https://management.azure.com/" + $ApplicationInsightId + "/query?api-version=2018-04-20&query=traces
                    | where customDimensions.LogLevel contains 'Information'
                    | where timestamp > todatetime('{0}') 
                    | where customDimensions.Category contains '{1}' and customDimensions.EventId == 2001
                    | project StatusId = customDimensions.EventId" -f $StartTimeAsString, $FunctionName

     $headers = [TokenProvider]::new().GetAuthHeader("https://management.azure.com");

     $response = Invoke-WebRequest -UseBasicParsing -Uri $aiQueryAPI -Method Get -Headers $headers 

     if($response -ne $null)
     {
        $customObject = $response.Content | ConvertFrom-Json

        if(($customObject | GM tables) -and ($customObject.tables -ne $null) -and ($customObject.tables[0] | GM rows) -and ($customObject.tables[0].rows -ne $null))
        {
            $Status = [EventStatus]::Completed
        }
     }

     return $Status;
}


function LogAnalyticsEventProcessor
{
    param(
        [ValidateNotNullOrEmpty()] 
        [string] $StartTimeAsString,

        [ValidateNotNullOrEmpty()] 
        [string] $FunctionName,

        [ValidateNotNullOrEmpty()] 
        [string] $WorkspaceId
    )
    
     $Status = [EventStatus]::NotCompleted

     try
     {
        $LAQuery = [string]::Empty

        switch($FunctionName)
        {
             $([ScannerConstants]::FunctionApp.BaselineControlsInvProcessor) { $LAQuery = $([ScannerConstants]::BaselineControlsInvLAQuery -f $StartTimeAsString) }
             $([ScannerConstants]::FunctionApp.WorkItemScheduler) { $LAQuery = $([ScannerConstants]::ControlResultsLAQuery -f $StartTimeAsString) }

        }
        
        if(![string]::IsNullOrWhiteSpace($LAQuery))
        {
            $Result  = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $LAQuery
            if(($Result.Results | Measure-Object).Count -gt 0)
            {
                $Status = [EventStatus]::Completed
            }
        }
     }
     catch
     {
        Write-Host "Error occurred while validating result in Log Analytics. ExceptionMessage [$($_.Exception.Message)]".
     }

     return $Status;
}

enum EventStatus
{
    NotCompleted
    Completed
}

class ScannerConstants
{
    static [string] $OnDemandScanInstructionMsg = "This command will perform 2 important operations. It will:`r`n`n" + 
					"   [1] Trigger baseline controls inventory processor `r`n" +
                    "   [2] Trigger work item scheduler `r`n"
					
    static [string] $OnDemandScanWarningMsg = "Please note that if the AzTS Soln has been setup recently, this command can take up to 30-45 minutes as it has to create tables in Log Analytics workspace for each inventory that is processed as part of this command.";
    static [string] $NextStepsMsg = "Baseline Controls inventory process and Scan has been completed. You can see the logs in the LA Workspace and UI.";

    static [string] $DoubleDashLine    = "================================================================================"
    static [string] $SingleDashLine    = "--------------------------------------------------------------------------------"

    static [string] $SubscriptionInvLAQuery = "let TablePlaceholder = view () {{print SubscriptionId = 'SubscriptionIdNotFound'}};
                                                      let SubInventory_CL = union isfuzzy=true TablePlaceholder, (union (
                                                      AzSK_SubInventory_CL | where TimeGenerated > todatetime('{0}')
                                                      | distinct SubscriptionId
                                                      ))
                                                      | where SubscriptionId !~ 'SubscriptionIdNotFound';
                                                      SubInventory_CL";
    static [string] $BaselineControlsInvLAQuery = "let TablePlaceholder = view () {{print ControlId_s = 'NA'}};
                                                          let BaselineControlsInv_CL = union isfuzzy=true TablePlaceholder, (union (
                                                          AzSK_BaselineControlsInv_CL | where TimeGenerated > todatetime('{0}')
                                                          | distinct ControlId_s
                                                          ))
                                                          | where ControlId_s !~ 'NA';
                                                          BaselineControlsInv_CL";
    static [string] $RBACInvLAQuery = "let TablePlaceholder = view () {{print NameId = 'NA', RoleId = 'NA'}};
                                              let RBAC_CL = union isfuzzy=true TablePlaceholder, (union (
                                              AzSK_RBAC_CL | where TimeGenerated > todatetime('{0}')
                                              | take 10
                                              | project RoleId = coalesce(RoleId_g, RoleId_s), NameId = NameId_g
                                              ))
                                              | where NameId !~ 'NA';
                                              RBAC_CL";
    static [string] $ControlResultsLAQuery = "let TablePlaceholder = view () {{print SubscriptionId = 'SubscriptionIdNotFound'}};
                                                     let ControlResults_CL = union isfuzzy=true TablePlaceholder, (union (
                                                     AzSK_ControlResults_CL | where TimeGenerated > todatetime('{0}')
                                                     | distinct SubscriptionId
                                                     ))
                                                     | where SubscriptionId !~ 'SubscriptionIdNotFound';
                                                     ControlResults_CL
                                                     | take 10";

    static [Hashtable] $FunctionApp = @{
            BaselineControlsInvProcessor = 'ATS_02_BaselineControlsInvProcessor'
            WorkItemScheduler = 'ATS_04_WorkItemScheduler'
    }

}

function DeployCustomControlConfiguration
{
    param ($ScanHostRGName, $StorageAccountName, $ContainerName, $JsonPath, $FeatureName, $SubscriptionId)
    Begin
    {
        Write-Host $([ScannerConstants]::DoubleDashLine)
        Write-Host "Uploading the custom control JSONs to the storage account... `n" -ForegroundColor Cyan

        $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ScanHostRGName -Name $StorageAccountName             
    }
    Process
    {

        $Context = $StorageAccount.Context
        $BlobObj = @{
            File             = $JsonPath
            Container        = $ContainerName
            Blob             = "Ext/" + $FeatureName + ".ext.json"
            Context          = $Context
            StandardBlobTier = 'Hot'
          }
          Set-AzStorageBlobContent @BlobObj -Verbose

          
        Write-Host "Uploaded the custom control JSONs to the storage account... `n" -ForegroundColor Cyan
        Write-Host $([ScannerConstants]::DoubleDashLine)

        TriggerBaselineControlInv -SubscriptionId $SubscriptionId -ScanHostRGName $ScanHostRGName -ForceFetch
    }
}
