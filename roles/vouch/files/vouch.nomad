variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "vouch" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "vouch" {
    network {
      port "http" {}
    }

    task "vouch" {
      driver = "docker"

      config {
        image = "quay.io/vouch/vouch-proxy"

        force_pull = true

        network_mode = "host"
      }

      template {
        data = <<EOH
{{- range $key, $value := (key "vouch" | parseJSON) -}}
{{- $key | trimSpace -}}={{- $value | toJSON }}
{{ end -}}
VOUCH_PORT={{ env "NOMAD_PORT_http" }}
VOUCH_LISTEN=127.0.0.1
EOH

        destination = "/secrets/.env"
        env = true
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 2048
      }

      service {
        name = "vouch"

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
          path = "/healthcheck"
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
          nginx-config = "location / {proxy_pass http://vouch;proxy_set_header Host $http_host;} location /static/ {proxy_pass http://vouch;proxy_pass_request_headers off;proxy_pass_request_body off;proxy_cache vouch_assets;proxy_cache_valid 24h;add_header X-Cache-Status $upstream_cache_status;}"
          firewall-rules = jsonencode(["internet"])
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
