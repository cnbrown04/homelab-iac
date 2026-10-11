# The PlanetScale Postgres of the apps. One database and one role for each
# app. To add an app, add one entry to local.apps. Do not write a new resource
# block.
locals {
  # The slugs from the PlanetScale dashboard.
  organization = "CHANGE-ME"
  database     = "CHANGE-ME"
  branch       = "main"
  host         = "us-east-5.pg.psdb.cloud"

  # One entry for each app. The key is the name of the database and of the
  # role.
  apps = {
  }
}

resource "planetscale_postgres_branch" "main" {
  organization       = local.organization
  database           = local.database
  name               = local.branch
  deletion_protected = true
  delete_descendants = false
}

# The role of OpenTofu. The postgresql provider uses it to make the databases.
resource "planetscale_postgres_branch_role" "tofu" {
  organization    = local.organization
  database        = local.database
  branch          = planetscale_postgres_branch.main.name
  name            = "tofu"
  inherited_roles = ["postgres"]
}

# The role of each app. The password is in the state only after the create.
# Copy it to the SOPS file of the app, then the app uses it.
resource "planetscale_postgres_branch_role" "app" {
  for_each = local.apps

  organization = local.organization
  database     = local.database
  branch       = planetscale_postgres_branch.main.name
  name         = each.key
}

resource "postgresql_database" "app" {
  for_each = local.apps

  name  = each.key
  owner = planetscale_postgres_branch_role.app[each.key].base_username
  # A database of PlanetScale can have connections from other roles. A drop
  # by mistake loses the data of an app.
  lifecycle {
    prevent_destroy = true
  }
}

# Each app connects to its own database only.
resource "postgresql_grant" "app_connect" {
  for_each = local.apps

  database    = postgresql_database.app[each.key].name
  role        = "public"
  object_type = "database"
  privileges  = []
}

output "app_passwords" {
  description = "The password of each app role. Run: tofu output -json app_passwords"
  value       = { for name, role in planetscale_postgres_branch_role.app : name => role.password }
  sensitive   = true
}
