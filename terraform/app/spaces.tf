resource "digitalocean_spaces_bucket" "taccoform-blog" {
  name   = "taccoform-blog"
  region = var.region
  acl = "public-read"

}