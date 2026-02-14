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
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output /firewall_rules/block-ai-bots.conf https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/nginx-block-ai-bots.conf
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output jq-linux64 https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output sha256sum.txt https://raw.githubusercontent.com/jqlang/jq/master/sig/v1.6/sha256sum.txt
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output github.json https://api.github.com/meta
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output uptime-robot.txt https://uptimerobot.com/inc/files/ips/IPv4.txt
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output perplexity.json https://www.perplexity.ai/perplexitybot.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output cloudflare.txt https://www.cloudflare.com/ips-v4
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output digitalocean.csv https://digitalocean.com/geo/google.csv
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output google.json https://www.gstatic.com/ipranges/cloud.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output fastly.json https://api.fastly.com/public-ip-list
curl --silent --tlsv1.2 --location --output linode.csv https://geoip.linode.com/
curl --silent --tlsv1.2 --location --output oracle.json https://docs.oracle.com/en-us/iaas/tools/public_ip_ranges.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output searchbot.json https://openai.com/searchbot.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output chatgpt.json https://openai.com/chatgpt-user.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output gptbot.json https://openai.com/gptbot.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output sentry.txt https://us.sentry.io/api/0/uptime-ips/
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output akamai.txt https://techdocs.akamai.com/property-manager/pdfs/akamai_ipv4_CIDRs.txt
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output zscaler.json https://config.zscaler.com/api/zscalerthree.net/future/json
curl --silent --tlsv1.2 --location --output aws.json https://ip-ranges.amazonaws.com/ip-ranges.json
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output blocklist.de.txt https://lists.blocklist.de/lists/all.txt
curl --silent --http2-prior-knowledge --tlsv1.2 --location --output drop.json https://www.spamhaus.org/drop/drop_v4.json

grep jq-linux64 sha256sum.txt | sha256sum --status --warn --strict --check
mv jq-linux64 jq
chmod +x jq

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/github-actions.conf
for range in $(./jq -r '.actions[]' < github.json)
do
    echo "allow $range;" >> /firewall_rules/github-actions.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/uptime-robot.conf
for range in $(cat uptime-robot.txt)
do
    echo "allow $(echo $range | tr -d '[:space:]');" >> /firewall_rules/uptime-robot.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/aws.conf
for range in $(./jq -r '.prefixes[].ip_prefix' < aws.json)
do
    echo "allow $range;" >> /firewall_rules/aws.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/sentry.conf
for range in $(cat sentry.txt)
do
    echo "allow $range;" >> /firewall_rules/sentry.conf
done

echo "# ${NOMAD_JOB_NAME}" > /firewall_rules/block-known-vendors.conf
echo "deny 160.79.104.0/23;" >> /firewall_rules/block-known-vendors.conf
for range in $(jq -r '.prefixes[].ipv4Prefix' < perplexity.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[].ip_prefix' < aws.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(cat cloudflare.txt)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(cat digitalocean.csv | cut --delimiter=, --fields=1)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' < google.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.addresses[]' < fastly.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(cat linode.csv | grep -v '#' | cut --delimiter=, --fields=1)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.regions[].cidrs[].cidr' < oracle.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' < searchbot.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' < chatgpt.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[] | select(.ipv4Prefix) | .ipv4Prefix' < gptbot.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.values[].properties.addressPrefixes[]' < azure.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(cat akamai.txt)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(./jq -r '.prefixes[]' < zscaler.json)
do
    echo "deny $range;" >> /firewall_rules/block-known-vendors.conf
done
for range in $(cat blocklist.de.txt)
do
    echo "deny $range;" >> /firewall_rules/blocklist.de.conf
done
for range in $(./jq -r '.cidr' drop.json | grep -v null)
do
    echo "deny $range;" >> /firewall_rules/drop.conf
done

curl --silent --unix-socket ${NOMAD_SECRETS_DIR}/api.sock --header 'X-Nomad-Token: ${NOMAD_TOKEN}' http://localhost/v1/client/allocation/$(curl --silent --unix-socket ${NOMAD_SECRETS_DIR}/api.sock --header 'X-Nomad-Token: ${NOMAD_TOKEN}' http://localhost/v1/job/nginx/allocations | ./jq -r '.[0].ID')/signal --request POST --data '{"Signal": "SIGHUP", "Task": "nginx"}' || true
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
