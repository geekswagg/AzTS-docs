# Know more about controls

All our controls inherit from a base class called BaseControlEvaluator which will take care of all the required plumbing from the control evaluation code. Every control will have a corresponding feature json file under the configurations folder. For example, Storage.cs (in the control evaluator folder) has a corresponding Storage.json file under configurations folder. These controls json have a bunch of configuration parameters, that can be controlled by a policy owner, for instance, you can change the recommendation, modify the description of the control suiting your org, change the severity, etc.

Below is the typical schema for each control inside the feature json

```JSON
{
    "ControlID": "Azure_Subscription_AuthZ_Limit_ClassicAdmin_Count",   //User friendly control Id. The format used is Azure_<FeatureName>_<Category>_<ControlName>
    "Description": "Limit access per subscription to 2 or less classic administrators",  //Description for the control, which is rendered in all the reports it generates (CSV, AI telemetry, emails etc.).
    "Id": "SubscriptionCore160",   //This is internal ID and should be unique. Since the ControlID can be modified, this internal ID ensures that we have a unique link to all the control results evaluation.
    "ControlSeverity": "High", //Represents the severity of the Control. 
    "Automated": "Yes",   //Indicates whether the given control is Manual/Automated.
    "MethodName": "CheckCoAdminCount",  // Represents the Control method that is responsible to evaluate this control. It should be present inside the feature SVT associated with this control.
    "DisplayName": "Limit access per subscription to 2 or less classic administrators", // Represents user friendly name for the control.
    "Recommendation": "You need to remove any 'Classic Administrators/Co-Administrators' who should not be in the role. Please follow these steps: (a) Logon to https://portal.azure.com/ (b) Navigate to Subscriptions (c) Select the subscription (d) Go to 'Access Control (IAM)' and select the 'Classic Administrators' tab. (e) Select the co-administrator account that has to be removed and click on the 'Remove' button. (f) Perform this operation for all the co-administrators that need to be removed from the subscription.",	  //Recommendation typically provides the precise instructions on how to fix this control.
    "Tags": [
         "SDL",
         "TCP",
         "Automated",
         "AuthZ",
         "SubscriptionCore",
         "Baseline",
         "CSEOPilotSub"
    ], // You can decorate your control with different set of tags, that can be used as filters in scan commands.
    "Enabled": true ,  //Defines whether the control is enabled or not.
    "Rationale": "The v1 (ASM-based) version of Azure resource access model did not have much in terms of RBAC granularity. As a result, everyone who needed any access on a subscription or its resources had to be added to the Co-administrator role. These individuals are referred to as 'classic' administrators. In the v2 (ARM-based) model, this is not required at all and even the count of 2 classic admins currently permitted is for backward compatibility. (Some Azure services are still migrating onto the ARM-based model so creating/operating on them needs 'classic' admin privilege.)", //Provides the intent of this control.
    "ControlSettings": {
      "NoOfClassicAdminsLimit": 2
    } //  Settings specific to the control to be provided for the scan
}
```

> *Note*:  Listed below is the description with example of other metadata for the control.

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

<br>
After Schema of the control json, let us look at the corresponding feature 

<!-- TODO: Mention below what CR is in details and same for resource -->

``` CS
public class SubscriptionCoreEvaluator : BaseControlEvaluator
{
    
    public ControlResult CheckCoAdminCount(ControlResult cr)
    {

        // 1. This is where the code logic is placed
        // 2. ControlResult input to this function, which needs to be updated with the verification Result (Passed/Failed/Verify/Manual/Error) based on the control logic
        // 3. Messages that you add to ControlResult variable will be displayed in the detailed log automatically.
        
        // Note the syntax of how to fetch value from Control Settings from the JSON.
        int noOfClassicAdminsLimit = cr.ControlDetails.ControlSettings?["NoOfClassicAdminsLimit"]?.Value<int>() ?? 2;
        string classicAdminAccountsString = "No classic admin accounts found.";
        int classicAdminAccountsCount = 0;

        // NOTE: While fetching RBAC result, we make three API calls - PIM, ARM, Classic. We are *not* handling partial result scenario if error occurred while fetching any of these RBAC result.
        // If no RBAC is found, mark status as Verify because sufficient data is not available for evaluation.
        if (this.RBACList?.Any() == false)
        {
            cr.VerificationResult = VerificationResultStatus.Verify;
            cr.StatusReason = "No RBAC result found for this subscription.";
            cr.ConsiderForCompliance = false;
            return cr;
        }
        else
        {
            List<RBAC> classicAdminAccounts = new List<RBAC>();
            classicAdminAccounts = RBACList.AsParallel().Where(rbacItem => rbacItem.RoleName.ToLower().Contains("coadministrator") || rbacItem.RoleName.ToLower().Contains("serviceadministrator")).ToList();

            // First start with default value, override this if classic admin account is found.
            if (classicAdminAccounts != null && classicAdminAccounts.Any())
            {
                classicAdminAccountsCount = classicAdminAccounts.Count;
                classicAdminAccountsString = string.Join(",", classicAdminAccounts.Select(a => a.ToStringClassicAssignment()).ToList());
            }

            // Start with failed state, mark control as Passed if all required conditions are met
            cr.StatusReason = $"No. of classic administrators found: [{classicAdminAccountsCount}]. Principal name results based on RBAC inv: [{String.Join(", ", classicAdminAccounts.Select(a => a.PrincipalName))}]";
            cr.VerificationResult = VerificationResultStatus.Failed;

            // Classic admin accounts count does not exceed the limit.
            if (classicAdminAccountsCount <= noOfClassicAdminsLimit)
            {
                cr.VerificationResult = VerificationResultStatus.Passed;
            }
        }

        return cr;
    }
    .
    .
    .
}
```

<!-- Add a block diagram here to show how the overlay happens -->
