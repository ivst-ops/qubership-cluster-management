# Local development

This guide covers the managed Floci lab. See [VM installation](vm-installation.md) for the Kubemarine operator tasks.

## Prerequisites

For a fresh machine, follow [First run with Floci](getting-started.md) first. It covers Docker and Devbox,
restricted-network provider downloads, proxy/NO_PROXY, and the full first-run sequence for AWS and Azure.
This reference describes the tasks, scripts and recovery in more detail.

Run the commands from the repository root in `devbox shell` on Linux or WSL 2. Internet access is required for
images, providers, Nexus, and charts.

What was run and on which machine: [verification scope](getting-started.md#verification-scope).

## Windows laptop (WSL 2)

Everything runs in Linux, so on Windows the lab runs in WSL 2. These steps target a typical corporate laptop
(x64, 16–32 GB RAM, 512 GB SSD, VPN and proxy). They follow the tested Ubuntu 24.04 setup;
the complete sequence on such a laptop has not been run end to end yet ([verification scope](getting-started.md#verification-scope)).

**1. WSL and its limits.** In PowerShell as administrator: `wsl --install -d Ubuntu-24.04`, then reboot.
WSL takes half of the RAM by default. A running AWS lab used about 4 GB on the test VM (k3s node, applications,
tools container); with Nexus installing, plan for about 8 GB at the peak and 40 GB of disk with the image cache
(an estimate, not a measurement). Create `%UserProfile%\.wslconfig`:

```ini
[wsl2]
memory=10GB        # 16 GB laptop; 20GB on a 32 GB one
processors=6
swap=8GB
[experimental]
sparseVhd=true     # the virtual disk gives freed space back to Windows
```

Apply it with `wsl --shutdown`. `sparseVhd` applies to distributions installed afterwards; for one that already
exists, run `wsl --manage Ubuntu-24.04 --set-sparse true` once (with WSL shut down). On a 16 GB laptop run one lab at a time; close the browser tabs you do not need
during `task lab:deploy`.

**2. Docker inside WSL.** Install [Docker Engine for Ubuntu](https://docs.docker.com/engine/install/ubuntu/) in the
WSL distribution, not Docker Desktop: that is the tested setup, the tools container's host network is then the WSL
machine itself, and no Docker Desktop licence is needed. Enable systemd first, so Docker and the Nix daemon of Devbox
start with WSL:

```bash
printf '[boot]\nsystemd=true\n' | sudo tee /etc/wsl.conf
```

Restart WSL (`wsl --shutdown` in PowerShell), install Docker Engine with the Compose plugin, and let your user run it:

```bash
sudo usermod -aG docker "$USER"
```

Open a new WSL shell and check `docker info --format '{{.OSType}}'` (expected `linux`). Docker Desktop with
WSL integration still works if you already use it: then enable Settings → Resources → Network → **Enable host
networking** and stop its Kubernetes. Do not run both engines at once.

**3. Checkout in the Linux file system.** Clone into the WSL home, for example `~/work/qubership-cluster-management`,
never under `/mnt/c/...`: the tools container mounts the checkout at the same path, and a Windows drive is slow
through 9P, has no Unix owners, and turns scripts' line endings and symlinks into broken files. Clone with Git in
WSL (`git config --global core.autocrlf input`), not with Git for Windows. Edit the files from Windows through
VS Code **WSL** or JetBrains Gateway (WSL); `\\wsl$\Ubuntu-24.04\home\<user>\work` opens the folder in Explorer.
Then install Devbox in WSL and continue with [First run](getting-started.md#3-get-the-repository-and-create-settings).

**4. VPN, proxy and certificates.** Corporate VPNs often hold 172.18.0.0/16: `lab:up` then skips slot 0 and takes
slot 1 (other ports, see `task lab:env`); run the first `task lab:up LAB_NET_PREFIX=172.28` to keep slot 0.
Windows proxy settings do not reach WSL: export `HTTPS_PROXY`, `HTTP_PROXY` and `NO_PROXY` in `~/.bashrc`
([proxies](getting-started.md#4-network-access-proxies-and-providers)) and give Docker the same proxy
(`/etc/systemd/system/docker.service.d/proxy.conf`, [Docker daemon proxy](https://docs.docker.com/engine/daemon/proxy/)).
A corporate TLS-inspecting proxy needs its root CA in WSL: copy it to `/usr/local/share/ca-certificates/` and run
`sudo update-ca-certificates`, then restart Docker. If the VPN breaks WSL networking altogether, try
`networkingMode=mirrored` under `[wsl2]` in `.wslconfig`.

**5. Browser on Windows.** WSL forwards its localhost ports to Windows, so Edge or Chrome on Windows opens the same
URLs as in [AWS application endpoints](#aws-application-endpoints): http://localhost:4500, http://argocd.localhost
(slot 0). Port 80 can already be in use on Windows (IIS, another proxy): `netstat -ano | findstr :80` in
PowerShell shows the owner; stop it, or use a lab in another slot, whose ALB port `task lab:env` prints.

**6. First build.** The first `task test` builds the tools image; later builds reuse the BuildKit cache. The image cache
([Image cache](#image-cache)) keeps the cluster images after the first deployment.

**7. Free the laptop after work.** `task lab:stop` keeps data; `task lab:destroy` first if you do not need the
deployment. `wsl --shutdown` in PowerShell gives all memory back to Windows. Disk: `docker system df`, then
`docker image prune` or `docker volume rm qcm-registry-cache`.

## Docker on another machine

A machine without Docker (a Mac) runs the tasks on a Linux machine it reaches over SSH, for example an OrbStack VM that
sees the checkout at the same path. Nothing is installed on the Mac. Write the connection once in `local/dev.env`
(copy [local/dev.env.example](../local/dev.env.example); the file is ignored by git): developers and AI agents read the
SSH destination there and run `ssh "$QCM_DOCKER_SSH" "cd <checkout path> && devbox run -- task <task>"`. The file is a
reference only, nothing reads it automatically. On Linux and WSL 2 it is not needed.

## Devbox, Taskfiles and the tools container

`devbox shell` brings [Task](https://taskfile.dev) and the other developer tools ([devbox.json](../devbox.json));
[Taskfile.yml](../Taskfile.yml) then starts what it needs:

| Part | Started by | What it is |
|---|---|---|
| Tools container | [compose.yml](../compose.yml) | Container `qcm-tools-<checksum of the checkout path>` of the tools image, one per checkout; runs as the calling user; checkout at the same path, host network |
| Emulator | [local/compose.yml](../local/compose.yml), [local/compose.azure.yml](../local/compose.azure.yml) | Floci, its UI and the lab sidecar |

Every task that uses the tools starts the tools container first: a Dockerfile change rebuilds the image and recreates
the container, an unchanged one is skipped.
The tools image keeps production tools only, Task among them for the
operator Taskfile [local/Taskfile.yml](../local/Taskfile.yml), which the Atmos workflows call in the container.
`task --list` shows every task; `task run -- <command>` runs a tool (`task run -- atmos describe stacks`) and
`task ops -- <task>` an operator task.

```bash
task lab:up                                   # Floci AWS + tools container; CLOUD=azure for Floci Azure (CA trusted too)
task lab:deploy                               # DEPLOY workflow (deploy-staging) of CUSTOMER/CLOUD
task lab:check                                # pods and Helm releases of STACK
task lab:destroy                              # DESTROY workflow (destroy-staging; destroy-infra when the state has no cluster)
task e2e CUSTOMER=customer2 KEEP=true         # all of the above, what CI runs per matrix entry; without KEEP=true the
                                              # lab it leased is released at the end (a failed run keeps it for diagnostics)
task lab:stop                                 # stop Floci; data and resources are kept
task run -- atmos describe stacks             # any command in the tools container
task ops -- prepare STACK=customer1-aws-staging   # an operator task in the tools container
task lab:diagnostics                          # containers, pods and events after a failed deployment
task image:lab                                # the lab sidecar image; image:all adds the linux/amd64 tools image
task bundle:pack                              # split the offline bundle into release assets in dist/
task lab:env                                  # the lab environment of this checkout: slot, ports, network
task lab:list                                 # all lab environments of this Docker host and their checkouts
task lab:stop-all                             # stop every lab of the host (devbox run lab-stop-all)
task lab:release                              # after lab:destroy: remove this lab, give its slot back
```

`STACK` defaults to `<CUSTOMER>-<CLOUD>-staging` and the workflow file to `customers/<CUSTOMER>/<CLOUD>`;
customer1 AWS uses `customers/customer1/staging-terraform`.
Overrides: `IMAGE=` (or `QCM_TOOLS_IMAGE` in the environment) picks the tools image, default `qcm-tools:dev`;
`LAB_NET_PREFIX=` (or `QCM_LAB_NET_PREFIX`) sets the first two octets of the slot 0 lab network, default `172.18`
(use another, e.g. `172.28`, when kind or another network already holds it).
Devbox scripts run the common tasks without a shell: `devbox run test`, `devbox run e2e`, `devbox run lab-list`,
`devbox run lab-stop-all`.

The tools container runs as the user who calls `task` (passwd and group entries in `.local-runtime/tools`), with
HOME in `.local-runtime/home`: files in the checkout keep their owner, and AWS CLI profiles, kubeconfig caches and
Helm data survive a recreated container. The Floci Azure CA is trusted through `SSL_CERT_FILE`
(`.local-runtime/ca-bundle.crt`), so no root is needed. Files that a root container wrote into an older checkout
stay root-owned; give them back once before the first task:

```bash
sudo chown -R "$(id -u):$(id -g)" .local-runtime components/terraform
```

### Extending the tools image

Edit the [Dockerfile](../Dockerfile); `task image` (or any task that starts the tools container) rebuilds it.

1. **AWS CLI service:** the image keeps 17 service models. Append the name (as in `aws <service>`) to `AWSCLI_SERVICES`
   (an empty value keeps all of them), rebuild, and check with `task run -- aws <service> help`.
2. **Helm plugin:** add a pinned, sha256-verified download like the `helm-diff` part of the `helm` stage, installed
   into `/plugins`, which the final image copies to `HELM_PLUGINS=/usr/local/share/helm/plugins` (readable by any uid).
3. **Another tool binary:** add a stage `FROM gobase AS <tool>` with `ARG <TOOL>_VERSION <TOOL>_SHA256_AMD64
   <TOOL>_SHA256_ARM64 TARGETARCH`, download with `fetch URL FILE SHA_AMD64 SHA_ARM64` into `/out`, run
   `strip-check /out/<tool> version` for a Go binary (strip, start check), and add `COPY --from=<tool> /out/ /usr/local/bin/`
   to the final stage. Take the hashes from the project's release checksums; a mismatch fails the build.
4. A system package goes into the `rootfs` stage's `apt-get install`; one that needs perl needs the perl note in
   [vm-installation.md](vm-installation.md).

**Bumping a tool by hand.** [Dependabot](../.github/dependabot.yml) does not see these: the versions and checksums
are plain `ARG`s, not a package manifest. The same goes for `devbox.lock`. To bump a tool:

1. Change `<TOOL>_VERSION` in the [Dockerfile](../Dockerfile).
2. Copy the new `<TOOL>_SHA256_AMD64` and `_ARM64` from the release's checksum file (or `sha256sum` the two
   downloaded binaries); a wrong hash fails the build, which is intended.
3. Update the version in the [tools table](getting-started.md#2-the-tools) and run `task image:release` (or `task test`) to check the build.
4. Task and the other Devbox packages: `devbox update <package>` (or `devbox update` for all) rewrites `devbox.lock`;
   commit it with `devbox.json`. Keep `devbox-version` in `.github/workflows/*.yml` in step with the local Devbox.
5. Images inside Taskfiles, which Dependabot does not see either: `SYSTEM_IMAGES` of `lab:cache-warm` in the
   [Taskfile](../Taskfile.yml) (the k3s system images `rancher/mirrored-coredns-coredns`, `mirrored-metrics-server` and
   `mirrored-pause`: change them with the k3s version of Floci, the image in [local/compose.yml](../local/compose.yml))
   and `ALPINE_IMAGE` (the warm-up and `lab:release`). `ALPINE_IMAGE` and the `alpine` image of `docker_gid` in
   [local/lab-env.sh](../local/lab-env.sh) keep the digest of `local/lab/Dockerfile`, which Dependabot updates.

## Parallel lab environments

Every checkout (the main one, a git worktree, a parallel session) gets its own lab environment on the Docker host:
`task lab:up` runs `local/lab-env.sh acquire`, which leases a free numbered slot, or confirms the one the checkout
already has, and writes it to `.local-runtime/lab.env`. Compose reads that file (`--env-file`), and the tools container
gets the values in its environment (it is recreated when the slot changes), so Atmos, OpenTofu and `local/lab.sh`
see them in every task, workflow and `task tools:shell`. `QCM_LAB_*` variables exported in the shell override
`lab.env` for Compose, so keep them unset.
Every task that acts on the lab of the checkout (`lab:stop`, `lab:deploy`, `lab:check`, `lab:destroy`) first runs
`local/lab-env.sh check`, which refuses when `lab.env` names a slot that another checkout holds now; `lab:release`
then only removes the stale file and leaves that checkout's lab alone.
`lab:destroy` acts on the stack of `CUSTOMER` and `CLOUD` (customer1 and aws by default): pass them for any other lab.
A stack without a `destroy-staging` workflow (customer2 has none) is refused with a message instead of falling back to
customer1. `lab:release` also removes the checkout's `.local-runtime/kubeconfig-*.yaml` and `known_hosts-*`, once no
container of its lab runs, so a later lab does not meet the access files of the released one.

The lease is the slot's Docker network, created with the labels `qcm.lab.slot` and `qcm.lab.owner` (the checkout
path): a network name exists once per Docker host, so creating it is the atomic step.
A checkout keeps its slot for good: its OpenTofu state and Floci data refer to that slot's names.
Floci joins every VPC network it creates, and Docker would then move its default route to the network whose name
sorts first (`floci-aws-vpc-*` before `qcm-lab-N`), cutting the API connections in flight; the lab network attachment
has `gw_priority: 100` against that (hence the Docker and Compose minimums of `task doctor`).
The lab's own ports (AWS API, UI, ALB, Azure API, sidecars) listen on 127.0.0.1 only. The ports Floci publishes for
the containers it starts (EKS and AKS APIs, EC2 SSH and security-group ports) use Docker's default bind address,
all interfaces, and Floci has no setting for it; on a host reachable from other machines, set `"ip": "127.0.0.1"` in
the Docker daemon configuration or firewall those ranges.

| | Slot 0 | Slot N (1 to `QCM_LAB_MAX_SLOT`, default and maximum 9) |
|---|---|---|
| Compose projects | `atmos-local`, `atmos-local-azure` | `qcm-lab-N`, `qcm-lab-N-azure` |
| Lab network | `aws-local_default`, `LAB_NET_PREFIX`.0.0/16 | `qcm-lab-N`, 10.99.N.0/24 |
| Environment names | `customer1-staging`, ... | `customer1-staging-sN`, ... (`QCM_LAB_SUFFIX`) |
| Floci containers and volumes | `floci-aws-...` | `floci-aws-sN-...` (`QCM_LAB_NAMESPACE`) |
| Customer VPCs | 10.40, 10.50, 10.60 (customer1 AWS, customer2 AWS, customer1 Azure) | 10.(40/50/60 + 16·N) |
| AWS API, UI, ALB | 4566, 4500, 80 | B+566, B+500, B+80, with B = 20000 + 1000·N |
| Azure API | 4577 | B+577 |
| Lab sidecars | 4590, 4591 | B+590, B+591 |
| EKS / AKS APIs, EC2 SSH | 6500–6599 / 6600–6699, 2200–2299 | B+600–699 / B+700–799, B+200–299 |
| EC2 security-group ports (Nexus) | 30000–30999 | B+800–999 |

Slot 0 keeps the slot-0 layout (no suffix, no namespace, the documented ports), so the first checkout on a host, CI, and a checkout whose existing lab uses
`aws-local_default` keep their names and URLs. In slot N the ALB routes are http://argocd.localhost:B+80 and so on;
`task lab:env` prints the ports. The environment name drives the cluster, IAM user and AWS profile names, and in slot
N Floci prefixes every container and volume it starts with the namespace `sN` (`FLOCI_DOCKER_RESOURCE_NAMESPACE`):
`floci-aws-s3-eks-customer1-staging-s3-eks`, `floci-aws-s3-vpc-*`, and the names Floci otherwise uses once per host
(`floci-aws-s3-ec2-volumes`, `floci-aws-s3-ec2-volume-helper`, `floci-aws-s3-ecr-registry` and its `-data` volume).
So no two labs ask Docker for the same name or share a volume. The stacks read the slot
through Go templates (`atmos.yaml` enables them): `environment`, `local_endpoint`, the VPC ranges and the Azure
metadata host.

`task lab:list` shows every lab environment of the host with its running containers and owner (a removed checkout
is marked). `task lab:stop-all` (`devbox run lab-stop-all`) stops all of them, whichever checkout started them:
the Compose services of every lab project and the image cache, then the containers Floci started (k3s nodes, EC2 instances, port forwards,
registries: label `io.floci` or names `floci-*`). Data, volumes and networks stay; `task lab:up` in a checkout starts its lab again and
the deploy's `prepare` restarts stopped nodes. To free a slot, run `task lab:destroy` and then `task lab:release` in
its checkout: it removes the emulator containers, the containers, VPC networks and volumes Floci made for the slot (label `floci_namespace=sN`, or the name prefix `floci-aws-sN-` for the k3s data volumes)
and the network lease. A checkout removed without that leaves its
slot taken; remove its containers and its network by hand (`docker network inspect qcm-lab-N`).

### Image cache

`task lab:up` also starts one pull-through image cache for the whole Docker host,
[zot](https://zotregistry.dev) in [local/compose.cache.yml](../local/compose.cache.yml) (container and volume
`qcm-registry-cache`). Every slot and checkout shares it, so a new cluster pulls istio, Argo CD, Kiali, MinIO and the
other public images from the cache instead of the Internet; only the first pull of an image goes upstream.
It mirrors docker.io, quay.io, ghcr.io, registry.k8s.io, registry.istio.io, public.ecr.aws, mcr.microsoft.com and
gcr.io, each under its own path (`/v2/docker.io/library/...`).

The cache is not published on the host. `prepare` and `prepare-azure` ask the lab sidecar (`op=mirror`) to connect it
to the node's network (the lab network at `.250`, or the Compose network of Floci Azure) and to write a containerd
`hosts.toml` per registry into the node's `certs.d`. containerd reads them at each pull, so the node is not
restarted, and it falls back to the upstream registry when the cache does not answer. Images that k3s pulls before
`prepare` (its own system images) still come from the Internet. `task lab:up REGISTRY_CACHE=false` leaves the cache
out; `task lab:stop-all` stops it with the labs, and `docker volume rm qcm-registry-cache` empties it.
`task lab:up` leaves a running cache as it is, also one made by a checkout on another commit, and warns when its
definition differs. After a change of `local/compose.cache.yml` apply it with `task lab:cache-recreate`, which refuses
while any lab runs (`FORCE=true` overrides). Checkouts older than this rule still recreate it on their `lab:up`.

**Warm-up.** zot syncs an image from upstream when its tag is first requested, and parallel first requests for one
repository collide: they wait for each other for minutes, and a lost race fails the sync. `task lab:up` therefore runs
`task lab:cache-warm`: it requests the application images of [bundle/manifest.yaml](../bundle/manifest.yaml)
(`app_images`) and the k3s system images one at a time under a lock of the Docker host
([local/cache-warm.sh](../local/cache-warm.sh)), so the first lab warms the cache and parallel labs find the images
cached. A cached tag is then served from the cache without asking the upstream registry for 24 hours
(`manifestCheckInterval` in [local/compose.cache.yml](../local/compose.cache.yml)); an upstream check that never answers
is abandoned after 4 minutes (`syncTimeout`) and the cached copy is served. After a restart of the cache the first
request of each tag checks upstream again. Images the cache does not serve (for example `ecr-public.aws.com`) are
skipped. The k3s system images in the task follow the k3s version of Floci.

## Configuration and stored data

| Path | Purpose |
|---|---|
| `local/compose.yml` | Floci API on 4566, UI on 4500, ALB HTTP entry point on 80; lab sidecar on 127.0.0.1:4590 (slot 0; see [Parallel lab environments](#parallel-lab-environments)) |
| `local/compose.azure.yml` | Floci Azure API on 4577, AKS APIs on 6600–6699; lab sidecar on 4591 (slot 0) |
| `.local-runtime/lab.env` | The lab environment of the checkout (`local/lab-env.sh`) |
| `local/compose.cache.yml` | The pull-through image cache shared by all labs of the host ([Image cache](#image-cache)) |
| `local/settings.json` | Region and the DNS servers of the k3s nodes; endpoint, network and addresses come from `lab.env` |
| `local/settings.example.json` | A template for a new machine |
| `stacks/customers/<customer>/aws/_defaults.yaml` | OpenTofu endpoint, local_lab, NO_PROXY |
| `local/floci-data/`, `local/floci-azure-data/` | Persisted Floci API data (kept across `lab:stop`, removed by `lab:release`) |
| `.local-runtime/` | Kubeconfigs, nodes.json with node IP and generation, the provider cache |
| `components/terraform/.../terraform.tfstate.d/` | Per-workspace OpenTofu state |
| Docker volumes | k3s/EC2/registry data stored separately from repository files |

Settings, runtime files, state, and Floci data are excluded from Git. AWS CLI profiles live in `.local-runtime/home`.
The lab sidecar runs on the host network, listens on 127.0.0.1 only and accepts POST requests with the token in
`.local-runtime/lab-token` (written by `task lab:up`); it moves a node only within the lab network or Floci's VPC
networks. The lab network (`aws-local_default` in slot 0) is external to Compose: it is the lease of the lab
environment, created by `local/lab-env.sh acquire`; a slot-0 network from an older lab keeps its subnet.
Removing runtime files does not delete resources. Clearing Floci data while retaining populated OpenTofu state causes a mismatch.

Create `local/settings.json` on a new machine as in [First run](getting-started.md#3-get-the-repository-and-create-settings).

The stacks set NO_PROXY to localhost,127.0.0.1,::1,floci for their tools, and local/lab.sh extends it; download
proxies come from the shell ([proxies](getting-started.md#4-network-access-proxies-and-providers)).

## Entry points

| Entry point | Where it runs | Behavior |
|---|---|---|
| `task lab:up` / `lab:stop` | Host (devbox shell) | Compose up with health wait / stop of the emulator; data is kept, customer resources are not deleted |
| `task test` | Host → tools container | Stacks, `tofu fmt`, init (no backend), validate and tests of all modules, script syntax, operator Taskfile |
| `task test:render STACK=...` | Host → tools container | Renders the Helmfile components of a stack without applying them |
| `task -d local prepare STACK=...` | Tools container | After Kubernetes creation: fixes node networking, webhook and DNS, configures AWS access and kubeconfig, waits for node and CoreDNS (`local/lab.sh prepare`) |
| `task -d local prepare-azure STACK=...` | Tools container | Writes the AKS kubeconfig with the published API port, waits for nodes and CoreDNS (`local/lab.sh prepare-azure`) |
| `task -d local logs:run STACK=... -- <command>` | Tools container | Runs the command (with `secrets/STACK.yaml` if it exists) and writes `.local-runtime/logs/STACK-<time>-<ok\|failed>.tar.gz` with the console output, stack configuration, Kubemarine dump and `cluster-info dump`; uploads it when `LOGS_UPLOAD_URL` is set (`local/lab.sh run`). `lab:deploy` and `lab:destroy` run through it, CI uploads the archives as the artifact `logs-<stack>-attemptN`. Details: [VM installation](vm-installation.md#run-logs) |
| `task -d local trust-azure` | Tools container | Downloads and trusts the Floci Azure CA (`lab:up CLOUD=azure` runs it) |
| `local/lab.sh nexus-endpoint-json` | Tools container, by OpenTofu | External program for Floci: reads instance_id from stdin JSON, waits for the published port, returns URL JSON. Timeout 600 seconds (`NEXUS_ENDPOINT_TIMEOUT`), polling every 5 seconds. Does not check application readiness |
| `local/lab/lab-api.sh` | Lab sidecar | The Docker operations of lab.sh (node repair, published ports) behind a small HTTP API |

`lab:up` does not wait for Argo CD or Nexus. Floci itself may restore persisted resources.
`prepare` is called by the workflows after the Kubernetes apply; do not run it before a first deployment.
It requires a local stack with `settings.local_lab: true`.

### Invocation chain

```text
User (devbox shell)
├─ task lab:up → Docker Compose → Floci + UI + lab sidecar; tools container
├─ task lab:deploy → tools container: Atmos deploy workflow → OpenTofu network, Kubernetes
│  └─ access → task -d local prepare → local/lab.sh prepare
│     ├─ Atmos describe → selected stack configuration
│     ├─ AWS CLI → local Floci EKS/EC2/IAM/STS
│     ├─ lab sidecar (HTTP) → Docker: k3s network and node settings
│     └─ AWS CLI + kubectl → profile, kubeconfig, access checks
│  after access succeeds → parallel branches
│     ├─ OpenTofu Nexus → single apply with provider readiness
│     │  └─ external provider → local/lab.sh nexus-endpoint-json → lab sidecar → URL
│     │     └─ OpenTofu HTTP provider → Nexus readiness
│     └─ Helmfile → applications → OpenTofu load-balancer
├─ task lab:destroy → Atmos destroy workflow → customer resource deletion
└─ task lab:stop → Docker Compose stop
```

`lab:up` does not deploy, deploy does not start the emulator, and `lab:stop` does not destroy.
These are separate operations with separate results; `task e2e` chains them as CI does.

### Configuration producers and consumers

| Setting | Consumer | Effect |
|---|---|---|
| lab.env QCM_LAB_AWS_PORT, settings.json region | local/lab.sh | AWS CLI target during access preparation |
| lab.env QCM_LAB_NETWORK | local/lab.sh, lab sidecar | Docker network of the k3s node |
| `LAB_NET_PREFIX` (slot 0), slot number | local/lab-env.sh | Lab network addressing on creation |
| dnsServers | lab sidecar node repair | nameserver entries inside the k3s container |
| STACK=customer1-aws-staging | prepare | Stack queried from Atmos |
| vars.environment | local/lab.sh and OpenTofu components | Customer cluster, IAM user, and VM identity |
| vars.local_endpoint and vars.region | OpenTofu providers | Cloud API target |
| Final stack env.KUBECONFIG | Helmfile launched through Atmos | Cluster access for charts |
| load-balancer.vars.kubeconfig_path | OpenTofu ALB Kubernetes provider | Access to existing Services |

Local settings and Atmos defaults are separate inputs for separate consumers. Changing one does not update the other;
keep the region aligned; endpoints follow the lab environment on both sides. Stack kubeconfig paths are relative to component directories.
Prepare writes the actual kubeconfig under the repository root's runtime directory.

### lab:up: actions and result

`task lab:up` writes the sidecar token once, leases the lab environment of the checkout (its network, see
[Parallel lab environments](#parallel-lab-environments)), then runs
`docker compose --env-file .local-runtime/lab.env -f local/compose.yml up -d --build --wait`: it builds the lab sidecar, starts Floci, its UI and the
sidecar, and waits for their health checks. Then it starts the tools container (and, for Azure, trusts the CA).

The result is an available Floci API and UI. Customer VPC, cluster, Nexus, and applications are created by deployment.
Floci uses the Docker socket to create k3s, EC2, registry, and port-forwarding containers as APIs are called.
Those containers are not separate services in our Compose file. The tools container has no Docker CLI or socket:
the lab sidecar does the few Docker operations that access preparation needs.

### prepare: inputs, actions, outputs

`task -d local prepare STACK=<stack>` runs `local/lab.sh prepare`:

1. It reads the argocd component's configuration through Atmos. Argo CD is only the configuration lookup target;
   an installed Argo CD server is not required for this lookup.
2. environment=customer1-staging determines cluster customer1-staging-eks, container floci-aws-eks-customer1-staging-eks,
   AWS profile floci-customer1-staging, and IAM user customer1-staging-kubectl.
3. It queries EKS/EC2 for the node address and compares createdAt with nodes.json to identify cluster generations.
4. The lab sidecar pins the IP, stopping and reconnecting the container when needed, fixes the token webhook,
   the floci hosts entry and DNS, starts a stopped node, and waits for its Kubernetes API.
5. It checks the profile identity, creates an access key for the OpenTofu-created IAM user when necessary,
   and saves credentials, region and endpoint in the AWS CLI profile.
6. It writes the kubeconfig with an `aws eks get-token` exec configuration, verifies authentication,
   and waits for Ready nodes and Available CoreDNS.

Prepare changes container configuration and access settings; it is not just a read-only configuration display.
Success means subsequent application steps can access the cluster.

| Output | Subsequent consumer |
|---|---|
| .local-runtime/nodes.json | Future preparation of the same cluster |
| .local-runtime/kubeconfig-customer1-aws-staging.yaml | kubectl, Helmfile, OpenTofu ALB Kubernetes provider, Kiali CR deletion |
| AWS profile floci-customer1-staging | AWS CLI token generation for kubectl/Helm/Kubernetes provider |
| Fixed node network, hosts, DNS, webhook | k3s and its applications |

To restore access to an existing cluster manually, for example after the tools container was recreated:

```bash
task ops -- prepare STACK=customer1-aws-staging
```

### Stop and configuration checks

`task lab:stop` stops Floci, its UI and the sidecar through Compose.
Success confirms those services stopped, not that customer resources were deleted.
Files and Docker volumes remain; run a successful destroy before stopping the environment.

`task test` checks stacks, OpenTofu formatting and module validity (with `tofu test`), the Bash syntax and the
operator Taskfile. `task test:render STACK=customer1-aws-staging` renders the Helmfile components.
Passing these checks does not verify cloud APIs or application runtime health.

## Running the Floci lab

For the AWS and Azure startup, deployment, access checks, and shutdown commands, use
[First run with Floci](getting-started.md#6-start-and-deploy-aws-customer1).
See [Workflows and readiness](architecture.md#workflows-and-readiness) for the AWS deployment and deletion order.

Customer2 has a separate sequential deployment:

```bash
task lab:deploy CUSTOMER=customer2
```

It excludes Nexus/ALB and currently has no destroy workflow (`task e2e CUSTOMER=customer2 KEEP=true`).

## AWS application endpoints

Slot 0 (other slots: their ports, `task lab:env`): Floci UI http://127.0.0.1:4500; configured ALB routes serve
http://argocd.localhost, http://kiali.localhost, http://minio.localhost, and http://headlamp.localhost
(slot N: `:QCM_LAB_ALB_PORT` after the host name).
Nexus uses a dynamic host port discovered by OpenTofu; do not hardcode 30000.
Its writable status endpoint returns 200 when ready. MinIO uses persistence.enabled=false;
data is not expected to survive pod replacement.

## Nexus readiness details

### OpenTofu-managed readiness

`task lab:deploy` runs `deploy-staging` of [staging-terraform.yaml](../workflows/customers/customer1/staging-terraform.yaml);
the order and the readiness check inside the single Nexus apply are in
[Workflows and readiness](architecture.md#workflows-and-readiness). In real AWS the URL is built from
`aws_instance.nexus.public_ip` (else `private_ip`) on port 8081, and the OpenTofu runner must reach it.

For local Floci, `data.external.nexus_endpoint` in `components/terraform/aws/nexus/readiness.tf` runs
`local/lab.sh nexus-endpoint-json` after the VM and HTTP ingress rule are created. The external
provider passes the instance ID as JSON on stdin. The script asks the lab sidecar for the host port that
`floci-aws-[sN-]ec2-fwd-<instance-id>-8081` publishes, waiting up to 600 seconds (`NEXUS_ENDPOINT_TIMEOUT`) with a 5-second
polling interval, and
returns `{"url":"http://127.0.0.1:<port>/service/rest/v1/status/writable"}` on stdout. It does not install anything,
create containers, call Atmos, or send HTTP requests to Nexus. Failure to resolve the port fails the apply.
The HTTP data source consumes this URL and performs application readiness retries within the same apply.
This local integration needs the lab sidecar (`task lab:up`) on the OpenTofu host.
The script is not called for real AWS, when readiness is disabled, or when an explicit readiness URL is supplied.
In AWS, the OpenTofu runner must be able to reach the VM address. No URL environment variable or manual script
invocation is required. Stack validation and workflow dry-runs do not verify a complete deployment.

The HTTP provider retries failed connections and retryable HTTP errors up to 60 times, with 10-second delays
and a 5-second per-request timeout. The postcondition requires HTTP 200. Waiting does not restart installation
or repair failed user-data. The Nexus catalog enables readiness for direct component apply too; the destroy
workflow explicitly disables it.

local/lab.sh obtains stack JSON through `atmos describe ... --file` and removes its temporary files.
CLI diagnostics are not parsed as JSON.
Nexus user-data sets DPkg::Lock::Timeout=180 because Floci may install SSH packages concurrently.
ALB uses the customer1 stack's kubeconfig_path, matching Prepare's output file.

## CI

[ci.yml](../.github/workflows/ci.yml) runs on pull requests and on `main` with the tasks above:

| Job | What it runs |
|---|---|
| `image` | Builds the tools image and publishes it to GHCR (`<repository>-tools:<commit>`, `latest` on `main`); a fork or Dependabot pull request has no write token, so it builds `task image:release` instead and passes the image on as an artifact |
| `validate` | `task doctor`, then `task test` with that image |
| `deploy` | `task doctor`, then `task e2e` per matrix entry (customer1 AWS, customer2 AWS with `KEEP=true`, customer1 Azure); on failure `task lab:diagnostics` |

`Bundle` ([bundle.yml](../.github/workflows/bundle.yml)) builds and publishes the offline bundle on a `bundle-*` tag or
a manual run ([bundle release](vm-installation.md#bundle-from-a-github-release)).

To repeat a failed deploy locally, run `task e2e` with the `vars` of its matrix entry.

## Validation and recovery

```bash
task test
task run -- atmos workflow deploy-staging -f customers/customer1/staging-terraform --dry-run
task run -- atmos workflow destroy-staging -f customers/customer1/staging-terraform --dry-run
task run -- atmos workflow destroy-services -f customers/customer1/staging-terraform --dry-run
task run -- atmos workflow destroy-infra -f customers/customer1/staging-terraform --dry-run
```

Parallel-group dry-run does not execute child workflows; inspect them separately.
`task test` downloads providers and `task test:render` renders charts; neither applies infrastructure.
Failures leave already-created resources in place. Do not reuse a plan after state changes.
The main deployment regenerates plans. To resume application installation from a known step, for example:

```bash
task run -- atmos workflow deploy-platform -f customers/customer1/staging-terraform --from-step minio
```

Newer Floci attaches the k3s node to a Docker network of its VPC and manages it; `prepare` then never stops the node.
Floci also keeps a deleted cluster's k3s data in the volume `floci-aws-[sN-]eks-<cluster>`, and a new cluster with the same
name reuses it: k3s then fails on the earlier node address (`failed to find interface with specified node ip` in
`docker logs floci-aws-[sN-]eks-<cluster>`). `task lab:destroy` removes such volumes once no container uses them. A cluster
that already fails this way needs to be recreated: destroy what does not need its API, remove the volume, deploy again:

```bash
for c in load-balancer kubernetes network; do task run -- atmos terraform destroy $c -s customer1-aws-staging -auto-approve -refresh=false </dev/null; done
```

```bash
docker volume ls -q --filter dangling=true | grep -E '^floci-aws-(s[0-9]+-)?eks-' | xargs -r docker volume rm
```

For Docker Address already in use, compare `docker network inspect <QCM_LAB_NETWORK>` (`task lab:env`; `aws-local_default` in slot 0) with nodes.json.
The workflow creates Kubernetes before Nexus, which prevents a new collision but does not repair an existing one.
Do not delete state or shared Docker networks to bypass the failure.
For local Floci HTTP 502, check proxy bypass. For slow Nexus startup, inspect
/var/log/nexus-install.log and /opt/sonatype-work/nexus3/log/nexus.log inside its EC2 container.
A Helm release that fails with `context deadline exceeded` while its pod is still pulling an image (a slow first
pull) needs more time, not a fix: raise `helm_timeout` (seconds; default 600, the lab stacks set 1200) in the
stack's top-level `helmfile.vars` section, or per component in `components.helmfile.<name>.vars`, then resume the
workflow from that step with `--from-step`.
A chart download that fails with `Client.Timeout exceeded while awaiting headers` (GitHub release assets sometimes
answer slowly) is retried: a `prepare` hook of each release (`components/helmfile/warm-chart.sh`) puts the chart into
helm's content cache with up to 5 attempts (`CHART_WARM_ATTEMPTS`) before helm diff and upgrade, which then read it
from the cache. The cache is per checkout (`.local-runtime/home/.cache/helm/content`), so the first deploy of a new
checkout downloads each chart once. Each attempt and its error are printed after `hook[prepare] logs |` (stdout only;
helmfile drops a hook's stderr). If all attempts fail, the step fails with helm's own error: resume it with
`--from-step`.
