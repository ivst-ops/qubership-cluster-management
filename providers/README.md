# Provider adapters

Provider-specific OpenTofu modules: `providers/<cloud>/modules/<module>/`, called by the root
components in `components/terraform/` with a relative `source`. Every module has `versions.tf`, its own tests
(`tests/*.tftest.hcl`, run by `task test`) and passes `task lint`, including `lint:leaks`.
