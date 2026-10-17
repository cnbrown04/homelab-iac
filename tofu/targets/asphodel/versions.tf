terraform {
  required_providers {
    planetscale = {
      source  = "planetscale/planetscale"
      version = "1.14.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.27.0"
    }
  }
}
