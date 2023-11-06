variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

variable "version" {
  type = string
  description = "The version of Meilisearch to run"
}

job "meilisearch" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "meilisearch" {
    network {
      port "http" {}
    }

    task "meilisearch" {
      driver = "docker"

      config {
        image = "getmeili/meilisearch:v${var.version}"

        args = [
          "/bin/meilisearch",
          "--db-path",
          "/meilisearch_data/",
          "--http-addr",
          "127.0.0.1:${NOMAD_PORT_http}",
          "--env",
          "production",
          "--max-indexing-memory",
          "4Gb",
          "--http-payload-size-limit",
          "100Mb",
        ]

        force_pull = true

        network_mode = "host"

        mount {
          type = "volume"
          target = "/meilisearch_data/"
          source = "${NOMAD_JOB_NAME}"
          readonly = false

          volume_options {
            no_copy = true
          }
        }
      }

      resources {
        cpu = 100
        memory = 256
        memory_max = 8096
      }

      template {
        data = <<EOF
MEILI_MASTER_KEY="{{- key "meilisearch/master-key" | trimSpace -}}"
EOF

        destination = "/secrets/.env"
        env = true
      }

      service {
        name = "${NOMAD_JOB_NAME}"

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
          path = "/health"
          port = "http"
          protocol = "http"
          timeout = "1s"
          type = "http"
        }

        check_restart {
          limit = 5
          grace = "20s"
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
