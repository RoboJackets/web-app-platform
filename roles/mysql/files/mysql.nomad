variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "mysql" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "mysql" {
    volume "run" {
      type = "host"
      source = "run"
    }

    network {
      port "mysql" {
        static = 3306
      }
    }

    task "mysql" {
      driver = "docker"

      config {
        image = "mysql"

        args = [
          "--socket=/var/opt/nomad/run/${NOMAD_JOB_NAME}-${NOMAD_ALLOC_ID}.sock"
        ]

        force_pull = true

        network_mode = "host"

        cap_add = ["sys_nice"]

        mount {
          type = "volume"
          target = "/var/lib/mysql/"
          source = "mysql"
          readonly = false

          volume_options {
            no_copy = true
          }
        }
      }

      template {
        data = <<EOF
{{- key "mysql/root_password" -}}
EOF

        destination = "/secrets/root_password"
      }

      env {
        MYSQL_ROOT_PASSWORD_FILE = "${NOMAD_SECRETS_DIR}/root_password"
      }

      resources {
        cpu = 100
        memory = 1024
        memory_max = 2048
      }

      volume_mount {
        volume = "run"
        destination = "/var/opt/nomad/run"
      }

      service {
        name = "mysql"

        port = "mysql"

        address = "127.0.0.1"

        tags = [
          "mysql"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "5s"

          name = "TCP"
          port = "mysql"
          timeout = "1s"
          type = "tcp"
        }

        check_restart {
          limit = 5
          grace = "20s"
        }

        meta {
          socket = "/var/opt/nomad/run/${NOMAD_JOB_NAME}-${NOMAD_ALLOC_ID}.sock"
        }
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
