variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "registry" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "registry" {
    network {
      port "http" {}
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry"

        force_pull = true

        network_mode = "host"

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
        cpu = 100
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

http:
  addr: 127.0.0.1:{{ env "NOMAD_PORT_http" }}
  net: tcp
  host: registry.${var.datacenter}.robojackets.net

auth:
  htpasswd:
    realm: registry.${var.datacenter}.robojackets.net
    path: /etc/docker/registry/htpasswd
EOH

        destination = "secrets/config.yml"
      }

      template {
        data = <<EOH
{{- key "registry/htpasswd" | trimSpace -}}
EOH

        destination = "secrets/htpasswd"
      }

      service {
        name = "registry"

        port = "http"

        address = "127.0.0.1"

        tags = [
          "http"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "5s"

          name = "HTTP"
          path = "/"
          port = "http"
          protocol = "http"
          timeout = "1s"
          type = "http"
        }

        check_restart {
          limit = 5
          grace = "20s"
        }

        meta {
          nginx-config = "client_max_body_size 0;location / {proxy_pass http://registry;proxy_set_header Host $http_host;proxy_set_header X-Real-IP $remote_addr;proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;proxy_set_header X-Forwarded-Proto $scheme;proxy_read_timeout 900;}"
          firewall-rules = jsonencode(["aws", "local", "uptime-robot", "internet"])
        }
      }

      restart {
        attempts = 1
        delay = "10s"
        interval = "1m"
        mode = "fail"
      }
    }

    reschedule {
      attempts  = 0
      unlimited = false
    }
  }

  update {
    max_parallel = 0
  }
}
