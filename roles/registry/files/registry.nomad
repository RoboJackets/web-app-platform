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

      consul {}

      config {
        image = "registry"

        force_pull = true

        network_mode = "host"

        mount {
          type   = "bind"
          source = "secrets/"
          target = "/etc/distribution/"
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

http:
  addr: 127.0.0.1:{{ env "NOMAD_PORT_http" }}
  net: tcp
  host: registry.${var.datacenter}.robojackets.net

auth:
  htpasswd:
    realm: registry.${var.datacenter}.robojackets.net
    path: /etc/distribution/htpasswd
EOH

        destination = "secrets/config.yml"
      }

      template {
        data = <<EOH
{{- key "registry/htpasswd" | trimSpace -}}
EOH

        destination = "secrets/htpasswd"
      }

      env {
        OTEL_TRACES_EXPORTER = "none"
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

          interval = "1s"

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
          nginx-config = "client_max_body_size 0;proxy_request_buffering off;proxy_buffering off;location / {proxy_pass http://registry;proxy_set_header Host $http_host;proxy_set_header X-Real-IP $remote_addr;proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;proxy_set_header X-Forwarded-Proto $scheme;proxy_read_timeout 900;}"
          firewall-rules = jsonencode(["local", "uptime-robot", "github-actions"])
        }
      }

      restart {
        attempts = 5
        delay = "10s"
        interval = "1m"
        mode = "fail"
      }
    }
  }

  reschedule {
    delay = "10s"
    delay_function = "fibonacci"
    max_delay = "60s"
    unlimited = true
  }

  update {
    max_parallel = 0
  }
}
