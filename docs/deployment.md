# Managed Azure and Google Cloud preparation

This guide covers real cloud accounts. For the Azure Floci lab, see
[First run with Floci](getting-started.md#7-start-and-deploy-azure-customer1).
For Kubernetes installed on VMs, see [Kubemarine installation](vm-installation.md).

The real-cloud templates are inactive until configured and enabled. Providers read their
credentials from environment variables (below). Real-cloud deployment has not been verified.

The tools image has no Azure CLI or gcloud, and a login on the host (`az login`, `gcloud auth`) does not reach the
tools container. Give the providers credentials as environment variables instead: add them to the stack secrets
(`sops secrets/<stack>.yaml`) and run Atmos under `task ops -- secrets:exec STACK=<stack> -- atmos …`.
Azure: `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` (a service principal). Google Cloud:
`GOOGLE_CREDENTIALS` (the service account key JSON). Create the service principal or service account with
the `az` or `gcloud` CLI on any other machine.

## AWS EKS access

The EKS cluster uses access entries (`authentication_mode: API`), not the `aws-auth` ConfigMap. Name the IAM roles
of the operators and the CI runner in the stack; each gets the EKS cluster-admin access policy unless it names another:

```yaml
components:
  terraform:
    kubernetes:
      vars:
        access_entries:
          operators: {principal_arn: arn:aws:iam::<account>:role/<operators-role>}
          runner: {principal_arn: arn:aws:iam::<account>:role/<runner-role>}
```

The IAM user `<environment>-kubectl` with static keys exists only in the local lab (`local_endpoint` set). A real
stack that had it loses it on the next apply; operators sign in with their role (`aws eks update-kubeconfig --name
<environment>-eks --role-arn …`) after it is in `access_entries`.

An existing cluster created before access entries runs in `CONFIG_MAP` mode, and EKS changes the mode one step at a
time: set `authentication_mode: API_AND_CONFIG_MAP` in the stack and apply, check that the access entries work, then
remove the override (back to `API`) and apply again.

## Azure

1. Create a service principal for the intended subscription and put `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET` and
   `ARM_TENANT_ID` in the stack secrets.
2. Set ARM_SUBSCRIPTION_ID in stacks/customers/customer1/azure/staging.yaml.example.
3. Review region, network ranges, AKS service CIDR, VM size, quotas, and role-assignment permissions.
4. Enable the completed template as a YAML stack. Use a distinct stage if a local stack is already active.

Create .local-runtime before retrieving kubeconfig if the directory does not exist.
AKS uses a separate managed identity with Network Contributor on its subnet.
workflows/azure.yaml contains an infrastructure workflow; its real deployment has not been verified.
Review individual component plans before a combined apply. Kubernetes requires an existing network.

## Google Cloud

1. Create a service account with the needed roles and a key for it; put the key JSON in the stack secrets as
   `GOOGLE_CREDENTIALS`.
2. Set project_id, location, region, and real operator admin_cidrs in the GCP template, replacing the documentation-range CIDR.
3. Review billing, quotas, IAM, API-enablement permissions, and role-assignment permissions.
4. Enable the completed template as a YAML stack. Use a distinct stage if a local stack is already active.

GKE uses a separate node pool and service account. node_count is per zone; the template uses a zonal location.
deletion_protection=true is enabled by default. Network provisioning enables Compute, Container, and IAM APIs
and does not disable them during resource deletion.
workflows/gcp.yaml contains an infrastructure workflow; its real deployment has not been verified.

## Load balancers

Import load-balancer catalogs explicitly once backends are known.
Azure requires resource_group_name/vpc_id from network, backend_addresses (name to private IP), and frontend/backend ports.
GCP requires backend_instances (VM self-links), port_range, and HTTP health-check settings.
Configure client/health-check firewall access for GCP and NSG/backend-port access for Azure.
These components do not automatically configure AKS/GKE ingress: Kubernetes manages Service LoadBalancer resources separately.

Helmfile templates retain laboratory settings, including anonymous Kiali access and Argo CD server.insecure.
Agree on TLS, authentication, storage classes, and persistence before exposing them externally.
