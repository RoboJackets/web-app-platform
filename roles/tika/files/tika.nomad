variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "tika" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "tika" {
    network {
      port "http" {}
    }

    task "tika" {
      driver = "docker"

      config {
        image = "apache/tika:latest-full"

        force_pull = true

        network_mode = "host"

        args = [
          "--host=127.0.0.1",
          "--port=${NOMAD_PORT_http}"
        ]
      }

      env {
        JAVA_OPTS = "-Xms2048M -Xmx4096M -XX:MaxDirectMemorySize=256M"
      }

      resources {
        cpu = 1000
        memory = 2048
        memory_max = 4096
      }

      service {
        name = "tika"

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
          path = "/tika"
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
