variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "backup" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  periodic {
    cron = "0 7 * * *"
    prohibit_overlap = true
  }

  group "backup" {
    volume "run" {
      type = "host"
      source = "run"
    }

    task "dump-mysql-databases" {
      driver = "docker"

      consul {}

      config {
        image = "mysql"

        entrypoint = [
          "/bin/bash",
          "-xeuo",
          "pipefail",
          "-c",
          "/local/script.sh"
        ]

        force_pull = true

        network_mode = "none"
      }

      env {
        HOME = "${NOMAD_SECRETS_DIR}/"
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
        data = <<EOF
[client]
host=localhost
user=root
password={{- key "mysql/root_password" | trimSpace }}
{{- range service "mysql" }}
socket={{- index .ServiceMeta "socket" | trimSpace }}
{{ end }}
EOF

        destination = "${NOMAD_SECRETS_DIR}/.my.cnf"

        change_mode = "noop"
      }

      template {
        data = <<EOF
set -o pipefail
set -eux

mysqldump {{ with (key "backup/config" | parseJSON) -}}{{- index . "MYSQLDUMP_SCOPE" -}}{{- end }} | xz --compress --extreme --threads=0 --verbose --verbose > ${NOMAD_ALLOC_DIR}/data/database.sql.xz
EOF

        destination = "${NOMAD_TASK_DIR}/script.sh"

        perms = "777"

        change_mode = "noop"
      }
    }

    task "snapshot-hashistack" {
      driver = "exec"

      consul {}

      config {
        command = "/bin/bash"
        args = [
          "-euxo",
          "pipefail",
          "-c",
<<EOF
nomad operator snapshot save ${NOMAD_ALLOC_DIR}/data/nomad.snapshot
consul snapshot save ${NOMAD_ALLOC_DIR}/data/consul.snapshot
EOF
        ]
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }

      volume_mount {
        volume = "run"
        destination = "/var/opt/nomad/run/"
      }

      template {
        data = <<EOF
CONSUL_HTTP_ADDR="unix:///var/opt/nomad/run/consul.sock"
CONSUL_HTTP_TOKEN="{{- key "consul/token" | trimSpace -}}"
NOMAD_TOKEN="{{- key "nomad/token" | trimSpace -}}"
EOF

        destination = "${NOMAD_SECRETS_DIR}/.env"
        env = true
      }
    }

    task "compress-docker-volumes" {
      driver = "raw_exec"

      consul {}

      config {
        command = "/bin/bash"
        args = [
          "-euxo",
          "pipefail",
          "-c",
          "${NOMAD_TASK_DIR}/script.sh"
        ]
      }

      template {
        data = <<EOF
set -o pipefail
set -eux

VOLUME_NAMES="{{ with (key "backup/config" | parseJSON) -}}{{- index . "DOCKER_VOLUMES" -}}{{- end }}"
VOLUME_LOCATIONS=""

for VOLUME_NAME in ${VOLUME_NAMES}
do
  VOLUME_LOCATIONS="${VOLUME_LOCATIONS} $(docker volume inspect ${VOLUME_NAME} --format={{ "'{{ .Mountpoint }}'" }})"
done

tar --create ${VOLUME_LOCATIONS} | xz --compress --extreme --threads=0 --verbose --verbose > ${NOMAD_ALLOC_DIR}/data/disk.tar.xz
EOF

        destination = "${NOMAD_TASK_DIR}/script.sh"

        perms = "777"

        change_mode = "noop"
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }
    }

    task "upload-to-s3" {
      driver = "docker"

      consul {}

      lifecycle {
        hook = "poststop"
      }

      config {
        image = "amazon/aws-cli"

        force_pull = true

        network_mode = "host"

        entrypoint = [
          "/bin/bash",
          "-euxo",
          "pipefail",
          "-c",
          "${NOMAD_TASK_DIR}/script.sh"
        ]
      }

      identity {
        name = "aws"
        aud = ["aws"]
        file = true
        ttl = "5m"
      }

      env {
        AWS_WEB_IDENTITY_TOKEN_FILE = "${NOMAD_SECRETS_DIR}/nomad_aws.jwt"
      }

      template {
        data = <<EOF
set -o pipefail
set -eux

aws s3 sync --storage-class DEEP_ARCHIVE --no-progress --region us-east-1 --debug {{ env "NOMAD_ALLOC_DIR" }}/data/ {{ with (key "backup/config" | parseJSON) -}}{{- index . "AWS_S3_LOCATION" -}}{{- end }}$(date --iso-8601)/
EOF

        destination = "${NOMAD_TASK_DIR}/script.sh"

        perms = "777"

        change_mode = "noop"
      }

      template {
        data = <<EOF
AWS_ROLE_ARN={{- with (key "backup/config" | parseJSON) -}}{{- index . "AWS_ROLE_ARN" -}}{{- end }}
AWS_ROLE_SESSION_NAME={{- env "NOMAD_REGION" -}}-{{- env "NOMAD_DC" -}}-{{- (env "NOMAD_JOB_NAME") | replaceAll "/" "-" -}}-{{- env "NOMAD_SHORT_ALLOC_ID" -}}
EOF

        destination = "${NOMAD_SECRETS_DIR}/.env"
        env = true
      }
    }
  }
}
