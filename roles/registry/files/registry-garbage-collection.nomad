variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "registry-garbage-collection" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  periodic {
    cron = "0 6 * * *"
    prohibit_overlap = true
  }

  group "registry-garbage-collection" {
    task "registry-garbage-collection" {
      driver = "docker"

      config {
        image = "registry"

        force_pull = true

        network_mode = "host"

        entrypoint = [
          "/bin/registry",
          "garbage-collect",
          "--delete-untagged=true",
          "/etc/docker/registry/config.yml",
        ]

        mount {
          type   = "bind"
          source = "secrets/"
          target = "/etc/docker/registry/"
        }

        mount {
          type = "volume"
          target = "/registry/"
          source = "registry"
          readonly = false

          volume_options {
            no_copy = true
          }
        }
      }

      resources {
        cpu = 1000
        memory = 512
        memory_max = 2048
      }

      template {
        data = <<EOH
---
version: 0.1

storage:
  filesystem:
    rootdirectory: /registry
  cache:
    blobdescriptor: inmemory
EOH

        destination = "secrets/config.yml"
      }
    }
  }
}
