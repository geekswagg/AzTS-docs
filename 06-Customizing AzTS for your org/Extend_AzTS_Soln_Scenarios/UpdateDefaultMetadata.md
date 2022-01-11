# Update metadata (display name, recommendation, etc.) for existing controls

Using Org policy customization, we can change some basic metadata for existing controls. A typical setting you may want to modify is the Display Name, Control Severity, Recommendation, etc of an existing control according to your org's needs. 


> Note: To edit policy JSON files, use a friendly JSON editor such as Visual Studio Code. It will save you lot of debugging time by telling you when objects are not well-formed (extra commas, missing curly-braces, etc.)! This is key because in a lot of policy customization tasks, you will be taking existing JSON objects and removing large parts of them (to only keep the things you want to modify).

Consider that you want to turn off the evaluation of some control altogether (regardless of whether people filter using the Baseline tags or not). Also, for another control, you want people to use a recommendation which leverages an internal tool the security team in your org has developed. Let us do this for the Storage.json file. Specifically, we will:

1. Turn off the evaluation of Azure_Storage_Audit_Issue_Alert_AuthN_Req altogether.
2. Modify severity of Azure_Storage_AuthN_Dont_Allow_Anonymous to Critical for our org (it is High by default).
3. Change the recommendation for people in our org to follow if they need to address an issue with the Azure_Storage_DP_Encrypt_In_Transit control.

Below is a walk-through example of how to do so leveraging the AzTS-Extended solution that you build using the steps mentioned [here](./SettingUpSolution.md).

Because the first-time org policy setup does not customize anything from this, we will need to follow the following steps to modify the Control Evaluator:

### Steps:
0.  Initially, set up the organization-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1.  Copy _FeatureNameExt.json_ file and rename it accordingly. For example: StorageExt.json
2.  Fill the parameters according to the feature. For example: 
    ``` JSON
    {
        "FeatureName": "Storage"
    }
    ```
3.  Add the control json with all parameters given in template. The following meta-data are required for a control to be scanned:
    ``` JSON
    "Controls": [
        {
        // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario. 
        "ControlID": "Azure_Storage_NetSec_Restrict_Network_Access",
        "Id": "AzureStorage260",
        "Automated": "Yes",
        "MethodName": "CheckStorageNetworkAccess",
        "Enabled": true,
        "DisplayName": "Ensure that Firewall and Virtual Network access is granted to a minimal set of trusted origins"
        }
    ]
    ```

    1. For **Id** above: 
        * Since we are modifying control settings for an existing control here, use the same ID as used previously from the FeatureName.json . 
    2. For **ControlID** above: Initial part of the control ID is pre-populated based on the service/feature and security domain you choose for the control (Azure_FeatureName_SecurityDomain_XXX). Please don't use spaces between words instead use underscore '_' to separate words in control ID. To see some of the examples of existing control IDs please check out this [list](https://github.com/azsk/AzTS-docs/tree/main/Control%20coverage#azure-services-supported-by-azts).
    3. Keep **Enabled** switch to 'Yes' to scan a control.
    4. **DisplayName** is the user friendly name for the control. It does not necessarily needed to be modified.
    5. For **MethodName** above: You can customize the MethodName here. Just make sure to use the same method name in the Control Evaluator in the next steps.

For this example, make changes to the properties of the respective controls so that the final JSON looks like the below:
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
   
   <br><b>Congratulations! Customizing the Specific controls of an existing service scenario is complete with this step.</b>

<b>Next Steps:</b>

1. Verify the changes in your local system:
 You can verify your changes in the Log Analytics Workspace with the help of this query.
    ``` kusto
    AzSK_ControlResults_CL
    | where TimeGenerated > ago(30m)
    | where ControlName_s == "Azure_Storage_AuthN_Dont_Allow_Anonymous"
    ```
    Few simple queries are provided in this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization) related to the inventory and Control Scan summary for reference.

2. Deploy the changes:
You can deploy the project with your changes in your current AzTS solution now. Please follow the steps mentioned [here](./DeployInAzTS.md).



## Steps:
0.  Initially, set up the organization-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1.  Copy _FeatureNameExt.json_ file and rename it accordingly. For example: SubscriptionCoreExt.json
2.  Fill the parameters according to the feature. For example: 
    ``` JSON
    {
        "FeatureName": "SubscriptionCore"
    }
    ```
3.  Add the control json with all parameters given in template. You can see the existing control metadata of the feature control you want to update from [here](https://github.com/azsk/AzTS-docs/tree/main/Control%20coverage#azure-services-supported-by-azts).<br>
The following meta-data are required for a control to be scanned:
    ``` JSON
    "Controls": [
        {
        // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario.
        
         // Note that below we update the Control ID value to the one required according to the org's policy.
        "ControlID": "Azure_Subscription_AuthZ_Limit_ClassicAdmin_Count_Extended",
        "Id": "SubscriptionCore160", // This is the unique primary key so unless we are not adding a new control, this should remain same when modifying any control.
        "Automated": "Yes",
        "DisplayName": "Limit access per subscription to 2 or less classic administrators",
        "MethodName": "CheckCoAdminCount", //  Represents the Control method that is responsible to evaluate this control. It should be present inside the feature JSON associated with this control.
        "Enabled": true,
        "ControlSettings": {
        "NoOfClassicAdminsLimit": 2
      } // Settings specific to the control to be provided for the scan
        }
    ]
    ```

    1. For `Id` above: 
        * Since we are modifying control settings for an existing control here, use the same ID as used previously from the FeatureName.json . 
    2. For `ControlID` above: Initial part of the control ID is pre-populated based on the service/feature and security domain you choose for the control (Azure_FeatureName_SecurityDomain_XXX). Please don't use spaces between words instead use underscore '_' to separate words in control ID. To see some of the examples of existing control IDs please check out this [list](https://github.com/azsk/AzTS-docs/tree/main/Control%20coverage#azure-services-supported-by-azts).
    3. Keep `Enabled` switch to 'Yes' to scan a control.
    4. `DisplayName` is the user friendly name for the control.
    5. For `MethodName` above: Use the same method name for this scenario as no change in the control logic is required.

    > *Note*:  You can provide additional details/optional settings for the control as listed below.

    |Settings| Description| Examples|
    |-------------|------|---------|
    |Automated| Whether the control is manual or automated| e.g. Yes/No (keep it Yes for policy based controls)|
    |Description| A basic description on what the control is about| e.g. App Service must only be accessible over HTTPS. |
    | Category| Generic security specification of the control.| e.g. Encrypt data in transit |
    |Tags| Labels that denote the control being of a specific type or belonging to a specific domain | For e.g. Baseline, Automated etc.|
    |Control Severity| The severity of the control| e.g. High: Should be remediated as soon as possible. Medium: Should be considered for remediation. Low: Remediation should be prioritized after high and medium.|
    |Control Requirements| Prerequisites for the control.| e.g. Monitoring and auditing must be enabled and correctly configured according to prescribed organizational guidance|
    |Rationale|  Logical intention for the added control | e.g. Auditing enables log collection of important system events pertinent to security. Regular monitoring of audit logs can help to detect any suspicious and malicious activity early and respond in a timely manner.|
    |Recommendations| Steps or guidance on how to remediate non-compliant resources | e.g. Refer https://azure.microsoft.com/en-in/documentation/articles/key-vault-get-started/ for configuring Key Vault and storing secrets |
    |Custom Tags| Tags can be used for filtering and referring controls in the future while reporting| e.g. Production, Phase2 etc. |
    |Control Settings| Settings specific to the control to be provided for the scan | e.g. Required TLS version for all App services in your tenant (Note: For policy based contols this should be empty) |
    |Comments | These comments show up in the changelog for the feature. | e.g. Added new policy based control for App Service |

4. Build and Run
   - Click on the AzTS_Extended as shown below to run the project: <br />
      ![Build Step 1](../../Images/06_OrgPolicy_Setup_BuildStep.png)<br/>
   - Output looks like below:<br/>
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep1.png)<br />
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep2.png)
   
   <br><b>Congratulations! Updating default metadata scenario is complete with this step.</b>

**Next Steps:**

1. Verify the changes in your local system:
 You can verify your changes in the Log Analytics Workspace with the help of this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization).
 <br/> Few simple queries are provided in the above link related to the inventory and Control Scan summary for reference.

2. Deploy the changes:
You can deploy the project with your changes in your current AzTS solution now. Please follow the steps mentioned [here](./DeployInAzTS.md).