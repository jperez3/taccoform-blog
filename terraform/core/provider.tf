terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "ordisius"

    workspaces {
      name = "taccoform-tutorial-core"
    }
  }
}


terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0.0"
    }
  }
  required_version = ">= 0.13"
}


provider "digitalocean" {
  token = var.do_token
}