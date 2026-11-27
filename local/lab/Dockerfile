# Lab sidecar: the Docker side of local/lab.sh (k3s node repair, published ports) behind a small HTTP API,
# so the tools container needs no Docker CLI or socket. local/compose*.yml start it next to Floci.
FROM docker:28.5.2-cli@sha256:625d9431a9f54c5a2bc90f24f0e1c3d55b1349fd857dd85035f98c2c9acbdd4d AS docker

FROM alpine:3.22@sha256:49340b346798875b5592e5d420241f2f9cfba5f47e62ebb1446a1b34734e898f
RUN apk add --no-cache bash jq busybox-extras
COPY --from=docker /usr/local/bin/docker /usr/local/bin/docker
COPY --chmod=755 lab-api.sh /srv/cgi-bin/lab
# Host network in local/compose*.yml: listen on loopback only, on LAB_PORT.
ENV LAB_PORT=8080
# Not root; local/compose*.yml run it as the user of the checkout (to read the 0600 token) with group_add of the Docker
# socket's group (QCM_LAB_DOCKER_GID, computed by local/lab-env.sh).
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=3s --retries=6 CMD wget -qO- "http://127.0.0.1:${LAB_PORT}/cgi-bin/lab?op=ping" >/dev/null
CMD exec busybox-extras httpd -f -p "127.0.0.1:${LAB_PORT}" -h /srv
