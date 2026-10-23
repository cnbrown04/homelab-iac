# The service token comes from PLANETSCALE_SERVICE_TOKEN_ID and
# PLANETSCALE_SERVICE_TOKEN. See scripts/tofu-env.sh.
provider "planetscale" {}

# OpenTofu makes the databases inside the branch with its own role. See
# databases.tf. The password of the role stays in the encrypted state.
provider "postgresql" {
  host     = local.host
  port     = 5432
  database = "postgres"
  username = planetscale_postgres_branch_role.tofu.username
  password = planetscale_postgres_branch_role.tofu.password
  # The login name has the routing suffix of the branch. A GRANT of the
  # provider needs the name of the role, with no suffix.
  database_username = planetscale_postgres_branch_role.tofu.base_username
  sslmode           = "verify-full"
  superuser         = false
  connect_timeout   = 15
}
