> The Azure Tenant Security Solution (AzTS) was created by the Core Services Engineering & Operations (CSEO) division at Microsoft, to help accelerate Microsoft IT's adoption of Azure. We have shared AzTS and its documentation with the community to provide guidance for rapidly scanning, deploying and operationalizing cloud resources, across the different stages of DevOps, while maintaining controls on security and governance.
<br>AzTS is not an official Microsoft product – rather an attempt to share Microsoft CSEO's best practices with the community.


### [Overview](Readme.md#Overview-1)
 - [When and why should I set up org policy?](Readme.md#when-and-why-should-i-setup-org-policy)

### [Setting up org policy](Readme.md#setting-up-org-policy-1)
 - [Prerequisites to customize AzTS for you org](Readme.md#what-happens-during-org-policy-setup)
 
### [Modifying and customizing org policy](Readme.md#modifying-and-customizing-org-policy-1)
 - [Getting Started](Readme.md#getting-started)
 - [Basic scenarios for org policy customization](Readme.md#basic-scenarios-for-org-policy-customization) 
      - [Changing control setting](Readme.md#b-changing-a-control-setting-for-specific-controls)
      - [Customizing specific controls for a service SVT](Readme.md#c-customizing-specific-controls-for-a-service)
      - [Setting up and updating baselines for your org](Readme.md#d-creating-a-custom-control-baseline-for-your-org)

### [Advanced scenarios for org policy customization/extending AzTS](Readme.md#advanced-usage-of-org-policy-extending-azsk) 

- [SVT customization](./Extending%20AzTS/Readme.md)
   - [Add new control for existing SVT](./Extending%20AzTS/Readme.md)
      - [Add new control based on custom Azure policy](./Extending%20AzTS/AddControlForPolicy.md)
      - [Add new control based on ASC Assessment](./Extending%20AzTS/AddControlForAssessment.md)
   - [Update/extend existing control](./Extending%20AzTS/Note.md)
      - [Update/extend existing control by custom Azure policy](./Extending%20AzTS/Note.md)
      - [Update/extend existing control by custom ASC Assessment](./Extending%20AzTS/Note.md)
   - [Add new SVT altogether (non-existing SVT)](./Extending%20AzTS/Note.md)

----------------------------------------------------------------

## Overview

### When and why should I setup org policy

When you setup and install AzTS, it relies on JSON-based policy files and certain app configurations to determine various parameters that effect the behavior of the scan performed by AzTS and other components. When you run the public version of the AzTS without any customization, the policy files are directly accessed from local pacakge deployed in your subscription. This setup you can consider as vanilla installation but AzTS provides capability to modify setup as per requirements in your organization. 

The JSON inside the policy files dictate the behavior of the security scan. 
This includes things such as:
 - Which set of controls to evaluate?
 - What control set to use as a baseline?
 - What settings/values to use for individual controls? 
 - What messages to display for recommendations? Etc.

While the deafult setup of AzTS may be good for limited use, in many contexts you may want to "customize" the behavior of the security scans for your environment. You may want to do things such as: (a) enable/disable some controls, (b) change control settings to better match specific security policies within your org, (c) change various messages, (d) add additional filter criteria for certain regulatory requirements that teams in your org can leverage, etc. When faced with such a need, you need a way to create and manage a dedicated customized policies to meet the needs of your environment. The organization policy customization feature 
helps you do that in an automated fashion. 

In this document, we will look at how to customize AzTS setup, how to make changes and manage the policy files and how to accomplish various common org-specific policy/behavior customizations for the AzTS.

## Setting up org policy

### Prerequisites to customize AzTS for you org

There are few prerequisites which need to be comepleted to set up AzTS customization feature for your org. Please follow the steps mentioned [here](Link to prerequisites).

## Modifying and customizing AzTS setup

### Getting Started

The typical workflow for all policy changes and customizatio will remain same and will involve the following basic steps:

1- Go to **AzTS UI**. (To get AzTS UI URL, check this [FAQ](https://github.com/azsk/AzTS-docs/blob/main/03-Running%20AzTS%20solution%20from%20UI/README.md#frequently-asked-questions))

2- Open **Control editor tool**.

![Open CMET Editor](../Images/06_ExtendingAzTS_Open_CMET.png)

3- Select one control.

4- Edit one or more control property.

5- **Save** and **Queue** the changes.

6- Go to scan tool of **AzTS UI**.

7- Trigger Adhoc scan.

8- Verify the changes done in step #4 are getting reflected in latest scan.

### Basic scenarios for org policy customization

In this section let us look at typical scenarios in which you would want to customize the org policy and ways to accomplish them.

#### a) Changing a control setting for specific controls 

TODO: Add Steps here.

#### b) Customizing specific controls for a service 
In this example, we will make a slightly more involved change in the context of a specific SVT (Storage). 

Imagine that you want to turn off the evaluation of some control altogether across your org.
Also, for another control, you want people to use a recommendation which leverages an internal tool the security team in your org has developed. Let us do this for the Storage feature. Specifically, we will:
1. Turn off the evaluation of `Azure_Storage_Audit_Issue_Alert_AuthN_Req` altogether.
2. Modify severity of `Azure_Storage_AuthN_Dont_Allow_Anonymous` to `Critical` for our org (it is `High` by default).
3. Change the recommendation for people in our org to follow if they need to address an issue with the `Azure_Storage_DP_Encrypt_In_Transit` control.
4. Change the display name of `Azure_Storage_DP_Encrypt_In_Transit` control.

TODO: Add Steps here.

#### c) Creating a custom control 'baseline' for your org

TODO: Add Steps here. 
HINT: Tag changes.
