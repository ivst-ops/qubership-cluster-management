# Representative inputs for `task lint:trivy` (trivy config --tf-vars): the authorized networks come from admin_cidrs.
# Values as in stacks/customers/customer1/gcp/staging.yaml.example.
environment = "t-s"
region      = "europe-west3"
project_id  = "p"
location    = "europe-west3-a"
vpc_id      = "projects/p/global/networks/vpc"
subnet_id   = "projects/p/regions/europe-west3/subnetworks/main"
admin_cidrs = ["203.0.113.10/32"]
