# First run with Floci

This guide explains what to install after cloning, which tasks to run, and how to deploy the local AWS or Azure lab.
Docker runs Floci, its Kubernetes nodes, and the tools container; Atmos, OpenTofu, Helmfile, kubectl and the AWS CLI
run inside that container, so they are not installed on the machine.

The documented host is a Linux shell with Docker: a Linux machine or VM, or Docker Engine inside WSL 2 on Windows
(Docker Desktop with WSL integration also works). The tools image is built for the host platform, so x64 and arm64 both work.
A Mac without local Docker runs the tasks on a Linux VM over SSH: [Docker on another machine](local-development.md#docker-on-another-machine).
Cloud accounts, Azure CLI, gcloud, Java, Python, PowerShell, and a separate Kubernetes installation are not needed for
these local labs. For the Kubemarine installation on VMs, see [VM installation](vm-installation.md).

## The complete sequence

```text
Install Docker and Devbox once -> clone the repository -> devbox shell -> review network access
  -> task test: build the tools image, download providers and validate, without deployment
  -> task lab:up [CLOUD=azure]: start the selected emulator and the tools container
  -> task lab:deploy: the Atmos deploy workflow creates customer infrastructure and applications
  -> task lab:check: check Kubernetes and access applications
  -> task lab:destroy: the Atmos destroy workflow deletes customer resources
  -> task lab:stop: stop the selected emulator
```

`task e2e` runs `lab:up` to `lab:destroy` as CI does, then `task lab:release` instead of `lab:stop` (`KEEP=true`
skips destroy and release; a lab that existed before the run is kept). Installing tools does not start the lab. `lab:up` does not deploy,
and `lab:stop` does not destroy. Choose AWS or Azure for your first run; starting both is not required.

## 1. Docker and Devbox

On Linux, install [Docker Engine](https://docs.docker.com/engine/install/) with the Compose plugin. On Windows, run
everything below in WSL 2, with Docker Engine installed inside the WSL distribution; see
[Windows laptop (WSL 2)](local-development.md#windows-laptop-wsl-2) for WSL memory, the checkout location, VPN and proxy.
[Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) with the WSL 2 backend and WSL
integration for your distribution works as well; it needs
Settings → Resources → Network → **Enable host networking**: the tools container uses the host network to reach
Floci and the Kubernetes APIs. Its built-in Kubernetes is not needed: Floci creates k3s itself.
Allow enough RAM and disk for Kubernetes, applications, and AWS Nexus; Docker's minimum requirements alone are not a
tested lab sizing guarantee.

```bash
docker version
docker info --format '{{.OSType}}'
docker compose version
```

Expected: Docker client and server available, server version 28 or later and Compose 2.33.1 or later (the lab
networks use `gw_priority`), OSType `linux`.

Install [Devbox](https://www.jetify.com/devbox/docs/installing_devbox/) and Git if absent.
`devbox shell` in the repository brings the developer tools from [devbox.json](../devbox.json): Task and the GitHub CLI.

## 2. The tools

| Tool | Version | Where |
|---|---|---|
| Task | 3.53.1 | `devbox shell` ([devbox.json](../devbox.json)) |
| GitHub CLI (`gh`) | 2.104.0 | `devbox shell`: pull requests, issues and workflow runs ([signing in](#github-cli-sign-in)) |
| Atmos | 1.234.1 | tools image ([Dockerfile](../Dockerfile)) |
| OpenTofu | 1.13.9 (modules require >= 1.8.0) | tools image |
| kubectl | 1.34.3 | tools image |
| Helm, helm-diff | 4.3.1, 3.15.13 | tools image |
| Helmfile | 1.8.1 | tools image |
| AWS CLI | 2.37.9, 17 service models (`AWSCLI_SERVICES`) | tools image |
| Kubemarine | 0.55.0 | tools image |
| sops, age | 3.13.3, 1.3.2 | tools image |
| crane, yq | 0.22.1, 4.53.6 | tools image |

The Dockerfile pins the versions; a version change also needs the new `<TOOL>_SHA256_AMD64` and `_ARM64` build args,
or the build fails. The first task that needs the tools builds the image, and a Dockerfile change rebuilds it.
To add a tool or bump a version: [Extending the tools image](local-development.md#extending-the-tools-image).
OpenTofu replaced Terraform in the image; for existing state see
[upgrading an existing checkout](../README.md#upgrading-an-existing-checkout).

### GitHub CLI sign-in

`gh` keeps its token in `~/.config/gh/hosts.yml`, in plain text where the machine has no keyring (a headless VM or WSL),
readable by every process of the user and by anything with access to the Docker socket. Keep the token narrow and
short-lived:

1. Create a fine-grained personal access token for this repository only (Contents, Pull requests and Issues: read and
   write; Actions: read) with a short expiry; authorise it for the organisation if it enforces SSO.
2. Sign in without the token reaching the shell history:
   `read -rs T && printf %s "$T" | devbox run -- gh auth login --with-token && devbox run -- gh auth setup-git`.
3. Afterwards: `devbox run -- gh auth logout --hostname github.com`, and delete the token on GitHub.

The tools container does not see `~/.config/gh`: it mounts only the repository.

## 3. Get the repository and create settings

```bash
git clone https://github.com/Netcracker/qubership-cluster-management.git
cd qubership-cluster-management
devbox shell
task doctor   # fails below Docker Engine 28 or Compose 2.33.1
```

All remaining commands assume this shell in the repository root. For AWS, create settings once:

```bash
[ -f local/settings.json ] || cp local/settings.example.json local/settings.json
```

Review region and DNS servers; ports, network and addresses come from the lab environment that `task lab:up`
leases for the checkout (`.local-runtime/lab.env`, `task lab:env`). The first lab on a host normally takes slot 0 and
creates the Docker subnet 172.18.0.0/16. If a VPN, kind or another network already uses that subnet, `lab:up` prints
"Slot 0 skipped" and leases slot 1 instead; to keep slot 0, run the first `task lab:up LAB_NET_PREFIX=172.28` (the
network keeps those octets afterwards). Other slots use 10.99.N.0/24, with no override.

## 4. Network access, proxies, and providers

Downloading OpenTofu providers is separate from building the image. The providers come from the OpenTofu registry
(`registry.opentofu.org`), which serves provider archives from GitHub releases (`github.com`,
`objects.githubusercontent.com`); `registry.terraform.io` and `releases.hashicorp.com` are not used.

| Setting | Purpose | Location |
|---|---|---|
| HTTPS_PROXY / HTTP_PROXY | External requests through an available proxy | The shell that runs `task`; Task passes them into the tools container |
| NO_PROXY | Direct access to local Floci/Kubernetes | The stacks set it for their tools; keep the local addresses in the shell too |
| Docker proxy | Image pulls and builds | Docker daemon or Docker Desktop settings, separately |
| OpenTofu provider mirror | Alternative provider package source | OpenTofu CLI configuration, `TF_CLI_CONFIG_FILE` |

The stacks set no proxy: a proxy that one machine needs belongs to that machine's shell. If yours needs one:

```bash
export HTTPS_PROXY=http://proxy.example.internal:3128 HTTP_PROXY=http://proxy.example.internal:3128
export NO_PROXY=localhost,127.0.0.1,::1,floci
```

Task forwards these variables, set or not, to every command in the tools container (`TOOLS_ENV` in
[Taskfile.yml](../Taskfile.yml)). Do not add registry.opentofu.org or github.com to NO_PROXY when they must use your
proxy: NO_PROXY does not unblock an external server; it keeps local API requests away from the external proxy.
Do not commit proxy passwords.

### Optional provider mirror

When direct downloads are unavailable, use an approved mirror that serves the `registry.opentofu.org` hostname
in the [provider network mirror protocol](https://opentofu.org/docs/internals/provider-network-mirror-protocol/),
for example an internal Nexus or Artifactory proxy. A mirror that only serves `registry.terraform.io/...` paths
does not match these providers: in OpenTofu, `hashicorp/aws` means `registry.opentofu.org/hashicorp/aws`.
Check coverage for the exact locked provider version and platform. This changes the download source, not the deployment cloud.

Write the CLI configuration inside the checkout (the tools container sees only that), for example
`.local-runtime/tofu.rc`, replacing the URL with your mirror, and export
`TF_CLI_CONFIG_FILE="$PWD/.local-runtime/tofu.rc"` in the devbox shell:

```hcl
provider_installation {
  network_mirror {
    url     = "https://mirror.example.internal/"
    include = ["registry.opentofu.org/hashicorp/*"]
  }
  direct {
    exclude = ["registry.opentofu.org/hashicorp/*"]
  }
}
```

Exclusion prevents matching providers from also consulting the blocked origin.
See [OpenTofu CLI configuration](https://opentofu.org/docs/cli/config/config-file/#provider-installation).
Provider sources stay hashicorp/aws, hashicorp/azurerm, hashicorp/google, hashicorp/kubernetes, hashicorp/http,
and hashicorp/external.
Keep committed .terraform.lock.hcl files; do not delete locks or use init -upgrade just to bypass a download error.
A missing mirror version or checksum mismatch needs investigation, not disabled integrity checks.

`versions.tf` sets compatible version ranges; each root module's `.terraform.lock.hcl` records its selected versions
and checksums for `registry.opentofu.org`.
The lock files are the source of the provider versions; do not unify or upgrade them during machine setup.

### Diagnose download access

From the tools container, which uses the forwarded proxy, with finite timeouts:

```bash
task run -- curl -sSI --connect-timeout 10 --max-time 20 https://registry.opentofu.org/.well-known/terraform.json
```

```bash
task run -- curl -sSI --connect-timeout 10 --max-time 20 https://github.com/opentofu/terraform-provider-aws/releases
```

An accessible endpoint does not prove a particular archive exists. `tofu init` is the final download check.
Repeated 403 responses require a working download route or mirror; endless retries do not solve access denial.
After fixing settings, rerun the check without deleting state or locks.
Provider mirrors do not cover Helm charts, Docker images, or Nexus installation downloads.

## 5. Run the configuration check

```bash
task test
```

It builds the tools image when needed, validates the stacks, runs `tofu fmt`, `init` (no backend), `validate` and
`tofu test` for every module, and checks the scripts and the operator Taskfile. It does not start the emulator or
deploy anything. Providers are cached in `.local-runtime/tofu-plugins`, so later runs are faster.
Resolve provider failures before deployment using the preceding section.
Kubeconfigs, state, and emulator data are excluded from Git and are created later.

## 6. Start and deploy AWS customer1

```bash
task lab:up
task lab:deploy
```

`lab:up` starts Floci, its UI and the lab sidecar, waits for their health, and starts the tools container. It does not
deploy or wait for Argo CD or Nexus. The workflow ([staging-terraform.yaml](../workflows/customers/customer1/staging-terraform.yaml))
creates infrastructure, prepares Kubernetes access (`task -d local prepare` in the tools container), then runs
Nexus/readiness and applications/ALB in parallel. OpenTofu applies are approved automatically.
Nexus readiness is checked by the HTTP provider inside the same apply that creates its VM.
First deployment includes downloads and Nexus installation, so completion can take time.

```bash
task lab:check
```

Expected: Ready node, ready application pods, deployed Helm releases. A completed MinIO bucket Job is normal.
Open http://localhost:4500 for Floci UI and http://argocd.localhost, http://kiali.localhost,
http://minio.localhost, http://headlamp.localhost for applications (slot 0; another slot adds its ports, `task lab:env`:
UI on QCM_LAB_UI_PORT, applications on http://argocd.localhost:QCM_LAB_ALB_PORT). Nexus uses the dynamically published host port
discovered inside OpenTofu; see the local development readiness section. Application login/token requirements still apply.

customer2 has its own workflow: `task lab:deploy CUSTOMER=customer2`.

## 7. Start and deploy Azure customer1

Azure uses a separate Compose project and API on port 4577; AWS Floci and Azure CLI are not required.
`lab:up` trusts the emulator CA in the tools container (`task -d local trust-azure`) and starts the emulator only.
For a fresh Azure environment with no existing cluster or state:

```bash
task lab:up CLOUD=azure
task lab:deploy CLOUD=azure
```

The stack records load-balancer backend IP 172.19.0.3; Docker can allocate another address on a new machine.
After access preparation, compare the node's InternalIP with
components.terraform.load-balancer.vars.backend_addresses.kubernetes in the Azure staging manifest:

```bash
task run -- kubectl --kubeconfig .local-runtime/kubeconfig-customer1-azure-staging.yaml get nodes -o wide
```

Update that local setting if different. Floci Azure LB does not forward traffic, regardless of this configuration.
Before repeating infrastructure apply, inspect its plan: Floci AKS read-back omits properties and has caused replacement plans.
With existing network state:

```bash
task run -- atmos terraform plan kubernetes -s customer1-azure-staging -input=false
```

For an existing cluster, refresh access and apply applications/LB without reapplying Kubernetes:

```bash
task run -- atmos workflow deploy-staging -f customers/customer1/azure --from-step access
```

```bash
task lab:check CLOUD=azure
```

Run each port-forward in a separate terminal from the repository root (inside `devbox shell`):

```bash
task run -- kubectl --kubeconfig .local-runtime/kubeconfig-customer1-azure-staging.yaml -n argocd port-forward svc/argocd-server 18080:80
```

```bash
task run -- kubectl --kubeconfig .local-runtime/kubeconfig-customer1-azure-staging.yaml -n istio-system port-forward svc/kiali 18081:20001
```

The tools container uses the host network, so http://localhost:18080 and http://localhost:18081 open on the host.
Ctrl+C ends that port-forward, not the application.
GCP is an inactive template; no unverified GCP launch sequence is provided here.

## 8. Destroy resources, then stop

Keep Docker and the emulator running until deletion succeeds. AWS customer1:

```bash
task lab:destroy
task lab:stop
```

Azure customer1:

```bash
task lab:destroy CLOUD=azure
task lab:stop CLOUD=azure
```

OpenTofu applies are approved automatically. Kiali CR is deleted before its operator; applications/LB before
Kubernetes/network. `lab:stop` retains state and data. Azure preserves AKS across emulator shutdowns, so destroy must
come first. Do not delete state or Floci data as a substitute for resource deletion.
To give the lab environment back to the Docker host (for example before removing a worktree), run `task lab:release`
after the destroy: it also removes the persisted Floci data (`local/floci-data`, `local/floci-azure-data`).
`task lab:list` shows the labs of the host.

## First-run troubleshooting

| Symptom | Check / action |
|---|---|
| `task: command not found` | Run the commands inside `devbox shell` |
| Docker unavailable / wrong engine | Start Docker; on Windows, Docker Engine inside this WSL distribution (`sudo systemctl start docker`) or Docker Desktop with WSL integration for it |
| Tools container cannot reach localhost:4566 | Docker Desktop: enable host networking |
| settings.json missing | Copy the example before `lab:up` |
| Slot 0 skipped: subnet 172.18.0.0 is in use | Not an error: `lab:up` leased the next free slot. To keep slot 0 despite the other network, run the first `task lab:up LAB_NET_PREFIX=172.28`. A slot N whose 10.99.N.0/24 is taken is skipped the same way |
| tofu init HTTP 403 | Review region/access restrictions, proxy, and mirror; retries alone do not fix denial |
| Local API 502 / proxy errors for localhost | Keep local endpoints in NO_PROXY; check HTTPS_PROXY in the shell |
| TLS errors | Review trusted certificates and corporate proxy CA; do not disable TLS verification as the default fix |
| Port already allocated | Inspect containers/processes: slot 0 uses 80/4500/4566, Azure API 4577, sidecars 4590/4591, EKS 6500–6599, AKS 6600–6699, EC2 SSH 2200–2299, EC2 security-group ports 30000–30999; other checkouts use their slot's ports (`task lab:env`, `task lab:list`, [parallel lab environments](local-development.md#parallel-lab-environments)) |
| Docker Address already in use | Inspect networks; see recovery notes. Do not delete shared networks/state |
| Kubeconfig missing | Deploy/access preparation creates it; `lab:up` alone does not |
| Azure LB IP does not open UI | Expected emulator limitation; use port forwarding |

## Verification scope

`task test` and `task e2e` (emulator up, deploy, cluster check, destroy) for AWS customer1
(workflow file `customers/customer1/staging-terraform`) and Azure customer1 (`CLOUD=azure`) were run on an arm64 Ubuntu
24.04 VM. Three of them ran at the same time on one Docker host in lab environments 1–3 (AWS, AWS, Azure; see
[parallel lab environments](local-development.md#parallel-lab-environments)), each a full `task e2e` through the image
cache: about 35 minutes each with an empty cache, 10–12 minutes with a warm one. The Azure port-forward steps and the
complete sequence on a clean Windows + WSL 2 machine have not been verified there.

See [local development](local-development.md) for internals and recovery, [architecture](architecture.md)
for imports and values, and [five-page diagrams](diagrams/README.md) for visual explanations.
