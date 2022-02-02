# Updating Control Metadata for controls based on MDC Assessment

Using Org policy customization, we can change some MDC (Microsoft Defender for Cloud) assessment setting for an existing control. Below is a walk-through example of how to do so leveraging the AzTS-Extended solution that you built using the steps mentioned [here](./SettingUpSolution.md).
<br/>
<br/>A typical setting you may want to modify is the name of the MDC assessment that is being scanned for a control according to your org's needs. 
<br/>For this scenario, let us change the MDC assessment value for the "Azure_Storage_NetSec_Restrict_Network_Access" existing control from ["2a1a9cdf-e04d-429a-8416-3bfb72a1b26f"](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F2a1a9cdf-e04d-429a-8416-3bfb72a1b26f)  to ["ad4f3ff1-30eb-5042-16ed-27198f640b8d"](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F34c877ad-507e-4c82-993e-3452a6e0ad3c). 
<br>This setting for any feature resides in a file called FeatureName.json (in this case - Storage.json) inside folder ConfigurationProvider/ControlConfigurations. 

<br/>Because the first time org policy setup does not customize anything from this, we will need to follow the following steps to modify the MDC assessments settings:

### Steps:
0.  Initially, set up the org-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1. Copy _FeatureName_Template.json_ file from the ControlConfigurationExt folder and paste it in the same folder. Rename it by appending "Ext" to the file name and save it.
<br>    *For this scenario:* 
<br>    Copy the template (_FeatureName_Template.json_) file and paste it in the same ControlConfigurationExt folder. Rename and save it as StorageExt.json for this scenario. 

    > Precautionary Note: Make sure the file name i.e. FeatureNameExt.json is in Pascal case. 

2. Copy the control metadata from the control array you wish to customize from the Built-in control JSON file (in this case - Storage.json) located in the ConfigurationProvider/ControlConfigurations folder and paste it in the FeatureNameExt.json file (in this case - StorageExt.json). 

3. Fill the FeatureName parameter according to the feature. For example:
    ``` JSON
    {
        "FeatureName": "Storage"
    }
    ```
<!-- 2.  Keep only the controls in the control array which you wish to customize. Remove the remaining control instances from the feature file. -->
4.  For this scenario, make changes to the properties of the control so that the final JSON looks like the below:
    ``` JSON
    "Controls": [
        {
        // The following parameters can be taken from the FeatureName.json i.e. Storage.json directly as there will no change in them for the scope of this scenario. 
        "ControlID": "Azure_Storage_NetSec_Restrict_Network_Access",
        "Id": "AzureStorage260",
        "Automated": "Yes",
        "DisplayName": "Ensure that Firewall and Virtual Network access is granted to a minimal set of trusted origins",
        "MethodName": "CheckStorageNetworkAccess", // This control is ASCorReader based so the method name remains same for the reader logic. This could be empty if the Control is MDC assessment based only. Irrespectively, do not modify the MethodName for the scope of this scenario.
        "Enabled": true,

        // For this scenario, modify the MDC Assessment name under Assessment properties as such:
        "AssessmentProperties": {
                "AssessmentNames": [
                    "ad4f3ff1-30eb-5042-16ed-27198f640b8d"
                ]
            }
        }
    ]
    ```

    1. Keep **Enabled** switch to 'true' to scan a control.
    2. For **MethodName** above: Irrespective of the `ControlScanSource`, do not modify the MethodName for the scope of this scenario. If the `ControlScanSource` is `ASC` based then, "MethodName" should be empty. If `ControlScanSource` is `ASCorReader` based then, use the same method name for this scenario as no change in the control reader logic is required for the scope of this scenario. 
    3. **AssessmentProperties**: Default enterprise policy settings for Azure Security Center like configuring assessment name in MDC etc. 

5. Build and Run
   - Click on the AzTS_Extended as shown below to run the project: <br />
      ![Build Step 1](../../Images/06_OrgPolicy_Setup_BuildStep.png)<br/>
<!-- TODO Add the SubscriptionCore file EXT added log -->
   - Output looks like below:<br/>
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep1.png)<br />
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep2.png)

<b>Next Steps:</b>

1. Deploy the changes:
You can deploy the JSON files with your changes in your current AzTS solution now using the helper script. 
Please follow the steps mentioned below.

- Download the script from [here](./Scripts/DeployCustomControlConfiguration.ps1)
  > **Note:** Script can be downloaded by clicking Alt+Raw button.
- Open a PowerShell session.
- Navigate to the download location of the script in PowerShell session.
    ```Powershell
   cd "Script downloads location"
    ```
- Unblock the downloaded script.
    ```Powershell
   Unblock-File -Path ".\DeployCustomControlConfiguration.ps1"
    ```
- Load the script in current PowerShell session.
    ```Powershell
    . ".\DeployCustomControlConfiguration.ps1"
    ```
    > **Note:** Do not miss the '.' at beginning of the above command.
- Connect to AzAccount
    ```Powershell
     Connect-AzAccount -Tenant $TenantId
    ```
    > **Note:** Tenant Id *must* be specified when connecting to AzAccount
- Invoke the configuration cmdlet
    ```Powershell
    DeployCustomControlConfiguration 
        -ScanHostRGName "AzTSHostingRGName" 
        -StorageAccountName "<StorageAccountName>" 
        -ContainerName "orgpolicy" 
        -JsonPath "path\to\JSON\files\SubscriptionCoreExt.json" 
        -FeatureName "subscriptioncore" 
        -SubscriptionId "<SubId>"
    ```
- Finally, you can validate your changes in the Log Analytics Workspace using the above query and validate the changes in the UI as well.
    
2. Verify the changes in your local system:
    You can verify your changes in the Log Analytics Workspace with the help of this query.
    ``` kusto
    AzSK_ControlResults_CL
    | where TimeGenerated > ago(30m)
    | where ControlName_s == "Azure_Storage_NetSec_Restrict_Network_Access"
    ```
    Few simple queries are provided in this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization) related to the inventory and Control Scan summary for reference.

    
<br><b>Congratulations! Modifying control metadata for controls based on MDC Assessment Scenario is complete with this step.</b>