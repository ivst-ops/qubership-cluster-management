# Image of `task docs:generate` and `task docs:check` (compose.lint.yml): terraform-docs and yq, nothing else.
# Both pinned by tag and digest; Dependabot updates the digests. The yq version must stay equal to YQ_VERSION of the
# root Dockerfile (the tools image); `task docs:check` fails when they differ.
FROM quay.io/terraform-docs/terraform-docs:0.25.1@sha256:7b2a74a2b9a9e6af41200335da47b73a64c39a0edd5afb91bc921f0a77eae681 AS terraform-docs

FROM mikefarah/yq:4.53.6@sha256:cfc4eee658595834ef304eadb0c3ea721f3b7cb6404ad8b7cb909cc5b5145b23
COPY --from=terraform-docs /usr/local/bin/terraform-docs /usr/local/bin/terraform-docs
USER 1000:1000
ENTRYPOINT []
