data "digitalocean_ssh_key" "root" {
  name = "taccoform-tutorial"
}

resource "digitalocean_droplet" "web" {
  count     = var.droplet_count
  image     = var.droplet_image
  name      = "${var.droplet_name}${count.index}-${var.service}-${var.env}"
  region    = var.region
  size      = var.droplet_size
  ssh_keys  = [data.digitalocean_ssh_key.root.id]
  user_data = templatefile("${path.module}/templates/user_data_docker.yaml", { hostname = "${var.droplet_name}${count.index}-${var.service}-${var.env}" })

  lifecycle {
    create_before_destroy = true
  }

}

output "droplet_public_ip" {
  value = digitalocean_droplet.web.*.ipv4_address
}