# Quality gate and cost-allocation tags

## Quality gate

`task lint` runs the checks below, each scanner in its own image pinned by tag and digest (`compose.lint.yml`), with
the checkout mounted read-only and no network. The same command runs locally and in the `Quality gate` GitHub
workflow (`.github/workflows/lint.yml`).

| Task | Checks | Settings |
|---|---|---|
| `lint:copies` | Every `components/terraform/<cloud>/<module>/cost_tags.tf` is identical to the one in `aws/network` | `taskfiles/lint.yml` |
| `lint:leaks` | `providers/`: no cloud account or subscription IDs in context, SSH public keys or private keys (the all-zero account of test mocks is allowed). With `LEAK_EXTRA_PATTERNS=<file>` also the patterns of that file, kept outside the repository, over the whole working tree. `.leakscan.repo.patterns` is checked over the whole working tree too: references to documents that are not part of the repository | `.leakscan.patterns`, `.leakscan.repo.patterns` |
| `lint:tflint` | OpenTofu modules under `components/terraform` and `providers`: the bundled `terraform` ruleset, `recommended` preset, naming, required versions and providers | `.tflint.hcl` |
| `lint:trivy` | (1) `trivy fs`: secrets in the working tree, Dockerfiles, plain Kubernetes YAML; (2) `trivy config` per OpenTofu module, with the module's `trivy.tfvars` when it has one | `trivy.yaml` |
| `lint:yamllint` | Syntax, duplicate keys, indentation of stacks, workflows and CI files (`*.gotmpl` is not plain YAML and is skipped); line length over 160 is a warning only | `.yamllint.yaml` |
| `lint:pull` | Not part of `task lint`: pulls the three images into the local Docker (see Offline) | `compose.lint.yml` |

**Severity.** HIGH and CRITICAL fail the gate. MEDIUM and LOW are **not reported at all**; `trivy config --severity
MEDIUM <module>` lists them. Raising the gate to MEDIUM is a separate change.

**Inputs for OpenTofu.** Without input values, `for_each` and `count` over inputs produce no resources, so Trivy
would see no VM and no subnet. Modules with such resources carry `trivy.tfvars` with representative values (the
values of their `tofu test` files or of the staging stacks): `aws|azure|gcp/vms`, `aws|azure/network`,
`gcp/kubernetes`. A new module with `for_each` over an input needs one too. OpenTofu does not load `trivy.tfvars`
on its own.

**Not covered.**
- Git-ignored runtime data: emulator data (`local/floci-data`, `local/floci-azure-data`, `local/backups`),
  `.local-runtime`, `.devbox` and local OpenTofu state (`*.tfstate*`, `terraform.tfstate.d`) are skipped in
  `trivy.yaml`, because they hold the emulators' own keys and Trivy does not read `.gitignore`. Trivy's built-in
  allow rules also skip paths that look like tests (for example `tests/` or `test` in a file name).
- Helm: the only chart (`components/helmfile/minio/charts/minio-bucket`) is a Go template and a post-install hook,
  and the Helmfile releases (`*.gotmpl`) are not rendered, so no Helm or Helmfile output is scanned. Backlog:
  `helmfile template` of the reference stacks into a temporary directory, scanned as Kubernetes YAML.
- tflint without the aws, azurerm and google rulesets checks style and structure only, not provider rules (invalid
  instance types, deprecated arguments). The rulesets are plugins that `tflint --init` downloads from GitHub, which
  the offline gate cannot do. Backlog: pinned plugins mirrored and mounted through `TFLINT_PLUGIN_DIR`.
- Vulnerability and licence scanning of images (they need the vulnerability database) belong to the release
  pipeline; history-wide secret scanning and a leak check of exported code belong to the export process.

**Blocking the merge.** The workflow fails on a finding, but it blocks a merge only when `Quality gate / lint` is a
required status check in the branch protection of `main` (repository settings, done once by a maintainer).

**Offline.** The scanners download nothing: tflint uses only its bundled ruleset, Trivy only the checks embedded in
its binary. `task lint:pull` pulls the images into the local Docker only; to use them without Internet, mirror the
three images (tag and digest as in `compose.lint.yml`) into Nexus and set `LINT_REGISTRY=<nexus-docker-host>/`.
`LINT_REGISTRY` replaces both `ghcr.io/` (tflint) and `docker.io` (Trivy, yamllint), so the Nexus Docker repository
behind it must serve both paths: a group repository over a ghcr.io proxy and a Docker Hub proxy, or a hosted
repository with the images pushed under `terraform-linters/tflint`, `aquasec/trivy` and
`pipelinecomponents/yamllint`.

**Accepted findings.** An exception is explicit, time-limited and recorded in the repository.
- OpenTofu: inline, on the one resource, with a reason comment and `#trivy:ignore:<ID>:exp:<date>`. A new resource
  with the same problem, even in the same file, fails the gate.
- Dockerfiles: `.trivyignore.yaml` (path, reason, `expired_at`).

After the date the finding fails the gate again. What stays accepted until 2027-02-17, and why:

| Finding | Where | Why it stays |
|---|---|---|
| AWS-0053: public ALB | `aws/load-balancer` | By design: the ALB publishes the stack UIs to the operators |
| AWS-0054: HTTP listener | `aws/load-balancer` | No certificate configured (`certificate_arn` is null). With a certificate the finding does not apply: HTTPS plus a redirect |
| AWS-0104: egress to 0.0.0.0/0 | `aws/nexus`, `aws/vms` | Nexus and the Kubernetes VMs reach upstream mirrors and package repositories, until the offline network model is fixed |

Fixed and no longer excepted: the public Kubernetes API endpoints (below), IMDSv1 and unencrypted root volumes of the Nexus and Kubernetes VMs (IMDSv2 required,
`encrypted = true`), ALB egress (only to the VPC CIDR) and `drop_invalid_header_fields`, EKS secrets encryption (KMS
key with rotation), the AKS network policy (`azure`). `task e2e` on Floci (AWS and Azure) applies and re-reads all of
these except the Kubernetes VMs of `aws/vms`, which the reference stacks do not create there (`tofu test` covers them;
the instance settings are the same as Nexus). Floci does not store the AKS network profile, so the policy is not read
back there. A new exception for a finding that can be fixed needs the same check, and a reason in the comment above it.

## Kubernetes API access and HTTPS

| Variable | Module | Default | Effect |
|---|---|---|---|
| `public_access_cidrs` | `aws/kubernetes` | `[]` | CIDRs that may reach the public EKS endpoint. Empty: no public endpoint, the API is reachable from inside the VPC only |
| `api_server_authorized_ip_ranges` | `azure/kubernetes` | none (required) | CIDRs that may reach the AKS API server. At least one, so an open API is a decision of the stack |
| `certificate_arn` | `aws/load-balancer` | `null` | ACM certificate: HTTPS listener on 443 with the `ELBSecurityPolicy-TLS13-1-2-2021-06` policy, HTTP redirects to it. Null: plain HTTP on 80 |

A real stack lists its operator and CI runner CIDRs, for example in the component's `vars`. The Floci lab stacks
(`customer1`, `customer2`) set `0.0.0.0/0`, because the lab and the runners reach the API from outside the network;
that value in a module's `trivy.tfvars` fails the gate (AWS-0040, AWS-0041).

## Existing stacks: resources the next apply recreates or changes

Checked against the AWS provider pinned in the lock files (6.70 for `aws/nexus`, 6.71 for `aws/vms`): `encrypted` in
`aws_instance.root_block_device` is ForceNew. On an account that already has these instances, `tofu plan` shows:

| Resource | Change | Effect |
|---|---|---|
| `aws_instance` in `aws/nexus` and `aws/vms` | **Recreated** (`encrypted = true`) | Root volume data is lost; instance ID and IP change. `aws/nexus` is also recreated by any change of `user-data.sh.tftpl` (`user_data_replace_on_change`), so one apply recreates it only once |
| `aws_eks_cluster` encryption (`encryption_config`, KMS key) | In place | Secrets encryption is added to the running cluster. It cannot be removed afterwards |
| `metadata_options` (IMDSv2) on the instances | In place | Applies on the instance that is recreated anyway |
| `vpc_config`: `endpoint_private_access`, `public_access_cidrs` | In place | See the section above for the empty default |

Before the apply:
- Nexus: back up the blob store and the database (`/opt/sonatype-work/nexus3`) with Nexus' own backup task, or copy the
  directory off the instance, and restore it on the new one. If the blob store sits on the root volume, it is lost
  otherwise.
- VMs and anything else on a root volume: either accept the recreation, or keep the instance: stop it, snapshot the
  root volume, copy the snapshot with encryption on, register an AMI from the copy and recreate from that AMI (the
  instance is still recreated, but with its data).
- Run `tofu plan` and check that only the listed resources are replaced. Do not apply on a stack whose Nexus holds the
  only copy of artifacts.

## Cost-allocation tags

The cloud resources of a stack carry the same tags (labels on GCP):

| Tag | Value |
|---|---|
| `tenant`, `stage`, `environment`, `cloud` | Atmos stack vars |
| `managed-by` | `qubership-cluster-management` |

Extra tags come from the `cost_tags` var. Set it in the `terraform` section of a stack, for example in a customer's
`_defaults.yaml`, so that it reaches the Terraform components only, not the Helmfile ones:

```yaml
terraform:
  vars:
    cost_tags:
      cost-center: cc-1234
      owner: platform-team
```

Only the cloud modules (`components/terraform/aws|azure|gcp/*`) declare it. `kubernetes/*` and `kubemarine` create
in-cluster objects, not cloud resources, so they are not tagged; OpenTofu warns about the undeclared value there and
ignores it.

**Replaced tags.** Before these tags the modules set `Environment` and `ManagedBy = "terraform"` (AWS, Azure VMs) and
the labels `environment` and `managed_by = "terraform"` (GCP VMs). They are gone: the next apply of an existing stack
retags its resources in place (`Environment` becomes `environment`, `ManagedBy`/`managed_by` becomes `managed-by` with
the value `qubership-cluster-management`). Cost reports, budgets and policies that select on the old keys or on
`terraform` must switch to the new ones. `Name` and `Role` stay.

The mandatory tags win over extra keys of the same name. Keys and values follow the GCP label rules (lowercase
letters, digits, `_` and `-`, up to 63 characters), so a stack tags the same way on every cloud; mandatory values are
lowercased and other characters replaced with `-`. Each cloud module has the same `cost_tags.tf` (`task lint:copies`
checks it); copies, not a symlink, because a Windows checkout without `core.symlinks` turns a symlink into a text file.

| Cloud | How | Not tagged |
|---|---|---|
| AWS | Provider `default_tags`; the EC2 root volumes explicitly (`root_block_device.tags`) | — |
| GCP | Provider `default_labels`; the GKE node VMs and disks through `node_config.resource_labels` (updated in place); the VM boot disks through `boot_disk.initialize_params.labels` | Boot disks of VMs that existed before the labels: `initialize_params` is ForceNew, so the labels are ignored on existing VMs (`ignore_changes`) instead of recreating them |
| Azure | `tags` on each taggable resource; the AKS node pool (`default_node_pool.tags`: the scale set and its instances); the cluster tags reach the node resource group and the resources AKS creates there (load balancer, public IPs, NSG, route table, identities) | OS disks of the VMs (`os_disk` has no tags, and VM tags are not copied to the disk) and of the AKS nodes. Cover them with Azure Cost Management tag inheritance (subscription or resource group tags applied to the cost records) |
