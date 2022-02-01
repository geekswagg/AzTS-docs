# Update metadata (display name, recommendation, etc.) for existing controls

Using Org policy customization, we can change some basic metadata for existing controls. A typical setting you may want to modify is the Display Name, Control Severity, Recommendation, etc of an existing control according to your org's needs. 


> Note: To edit policy JSON files, use a friendly JSON editor such as Visual Studio Code. It will save you lot of debugging time by telling you when objects are not well-formed (extra commas, missing curly-braces, etc.)! This is key because in a lot of policy customization tasks, you will be taking existing JSON objects and removing large parts of them (to only keep the things you want to modify).

Consider that you want to turn off the evaluation of some control altogether (regardless of whether people filter using the Baseline tags or not). Also, for another control, you want people to use a recommendation which leverages an internal tool the security team in your org has developed. Let us do this for the Storage.json file. Specifically, we will:

1. Turn off the evaluation of Azure_Storage_Audit_Issue_Alert_AuthN_Req altogether.
2. Modify severity of Azure_Storage_AuthN_Dont_Allow_Anonymous to Critical for our org (it is High by default).
3. Change the recommendation for people in our org to follow if they need to address an issue with the Azure_Storage_DP_Encrypt_In_Transit control.

Below is a walk-through example of how to do so leveraging the AzTS-Extended solution that you built using the steps mentioned [here](./SettingUpSolution.md).

Because the first time org policy setup does not customize anything from this, we will need to follow the following steps to modify the Control Evaluator:

### Steps:
0.  Initially, set up the organization-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1. Copy _FeatureName_Template.json_ file from the ControlConfigurationExt folder and paste it in the same folder. Append "Ext" to the file name and save it.
<br>    *For this scenario:* 
<br>    Copy the template file and paste it in the same ControlConfigurationExt folder. Rename and save it as StorageExt.json. 

2. Copy the control metadata from the control array you wish to customize from the Base Control JSON file located in the ConfigurationProvider/ControlConfigurations/Services folder and paste it in the FeatureNameExt.json file (here StorageExt.json). 
<!-- 2.  Keep only the controls in the control array which you wish to customize. Remove the remaining control instances from the feature file. -->
3.  For this scenario, make changes to the properties of the respective controls so that the final JSON looks like the below:
``` JSON
{
    "Controls": [
        {
            // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario. 
            "ControlID": "Azure_Storage_AuthN_Dont_Allow_Anonymous",
            "Id": "AzureStorage110",
            "Automated": "Yes",
            "MethodName": "CheckStorageContainerPublicAccessTurnOff",
            "Enabled": true,
            "DisplayName": "Ensure secure access to storage account containers.",

            // Modifying severity to Critical for your org (it is High by default)
            "ControlSeverity": "Critical"
        },
        {
            // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario. 
            "ControlID": "Azure_Storage_Audit_Issue_Alert_AuthN_Req",
            "Id": "AzureStorage120",
            "Automated": "Yes",
            "MethodName": "CheckStorageMetricAlert",
            "DisplayName": "Alert rules must be configured for tracking anonymous activity",

            // Turning off the evaluation of Azure_Storage_Audit_Issue_Alert_AuthN_Req altogether
            "Enabled": false
        },
        {
            // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario. 
            "ControlID": "Azure_Storage_DP_Encrypt_In_Transit",
            "Id": "AzureStorage160",
            "Automated": "Yes",
            "MethodName": "CheckStorageEncryptionInTransit",
            "Enabled": true,
            "DisplayName": "Enable Secure transfer to storage accounts",

            // Change the recommendation for people in your org to follow which leverages an internal tool the security team in your org has developed
            "Recommendation": "**Note**: Use our Contoso-IT-EncryptInTransit.ps1 tool for this!"
        }
    ]
}
```

4. Build and Run
   - Click on the AzTS_Extended as shown below to run the project: <br />
      ![Build Step 1](../../Images/06_OrgPolicy_Setup_BuildStep.png)<br/>
   - Output looks like below:<br/>
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep1.png)<br />
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep2.png)
   

<b>Next Steps:</b>

1. Verify the changes in your local system:
 You can verify your changes in the Log Analytics Workspace with the help of this query.
    ``` kusto
    AzSK_ControlResults_CL
    | where TimeGenerated > ago(30m)
    | where ControlName_s == "Azure_Storage_AuthN_Dont_Allow_Anonymous" or ControlName_s == "Azure_Storage_DP_Encrypt_In_Transit" or ControlName_s == "Azure_Storage_Audit_Issue_Alert_AuthN_Req" 
    ```
    Few simple queries are provided in this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization) related to the inventory and Control Scan summary for reference.

2. Deploy the changes:
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
        -JsonPath "path\to\JSON\files\StorageExt.json" 
        -FeatureName "storage" 
        -SubscriptionId "<SubId>"
    ```
- Finally, you can validate your changes in the Log Analytics Workspace using the above query and validate the changes in the UI as well.
    

<br><b>Congratulations! Updating metadata scenario is complete with this step.</b>
