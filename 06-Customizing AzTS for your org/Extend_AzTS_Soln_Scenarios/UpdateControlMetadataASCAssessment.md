# Updating Control Metadata for controls based on ASC Assessment

Using Org policy customization, we can change some ASC assessment setting for an existing control. Below is a walk-through example of how to do so leveraging the AzTS-Extended solution that you built using the steps mentioned [here](./SettingUpSolution.md).
<br/>
<br/>A typical setting you may want to modify is the name of the ASC assessment that is being scanned for a control according to your org's needs. 
<br/>Let us change the ASC assessment value from "2acd365d-e8b5-4094-bce4-244b7c51d67c" to "00c6d40b-e990-6acf-d4f3-471e747a27c4" for the "Azure_Subscription_AuthZ_Remove_Management_Certs" existing control. 
This setting for any feature resides in a file called FeatureName.json (in this case - SubscriptionCore.json).  
<br/>Because the first time org policy setup does not customize anything from this, we will need to follow the following steps to modify the ASC assessments settings:

### Steps:
0.  Initially, set up the organization-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1. Copy _FeatureName_Template.json_ file from the ControlConfigurationExt folder and paste it in the same folder. Append "Ext" to the file name and save it.
<br>    *For this scenario:* 
<br>    Copy the template file and paste it in the same ControlConfigurationExt folder. Rename and save it as StorageExt.json. 

2. Copy the control metadata from the control array you wish to customize from the Base Control JSON file located in the ConfigurationProvider/ControlConfigurations/Services folder and paste it in the FeatureNameExt.json file (here StorageExt.json). 
<!-- 2.  Keep only the controls in the control array which you wish to customize. Remove the remaining control instances from the feature file. -->
3.  For this scenario, make changes to the properties of the control so that the final JSON looks like the below:
    ``` JSON
    "Controls": [
        {
        // The following parameters can be taken from the FeatureName.json i.e. SubscriptionCore.json directly as there will no change in them for the scope of this scenario. 
        "ControlID": "Azure_Subscription_AuthZ_Remove_Management_Certs",
        "Id": "SubscriptionCore170",
        "Automated": "Yes",
        "DisplayName": "Do not use management certificates",
        "MethodName": "", // This will be empty since the Control is ASC assessment based
        "Enabled": true,

        // For this scenario, modify the ASC Assessment name under Assessment properties as such:
        "AssessmentProperties": {
                "AssessmentNames": [
                    "00c6d40b-e990-6acf-d4f3-471e747a27c4"
                ]
        }
        }
    ]
    ```

    1. Keep **Enabled** switch to 'true' to scan a control.
    2. For **MethodName** above: If the `ControlScanSource` is `ASC` based then, "MethodName" should be empty. If `ControlScanSource` is `ASCorReader` based then, use the same method name for this scenario as no change in the control logic is required for the scope of this scenario.
    3. **AssessmentProperties**: Default enterprise policy settings for Azure Security Center like configuring assessment name in ASC etc. 

4. Build and Run
   - Click on the AzTS_Extended as shown below to run the project: <br />
      ![Build Step 1](../../Images/06_OrgPolicy_Setup_BuildStep.png)<br/>
<!-- TODO Add the SubscriptionCore file EXT added log -->
   - Output looks like below:<br/>
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep1.png)<br />
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep2.png)

<b>Next Steps:</b>

1. Verify the changes in your local system:
    You can verify your changes in the Log Analytics Workspace with the help of this query.
    ``` kusto
    AzSK_ControlResults_CL
    | where TimeGenerated > ago(30m)
    | where ControlName_s == "Azure_Subscription_AuthZ_Remove_Management_Certs"
    ```
    Few simple queries are provided in this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization) related to the inventory and Control Scan summary for reference.


2. Deploy the changes:
You can deploy the project with your changes in your current AzTS solution now. Please follow the steps mentioned [here](./DeployInAzTS.md).

<br><b>Congratulations! Modifying control metadata for controls based on ASC Assessment Scenario is complete with this step.</b>