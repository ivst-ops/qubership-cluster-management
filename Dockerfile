# Production tools; versions: docs/getting-started.md. Build: `task image` (native) / `task image:release` (linux/amd64).
# One stage per tool, built in parallel; Go binaries stripped, not packed (see below); rootfs squashed into one layer.
# No Docker CLI: emulators start on the host with Docker Compose, and the lab sidecar (local/lab/) does the Docker work.
ARG ATMOS_VERSION=1.234.1
ARG TOFU_VERSION=1.13.9
ARG KUBECTL_VERSION=1.34.3
ARG HELM_VERSION=4.3.1
ARG HELM_DIFF_VERSION=3.15.13
ARG HELMFILE_VERSION=1.8.1
ARG AWSCLI_VERSION=2.37.9
ARG KUBEMARINE_VERSION=0.55.0
ARG SOPS_VERSION=3.13.3
ARG AGE_VERSION=1.3.2
ARG CRANE_VERSION=0.22.1
ARG YQ_VERSION=4.53.6
# Task runs the operator Taskfile (local/Taskfile.yml) that the Atmos workflows call; same version as devbox.json.
ARG TASK_VERSION=3.53.1
# sha256 of every download per architecture, from the project's published checksums (helm-diff, age and the AWS CLI
# publish none: hashes of the artifacts). A version change needs its new hashes; the build fails on a mismatch.
ARG ATMOS_SHA256_AMD64=ff14c83551533792d921d629ecf3651c9b0d33f7a0bd63702264aa5644518476
ARG ATMOS_SHA256_ARM64=33d763c5c686ecb88546972089ff4177019180ea1f51d026a9e3109746e946fd
ARG TOFU_SHA256_AMD64=bc44eb6b06446ba83bd4072114891987f590f66cca712737a7f1147c50c539ce
ARG TOFU_SHA256_ARM64=04f7c93828b859d420269ed30f923ffebf09157b5d7fb95bf8d88a4d208b7fa3
ARG KUBECTL_SHA256_AMD64=ab60ca5f0fd60c1eb81b52909e67060e3ba0bd27e55a8ac147cbc2172ff14212
ARG KUBECTL_SHA256_ARM64=46913a7aa0327f6cc2e1cc2775d53c4a2af5e52f7fd8dacbfbfd098e757f19e9
ARG HELM_SHA256_AMD64=0403a88ae20913d11b10a2467b50087721fea7581736da6b9d3992f5357fe54b
ARG HELM_SHA256_ARM64=8cf8f66ecbc252ac8f7f06cca68aba88508ddfde3a6a34feb1678ad1694b4f88
ARG HELM_DIFF_SHA256_AMD64=c004219c405e5be665e0b573378cf07f0182f2da7466a4c5a580a3c7162e7ae8
ARG HELM_DIFF_SHA256_ARM64=b8a4d992eea22fad9edcadcbc457b894a3c8f441f420bd5433bfd9362ee7c10e
ARG HELMFILE_SHA256_AMD64=ccabbe75dddbc25008d055fe92a44f95a184342211e7244d32b870409239c7a3
ARG HELMFILE_SHA256_ARM64=2217788de9fb42cd0b3d84f1ee99c63617e19dea7af4995a59e45e4952c86ec4
ARG AWSCLI_SHA256_AMD64=6b3a6a3d7bb3997928f0bdf7b866914224abf242c2e54e1dcebbe84bee64f356
ARG AWSCLI_SHA256_ARM64=e7d2cca3622af4765871fe9ce7eeed03acd09dca10a99ebc46e92f79d78765c0
ARG SOPS_SHA256_AMD64=e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b
ARG SOPS_SHA256_ARM64=53b0abacd38ef1b12a66d6c100956691b9cefce018d91f81e73ddf7438b94d77
ARG AGE_SHA256_AMD64=cbe24006683f8eb669266162894b9a522a1af52f2665fbc63a4bb032ed26ac10
ARG AGE_SHA256_ARM64=6b8dc4333c53a5a57c9e5834e3a48f92605d7154014cd07269ff3327db5d37f4
ARG CRANE_SHA256_AMD64=0ab7a1d6932a213aed964ce97666c3077fe691c8606413674a8b3e0b9ec4cda0
ARG CRANE_SHA256_ARM64=898c0cff975f898a33e8c4580bdafb0e7c02c7faa33374e946762f97c4ab7110
ARG YQ_SHA256_AMD64=c5f056448f973ae7d39b5401949648a78f2dc1947d6a8eb65be60d5c504b9385
ARG YQ_SHA256_ARM64=88a1016bc1d657375a35864e4f44b6f333df8ff97b559f51bba0adcb2169df09
ARG TASK_SHA256_AMD64=a54a408f6861ff921f6e87774180db31bacd8c1e7c944ca696db9fea49a82fc7
ARG TASK_SHA256_ARM64=e3ad19101493a0112e1f22ae8ccc54bf03e533b1076a0ca1e6c782a09ad2e588
# AWS CLI service models to keep (local/lab.sh needs ec2, eks, iam, sts; the rest are for operators).
# Empty keeps all of them.
ARG AWSCLI_SERVICES="ec2 eks iam sts s3 secretsmanager ssm kms sso sso-oidc signin ecr elbv2 route53 dynamodb cloudformation logs"
# Go binaries are not packed: a packed binary unpacks itself into private memory at every start, which costs about
# 2 s and 300 MB per atmos call.

# Build platform: Go binaries for TARGETARCH, with cross binutils for strip.
FROM --platform=$BUILDPLATFORM ubuntu:24.04@sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8 AS gobase
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
      binutils-x86-64-linux-gnu binutils-aarch64-linux-gnu \
 && rm -rf /var/lib/apt/lists/*
# fetch URL FILE SHA256_AMD64 SHA256_ARM64: download URL to FILE and check the hash for TARGETARCH.
RUN printf '%s\n' '#!/bin/sh' 'set -eu' \
      'case "$TARGETARCH" in amd64) h=$3 ;; arm64) h=$4 ;; *) echo "No sha256 for $TARGETARCH" >&2; exit 1 ;; esac' \
      'curl -fsSL --retry 3 -o "$2" "$1"' 'echo "$h  $2" | sha256sum -c --quiet -' \
      >/usr/local/bin/fetch \
 && chmod 755 /usr/local/bin/fetch
# strip-check FILE [ARGS...]: strip a Go binary for TARGETARCH, then check that `FILE ARGS` still runs (through binfmt
# emulation when TARGETARCH is foreign).
RUN printf '%s\n' '#!/bin/sh' 'set -eu' 'f=$1; shift' 'chmod 755 "$f"' \
      'case "$TARGETARCH" in amd64) x86_64-linux-gnu-strip "$f" ;; arm64) aarch64-linux-gnu-strip "$f" ;; esac' \
      'cd / && "$f" "$@" >/dev/null' \
      >/usr/local/bin/strip-check \
 && chmod 755 /usr/local/bin/strip-check \
 && mkdir /out
WORKDIR /tmp

# Target platform: the AWS CLI installer and pip run the target's own binaries.
FROM ubuntu:24.04@sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8 AS base
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip binutils python3-venv \
 && rm -rf /var/lib/apt/lists/*
COPY --from=gobase /usr/local/bin/fetch /usr/local/bin/fetch
WORKDIR /tmp

FROM gobase AS atmos
ARG ATMOS_VERSION ATMOS_SHA256_AMD64 ATMOS_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/cloudposse/atmos/releases/download/v${ATMOS_VERSION}/atmos_${ATMOS_VERSION}_linux_${TARGETARCH}" /out/atmos \
      "$ATMOS_SHA256_AMD64" "$ATMOS_SHA256_ARM64" \
 && strip-check /out/atmos version

FROM gobase AS kubectl
ARG KUBECTL_VERSION KUBECTL_SHA256_AMD64 KUBECTL_SHA256_ARM64 TARGETARCH
RUN fetch "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" /out/kubectl \
      "$KUBECTL_SHA256_AMD64" "$KUBECTL_SHA256_ARM64" \
 && strip-check /out/kubectl version --client

FROM gobase AS tofu
ARG TOFU_VERSION TOFU_SHA256_AMD64 TOFU_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${TARGETARCH}.zip" tofu.zip \
      "$TOFU_SHA256_AMD64" "$TOFU_SHA256_ARM64" \
 && unzip -q tofu.zip tofu -d /out && rm tofu.zip \
 && strip-check /out/tofu version

FROM gobase AS helm
ARG HELM_VERSION HELM_DIFF_VERSION HELM_SHA256_AMD64 HELM_SHA256_ARM64 HELM_DIFF_SHA256_AMD64 HELM_DIFF_SHA256_ARM64 TARGETARCH
# Plugins outside HOME (HELM_PLUGINS in the final image), so any user finds helm-diff.
RUN fetch "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" helm.tgz "$HELM_SHA256_AMD64" "$HELM_SHA256_ARM64" \
 && tar -xzf helm.tgz --strip-components=1 -C /out "linux-${TARGETARCH}/helm" \
 && fetch "https://github.com/databus23/helm-diff/releases/download/v${HELM_DIFF_VERSION}/helm-diff-linux-${TARGETARCH}.tgz" diff.tgz \
      "$HELM_DIFF_SHA256_AMD64" "$HELM_DIFF_SHA256_ARM64" \
 && mkdir -p /plugins && tar -xzf diff.tgz -C /plugins && mv /plugins/diff /plugins/helm-diff && rm -f ./*.tgz \
 && chmod -R a+rX /plugins \
 && strip-check /out/helm version \
 && PATH=/out:$PATH strip-check /plugins/helm-diff/bin/diff version

FROM gobase AS helmfile
ARG HELMFILE_VERSION HELMFILE_SHA256_AMD64 HELMFILE_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${TARGETARCH}.tar.gz" helmfile.tgz \
      "$HELMFILE_SHA256_AMD64" "$HELMFILE_SHA256_ARM64" \
 && tar -xzf helmfile.tgz -C /out helmfile && rm helmfile.tgz \
 && strip-check /out/helmfile --version

FROM gobase AS sops
ARG SOPS_VERSION SOPS_SHA256_AMD64 SOPS_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${TARGETARCH}" /out/sops \
      "$SOPS_SHA256_AMD64" "$SOPS_SHA256_ARM64" \
 && strip-check /out/sops --version

FROM gobase AS age
ARG AGE_VERSION AGE_SHA256_AMD64 AGE_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${TARGETARCH}.tar.gz" age.tgz \
      "$AGE_SHA256_AMD64" "$AGE_SHA256_ARM64" \
 && tar -xzf age.tgz --strip-components=1 -C /out age/age age/age-keygen && rm age.tgz \
 && strip-check /out/age --version && strip-check /out/age-keygen --version

FROM gobase AS crane
ARG CRANE_VERSION CRANE_SHA256_AMD64 CRANE_SHA256_ARM64 TARGETARCH
RUN arch=$(case "$TARGETARCH" in amd64) echo x86_64 ;; *) echo "$TARGETARCH" ;; esac) \
 && fetch "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_${arch}.tar.gz" crane.tgz \
      "$CRANE_SHA256_AMD64" "$CRANE_SHA256_ARM64" \
 && tar -xzf crane.tgz -C /out crane && rm crane.tgz \
 && strip-check /out/crane version

FROM gobase AS yq
ARG YQ_VERSION YQ_SHA256_AMD64 YQ_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" /out/yq \
      "$YQ_SHA256_AMD64" "$YQ_SHA256_ARM64" \
 && strip-check /out/yq --version

FROM gobase AS task
ARG TASK_VERSION TASK_SHA256_AMD64 TASK_SHA256_ARM64 TARGETARCH
RUN fetch "https://github.com/go-task/task/releases/download/v${TASK_VERSION}/task_linux_${TARGETARCH}.tar.gz" task.tgz \
      "$TASK_SHA256_AMD64" "$TASK_SHA256_ARM64" \
 && tar -xzf task.tgz -C /out task && rm task.tgz \
 && strip-check /out/task --version

# AWS CLI v2 is the largest non-Go part: drop examples, the auto-prompt index, the completer, unused service models
# and the bundled Python's test modules, and strip its shared libraries.
FROM base AS awscli
ARG AWSCLI_VERSION AWSCLI_SERVICES AWSCLI_SHA256_AMD64 AWSCLI_SHA256_ARM64 TARGETARCH
RUN set -eux; arch=$(case "$TARGETARCH" in amd64) echo x86_64 ;; arm64) echo aarch64 ;; esac) \
 && fetch "https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWSCLI_VERSION}.zip" aws.zip "$AWSCLI_SHA256_AMD64" "$AWSCLI_SHA256_ARM64" \
 && unzip -q aws.zip && ./aws/install \
 && dist=/usr/local/aws-cli/v2/${AWSCLI_VERSION}/dist && test -d "$dist/awscli/botocore/data" \
 && rm -rf "$dist/awscli/examples" "$dist/awscli/data/ac.index" "$dist/aws_completer" /usr/local/bin/aws_completer \
           "$dist"/python3*/lib-dynload/_test* "$dist"/python3*/lib-dynload/_xxtestfuzz* "$dist"/python3*/lib-dynload/_ctypes_test* \
 && if [ -n "$AWSCLI_SERVICES" ]; then \
      for d in "$dist"/awscli/botocore/data/*/; do \
        case " $AWSCLI_SERVICES " in *" $(basename "$d") "*) ;; *) rm -rf "$d" ;; esac; \
      done; \
    fi \
 && find "$dist" -type f \( -name '*.so' -o -name '*.so.*' \) -exec strip --strip-unneeded {} + \
 && find /usr/local/aws-cli -name __pycache__ -type d -prune -exec rm -rf {} + \
 && aws --version \
 && aws sts get-caller-identity --generate-cli-skeleton >/dev/null \
 && aws ec2 describe-instances --generate-cli-skeleton >/dev/null \
 && aws eks describe-cluster --generate-cli-skeleton >/dev/null \
 && rm -rf /tmp/*

# Kubemarine installs Kubernetes on <cloud>/vms through the jump host; a venv keeps its pinned dependencies apart.
# The final stage runs the venv on the same base image's python3, so python3-venv and pip stay here.
FROM base AS kubemarine
ARG KUBEMARINE_VERSION
RUN python3 -m venv /opt/kubemarine \
 && /opt/kubemarine/bin/pip install --no-cache-dir --no-compile "kubemarine==${KUBEMARINE_VERSION}" \
 && /opt/kubemarine/bin/pip uninstall -y -q pip \
 && sp=$(echo /opt/kubemarine/lib/python3*/site-packages) \
 && find "$sp" -depth -type d \( -name tests -o -name test -o -name __pycache__ \) -exec rm -rf {} + \
 && find /opt/kubemarine -type f -name '*.so*' -exec strip --strip-unneeded {} + \
 && /opt/kubemarine/bin/python -c 'import kubemarine, cryptography.hazmat.bindings._rust, nacl.bindings, bcrypt, paramiko' \
 && find /opt/kubemarine -name __pycache__ -type d -prune -exec rm -rf {} +

FROM ubuntu:24.04@sha256:73b999393d07f2bf65a40373778a44dc9a6d54ad7718d29247d8ff9413c4d6a8 AS rootfs
# dpkg skips docs, man pages and translations, so the packages never write them.
# gpg + gpg-agent are what sops needs; the gnupg meta-package would add dirmngr, gpgsm, keyboxd and LDAP libraries.
# perl (~50 MB, needed by git only for rare commands) is replaced by empty packages of the same names and versions.
# Before installing a package that needs perl: `apt-get install --reinstall perl liberror-perl git-man`.
RUN set -eux \
 && printf '%s\n' 'path-exclude=/usr/share/doc/*' 'path-include=/usr/share/doc/*/copyright' \
      'path-exclude=/usr/share/man/*' 'path-exclude=/usr/share/info/*' 'path-exclude=/usr/share/lintian/*' \
      'path-exclude=/usr/share/locale/*' 'path-include=/usr/share/locale/locale.alias' \
      > /etc/dpkg/dpkg.cfg.d/01-slim \
 && apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git jq less openssh-client python3 gpg gpg-agent \
 && placeholders="git-man liberror-perl perl" \
 && for p in $placeholders; do echo "$p $(dpkg-query -Wf '${Version}' "$p")"; done >/tmp/versions \
 && dpkg --purge --force-depends $placeholders perl-modules-5.38 libperl5.38t64 \
 && while read -r p v; do \
      mkdir -p "/tmp/$p/DEBIAN" \
      && printf 'Package: %s\nVersion: %s\nArchitecture: all\nMaintainer: qcm-tools\nDescription: placeholder (removed to keep the image small)\n' \
           "$p" "$v" >"/tmp/$p/DEBIAN/control" \
      && dpkg-deb -b "/tmp/$p" "/tmp/$p.deb" >/dev/null; \
    done </tmp/versions \
 && dpkg -i /tmp/*.deb >/dev/null && rm -rf /tmp/* \
 && apt-get check -qq \
 && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/cache/debconf/*-old /var/lib/dpkg/*-old /var/log/* \
           /usr/share/doc/* /usr/share/man/* /usr/share/info/* \
           /usr/lib/python3*/test /usr/lib/python3*/pydoc_data /usr/lib/python3*/idlelib /usr/lib/python3*/lib2to3 \
           /usr/lib/python3*/turtledemo /usr/lib/python3*/tkinter /usr/lib/python3*/ensurepip \
 && find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name locale.alias -exec rm -rf {} + \
 && find / -xdev -name __pycache__ -type d -prune -exec rm -rf {} +

COPY --from=atmos /out/ /usr/local/bin/
COPY --from=kubectl /out/ /usr/local/bin/
COPY --from=tofu /out/ /usr/local/bin/
COPY --from=helm /out/ /usr/local/bin/
COPY --from=helm /plugins/ /usr/local/share/helm/plugins/
COPY --from=helmfile /out/ /usr/local/bin/
COPY --from=sops /out/ /usr/local/bin/
COPY --from=age /out/ /usr/local/bin/
COPY --from=crane /out/ /usr/local/bin/
COPY --from=yq /out/ /usr/local/bin/
COPY --from=task /out/ /usr/local/bin/
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=kubemarine /opt/kubemarine/ /opt/kubemarine/
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws \
 && ln -s /opt/kubemarine/bin/kubemarine /opt/kubemarine/bin/_kubemarine /usr/local/bin/ \
 && groupadd -g 65532 nonroot && useradd -u 65532 -g 65532 -M -d /home/nonroot -s /bin/bash nonroot \
 && mkdir -p /workspace /home/nonroot && chown 65532:65532 /workspace /home/nonroot \
 && git --version && python3 -c 'import ssl, json' && gpg --version >/dev/null \
 && aws --version >/dev/null && /opt/kubemarine/bin/python -c 'import kubemarine, paramiko'

FROM scratch
COPY --from=rootfs / /
# The image keeps no .pyc files; stop python writing them into containers.
# Default user: nonroot (65532); compose runs the tools container as the calling user. A derived image that installs
# packages starts with `USER root`. Helm plugins live outside HOME, so any uid can use them.
# atmos checks GitHub for a newer release on every call (~2.5 s); its version is pinned here, so the check is off.
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    PYTHONDONTWRITEBYTECODE=1 \
    HELM_PLUGINS=/usr/local/share/helm/plugins \
    ATMOS_VERSION_CHECK_ENABLED=false
USER 65532:65532
WORKDIR /workspace
CMD ["bash"]
