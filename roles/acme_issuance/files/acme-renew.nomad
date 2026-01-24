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

  group "acme-renew" {
    task "acme-sh-cron" {
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

    task "signal-nginx" {
      driver = "exec"

      lifecycle {
        hook = "poststop"
      }

      identity {
        env = true
      }

      config {
        command = "/bin/bash"
        args = [
          "-euxo",
          "pipefail",
          "-c",
<<EOF
cd ${NOMAD_TASK_DIR}
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output jq-linux64 https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output sha256sum.txt https://raw.githubusercontent.com/jqlang/jq/master/sig/v1.6/sha256sum.txt
grep jq-linux64 sha256sum.txt | sha256sum --status --warn --strict --check
mv jq-linux64 jq
chmod +x jq

curl --silent --unix-socket ${NOMAD_SECRETS_DIR}/api.sock --header 'X-Nomad-Token: ${NOMAD_TOKEN}' http://localhost/v1/client/allocation/$(curl --silent --unix-socket ${NOMAD_SECRETS_DIR}/api.sock --header 'X-Nomad-Token: ${NOMAD_TOKEN}' http://localhost/v1/job/nginx/allocations | ./jq -r '.[0].ID')/signal --request POST --data '{"Signal": "SIGHUP", "Task": "nginx"}' || true
EOF
        ]
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }
    }
  }
}
