variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

variable "acme-server" {
  type = string
  description = "The ACME service to use when renewing certificates"
}

job "acme-renew" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  periodic {
    cron = "0 8 * * *"
    prohibit_overlap = true
  }

  group "acme-sh" {
    task "acme-sh" {
      config {
        image = "neilpang/acme.sh"
        args = [
          "--cron",
        ]

        force_pull = true

        network_mode = "host"

        mount {
          type = "volume"
          target = "/acme.sh/"
          source = "acme-account-${var.acme-server}"
          readonly = false

          volume_options {
            no_copy = true
          }
        }

        mount {
          type = "volume"
          target = "/certificate/"
          source = "acme-certificate-${var.acme-server}"
          readonly = false

          volume_options {
            no_copy = true
          }
        }
      }

      driver = "docker"

      resources {
        cpu = 1000
        memory = 512
        memory_max = 2048
      }
    }
  }
}
