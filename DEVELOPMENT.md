# Development

This document describes recommended practices for developing and testing against this pattern.

## Testing Environments

While you may bring your own (BYO) OpenShift cluster, Red Hat associates and partners may utilize [Red Hat Demo Platform (RHDP)](https://catalog.demo.redhat.com) to provision OpenShift environments for use as targets for pattern development and testing.

### Provisioning

The following Catalog Item (CI) has been verified and is recommended when provisioning OpenShift clusters as it meets the prerequisites set form within the pattern:

* [Red Hat OpenShift Container Platform Cluster (AWS)](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.ocp-wksp.prod&utm_source=webapp&utm_medium=share-link)

The following options should be selected:

* Activity: Practice / Enablement
* Purpose: Trying out a technical solution
* Salesforce ID: Can be omitted (See note below)
* OpenShift Version: 4.19+
* Features
  * Enable Cert Manager
  * Enable Cert Manager API
* Control Plane Count: 3

Once a cluster has been provisioned, there are additional sets which need to be performed in order to avoid overlapping capabilities that are implemented within this pattern:

### Cert-Manager Removal

While cert-manager is a key feature offered within this pattern, RHDP deploys an instance to support the generation of API and Ingress certificates. Utilize the following steps to remove the conflicting resources.

1. Login to the Web Console of the provisioned OpenShift cluster with the provided authentication details.
2. Under _Operators_ on the left hand navigation ad select **Installed Operators**
3. Locate _cert-manager Operator for Red Hat OpenShift_ and click the kabob (3 vertical dots) from the right hand column and select **Uninstall Operator**
4. The `OperatorGroup` associated with Cert Manager must also be uninstalled. Under _Home_ on the left hand navigation, select **API Explorer**
5. From the project dropdown at the top of the screen, select `cert-manager-operator` as the _Project_
6. In the search textbox, enter `OperatorGroup` and select the link underneath the _Name_ column associated with API Version `v1` in the _Version_ column.
7. Click on the **Instances** tab
8. Locate any instances and click the kabob (3 vertical dots) from the right hand column and select **Delete OperatorGroup**

## Analytics Tracking

Metrics are captured to track the use of any of the Validated Patterns. It is important than an accurate depiction of pattern use by customers, partners and those from the community are captured. Red Hat associates should not factor into this calculation and support is available in the Validated Patterns framework to opt out of being captured.

To implement the opt-out capability, create a file in the location `~/.config/validated-patterns/pattern-uuid`. The file does not need to have to be populated with any specific content. Its mere presence is all that is necessary for usage of the pattern to not be tracked.
