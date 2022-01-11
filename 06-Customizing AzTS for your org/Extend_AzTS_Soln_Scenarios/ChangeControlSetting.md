# Changing control setting for existing controls 

Using Org policy customization, we can change some control setting for an existing control. Below is a walk-through example of how to do so leveraging the AzTS-Extended solution that you build using the steps mentioned [here](./SettingUpSolution.md).
<br/><br/>A typical setting you may want to tweak is the maximum number of classic admins allowed for your org's subscriptions. 
It is verified in one of the subscription security controls. (The default value is 2.) Let us change this default value to 5.
This setting for any feature resides in a file called FeatureName.json (in this case - SubscriptionCore.json).  
<br/>Because the first time org policy setup does not customize anything from this, we will need to follow the following steps to modify the control settings:

### Steps:
0.  Initially, set up the organization-specific policy customizable AzTS Solution in your local systems by following the steps mentioned [here](./SettingUpSolution.md).
1.  Copy _FeatureNameExt.json_ file and rename it accordingly. For example: SubscriptionCoreExt.json
2.  Fill the parameters according to the feature. For example: 
    ``` JSON
    {
        "FeatureName": "SubscriptionCore"
    }
    ```
3.  Add the control json with all parameters given in template. The following metadata are required for a control to be scanned:
    ``` JSON
    "Controls": [
        {
        // The following parameters can be taken from the FeatureName.json directly as there will no change in them for the scope of this scenario. 
        "ControlID": "Azure_Subscription_AuthZ_Limit_ClassicAdmin_Count",
        "Id": "SubscriptionCore160",
        "Automated": "Yes",
        "MethodName": "CheckCoAdminCount",
        "Enabled": true,

        // As required we need to modify the Display Name according to the control setting changes for this case:
        "DisplayName": "Limit access per subscription to 5 or less classic administrators",

        // For this scenario, modify the control settings as such:
        "ControlSettings": {
            "NoOfClassicAdminsLimit": 5 // Changing the Classic Admin limit to 5 from 2.
            }
        }
    ]
    ```

    1. For **Id** above: 
        * Since we are modifying control settings for an existing control here, use the same ID as used previously from the FeatureName.json . 
    2. Keep **Enabled** switch to 'true' to scan a control.
    3. **DisplayName** is the user friendly name for the control. It does not necessarily needed to be modified here.
    4. For **MethodName** above: Use the same method name for this scenario as no change in the control logic is required.

The final JSON file should look like this for our walk-through example:
![Example](../../Images/06_OrgPolicy_BScenario2.png)

4. Build and Run
   - Click on the AzTS_Extended as shown below to run the project: <br />
      ![Build Step 1](../../Images/06_OrgPolicy_Setup_BuildStep.png)<br/>
<!-- TODO Add the SubscriptionCore file EXT added log -->
   - Output looks like below:<br/>
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep1.png)<br />
      ![Run Output](../../Images/06_OrgPolicy_Setup_RunStep2.png)
   
   <br><b>Congratulations! Changing Control Setting Scenario is complete with this step.</b>

<b>Next Steps:</b>

1. Verify the changes in your local system:
    You can verify your changes in the Log Analytics Workspace with the help of this query.
    ``` kusto
    AzSK_ControlResults_CL
    | where TimeGenerated > ago(30m)
    ```
    Few simple queries are provided in this [link](https://github.com/azsk/AzTS-docs/tree/main/01-Setup%20and%20getting%20started#4-log-analytics-visualization) related to the inventory and Control Scan summary for reference.

2. Deploy the changes:
You can deploy the project with your changes in your current AzTS solution now. Please follow the steps mentioned [here](./DeployInAzTS.md).