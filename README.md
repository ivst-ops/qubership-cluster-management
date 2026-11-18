# Qubership Cluster Manager

Deploy Kubernetes infrastructure and applications with Atmos, OpenTofu, and Helmfile.
Customer stacks combine reusable components with cloud and environment settings.
Workflows define the order of deployment and deletion.

| Deployment path | How Kubernetes is installed | Start here |
|---|---|---|
| Managed Kubernetes | OpenTofu uses the cloud Kubernetes API. The local AWS and Azure scenarios use Floci. | [First run with Floci](docs/getting-started.md) |
| Kubemarine on VMs | OpenTofu creates VMs. Kubemarine installs Kubernetes over SSH using an offline bundle served by Nexus. | [VM installation on AWS and Azure](docs/vm-installation.md) |

Both paths use shared Helmfile components. Managed stacks use public chart repositories.
Kubemarine stacks use the chart repository and versions from the Nexus bundle.

## Developer tasks

From a Linux shell with Docker and Docker Compose (a Linux VM, WSL 2) and [Devbox](https://www.jetify.com/devbox),
in the repository root. `devbox shell` brings [Task](https://taskfile.dev) and the other developer tools
([devbox.json](devbox.json)); the infrastructure tools run in a container of the tools image, rebuilt when the
Dockerfile changes:

```bash
devbox shell
task --list                       # everything below and more
task test                         # stacks, module validation and tests, script syntax; changes nothing
task e2e                          # what CI deploys: Floci up, deploy, check, destroy, release (CLOUD=azure; KEEP=true keeps the lab; customer2 has no destroy workflow: CUSTOMER=customer2 KEEP=true)
task tools:shell                  # a shell with Atmos, OpenTofu, kubectl, Kubemarine...
task image:release                # the linux/amd64 tools image, as CI builds it (qcm-tools:local)
task docs:diagrams                # regenerate docs/diagrams (manual; docs:diagrams:check compares)
```

### Upgrading an existing checkout

- `local/lab.sh` commands → Task: `start` / `start-azure` / `stop` → `task lab:up` / `task lab:up CLOUD=azure` /
  `task lab:stop`; `check` → `task test` / `task test:render`; `secrets-init` / `with-secrets` / `tunnel … stop` →
  `task ops -- secrets:init` / `secrets:exec` / `tunnel:stop`.
- `bundle/build.sh` → `task bundle` (then `task bundle:pack` for a release).
- The lab stacks no longer set `HTTPS_PROXY`: export the proxy in the shell, Task forwards it to the tools container.
- The tools container runs as you: [give back root-owned files](docs/local-development.md#devbox-taskfiles-and-the-tools-container) once.
- The PowerShell scripts in `local/scripts` and the Docker CLI in the tools image are gone: run everything through
  `devbox shell` and Task. `Test-Project.ps1` → `task test`; `Start-Local.ps1` / `Start-AzureLocal.ps1` →
  `task lab:up` / `task lab:up CLOUD=azure`; `Stop-Local.ps1` → `task lab:stop`; `Prepare-Cluster.ps1` /
  `Prepare-AzureCluster.ps1` → the deploy workflow (by hand: `task ops -- prepare STACK=…` / `prepare-azure`);
  `Get-NexusTerraformEndpoint.ps1` → nothing, the Nexus module finds the port itself.
- OpenTofu replaces Terraform, and the tools image no longer has a `terraform` binary. The lock files now point to
  `registry.opentofu.org`, so re-run `tofu init` (or the next `atmos terraform` command) in every component with an old
  `.terraform/` directory.
- Existing state in `terraform.tfstate.d/` works as is: OpenTofu reads state written by Terraform 1.16.5 and
  rewrites it on the next apply; the state then names providers by their `registry.opentofu.org` addresses. Going
  back to the old Terraform image is not supported: if you must, keep the same provider versions and test a `plan`
  on a copy of the state first.
- The Kubernetes API is closed by default: `aws/kubernetes` has no public endpoint unless `public_access_cidrs` lists
  CIDRs, and `azure/kubernetes` requires `api_server_authorized_ip_ranges`. An existing stack that other machines reach
  must set them before the next apply, or that apply removes the public EKS endpoint
  ([API access and HTTPS](docs/quality-gate.md#kubernetes-api-access-and-https)).
- **The next apply recreates the existing Nexus and Kubernetes VM instances** (`aws/nexus`, `aws/vms`): the encrypted
  root volume (`root_block_device.encrypted`) cannot be changed in place. Data on the root volume is lost and the
  instance ID and public IP change. Back up first
  ([recreated resources](docs/quality-gate.md#existing-stacks-resources-the-next-apply-recreates-or-changes)).

## Documentation

1. [First run with Floci](docs/getting-started.md): install, `task test`, the local AWS or Azure lab.
1. [Local development](docs/local-development.md): lab tasks, parallel labs, image cache, CI, recovery.
1. [VM installation](docs/vm-installation.md): Kubemarine, the offline bundle and its GitHub release.
1. [Managed cloud preparation](docs/deployment.md): real Azure and Google Cloud accounts.
1. [Architecture](docs/architecture.md) and its [diagrams](docs/diagrams/README.md): layout, imports, workflows, values.
