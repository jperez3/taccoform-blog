terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "ordisius"

    workspaces {
      name = "taccoform-tutorial-app"
    }
  }
}


terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = "~> 0.14.0"
}


provider "digitalocean" {
  token = var.do_token

  spaces_access_id  = var.do_access_id
  spaces_secret_key = var.do_secret_key
}
