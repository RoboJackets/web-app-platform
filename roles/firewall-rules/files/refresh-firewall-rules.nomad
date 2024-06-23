variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "refresh-firewall-rules" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  periodic {
    cron = "0 6 * * *"
    prohibit_overlap = true
  }

  group "refresh-firewall-rules" {
    volume "firewall_rules" {
      type = "host"
      source = "firewall_rules"
    }

    task "refresh-firewall-rules" {
      driver = "exec"

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
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output github.json https://api.github.com/meta
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output uptime-robot.txt https://uptimerobot.com/inc/files/ips/IPv4.txt
curl --silent --tlsv1.2 --location --output aws.json https://ip-ranges.amazonaws.com/ip-ranges.json
grep jq-linux64 sha256sum.txt | sha256sum --status --warn --strict --check
mv jq-linux64 jq
chmod +x jq

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/github-actions.conf
for range in $(./jq -r '.actions[]' < github.json)
do
    echo "allow $range;" >> /firewall_rules/github-actions.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/aws.conf
for range in $(./jq -r '.prefixes[] | select(.region=="us-east-1") | select(.service=="EC2") | .ip_prefix' < aws.json)
do
    echo "allow $range;" >> /firewall_rules/aws.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/uptime-robot.conf
for range in $(cat uptime-robot.txt)
do
    echo "allow $(echo $range | tr -d '[:space:]');" >> /firewall_rules/uptime-robot.conf
done

ls -al /firewall_rules/

cat /firewall_rules/*
EOF
        ]
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }

      volume_mount {
        volume = "firewall_rules"
        destination = "/firewall_rules/"
      }
    }
  }
}
