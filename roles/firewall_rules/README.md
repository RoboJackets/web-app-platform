# firewall-rules

This role creates allowlists and denylists in Nginx format to limit access to non-end-user-facing services. Rules are written to `/var/opt/nomad/firewall_rules/` and consumed by Nginx via the `firewall_rules` host volume. Lists include both IPv4 and IPv6 ranges where vendors publish them.

Static allowlists written by this role:
- `vpn` - allows access from `vpn-2fa-csrplus`, `vpn-2fa-former-emp`, `vpn-2fa-students`, and `vpn-2fa-other` ranges defined in fw.noc
- `local` - allows access from `127.0.0.0/8`, `::1`, and the `ansible_host` value from inventory

Dynamic lists are refreshed daily at 06:00 by the Nomad batch job `refresh-firewall-rules`:
- `aws` - allows access from AWS IP ranges (all regions, IPv4 and IPv6)
- `uptime-robot` - allows access from [Uptime Robot](https://uptimerobot.com/) monitoring nodes
- `github-actions` - allows access from GitHub Actions runners
- `sentry` - allows access from Sentry uptime monitoring nodes
- `block-known-vendors` - denies traffic from common cloud/CDN/AI crawler ranges (AWS, Azure, Cloudflare, Fastly, Google, DigitalOcean, Linode, Oracle, Akamai, Zscaler, OpenAI, Perplexity, Anthropic, and others)
- `block-ai-bots` - Nginx config that blocks known AI bots
- `drop` - denies Spamhaus DROP listed ranges

Azure Service Tags JSON is downloaded when the role runs and used by the refresh job when building `block-known-vendors`. After refreshing rules, the job sends SIGHUP to Nginx so changes take effect.

Services opt into allowlists via Consul service metadata `firewall-rules` (a JSON array of list names such as `["vpn","local"]` or `["internet"]`).
