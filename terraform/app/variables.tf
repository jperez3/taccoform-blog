variable "env" {

    description = "unique environment name"
    default     = "prod"
}

variable "service" {
    description = "unique service name"
    default     = "burrito"
}

variable "do_token" {
  description = "Digital Ocean auth token"
}

variable "region" {
  description = "DigitalOcean region"
  default     = "sfo2"
}