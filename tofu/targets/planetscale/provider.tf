# The service token comes from PLANETSCALE_SERVICE_TOKEN_ID and
# PLANETSCALE_SERVICE_TOKEN. See scripts/tofu-env.sh.
provider "planetscale" {}

# OpenTofu makes the databases inside the branch with its own role. See
# databases.tf. The password of the role stays in the encrypted state.
provider "postgresql" {
  host            = local.host
  port            = 5432
  database        = "postgres"
  username        = planetscale_postgres_branch_role.tofu.username
  password        = planetscale_postgres_branch_role.tofu.password
  sslmode         = "verify-full"
  superuser       = false
  connect_timeout = 15
}
