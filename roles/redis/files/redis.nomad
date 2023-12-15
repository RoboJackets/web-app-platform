variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "redis" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "redis" {
    volume "run" {
      type = "host"
      source = "run"
    }

    network {
      port "resp" {}
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis"

        args = [
          "/usr/local/etc/redis/redis.conf"
        ]

        force_pull = true

        network_mode = "host"

        mount {
          type   = "bind"
          source = "secrets/"
          target = "/usr/local/etc/redis/"
        }
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 2048
      }

      volume_mount {
        volume = "run"
        destination = "/var/opt/nomad/run/"
      }

      template {
        data = <<EOH
bind 0.0.0.0
port {{ env "NOMAD_PORT_resp" }}
unixsocket /var/opt/nomad/run/{{ env "NOMAD_JOB_NAME" }}-{{ env "NOMAD_ALLOC_ID" }}.sock
unixsocketperm 777
requirepass {{ key "redis/password" }}
maxmemory {{ env "NOMAD_MEMORY_LIMIT" }}mb
maxmemory-policy allkeys-lru
EOH

        destination = "secrets/redis.conf"
      }

      service {
        name = "redis"

        port = "resp"

        tags = [
          "resp"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "5s"

          name = "TCP"
          port = "resp"
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
