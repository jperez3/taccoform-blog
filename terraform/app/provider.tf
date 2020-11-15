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
      source = "digitalocean/digitalocean"
      version = "~> 1.22.2"
    }
  }
  required_version = ">= 0.13"
}


provider "digitalocean" {
  token = var.do_token

  spaces_access_id  = var.do_access_id
  spaces_secret_key = var.do_secret_key  
}