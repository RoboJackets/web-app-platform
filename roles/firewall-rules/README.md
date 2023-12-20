# firewall-rules

This role creates allowlists in Nginx format to limit access to non-end-user-facing services. It currently only generates IPv4 ranges as our current production VLAN (128) only has IPv4 addressing.

The following allowlists are created:
- `vpn` - allows access from `vpn-2fa-csrplus`, `vpn-2fa-former-emp`, `vpn-2fa-students`, and `vpn-2fa-other` ranges defined in fw.noc
- `local` - allows access from `127.0.0.0/8` as well as the `ansible_host` value from inventory
- `aws` - allows access from EC2 instances and other user-controlled IP addresses in us-east-1
- `uptime-robot` - allows access from [Uptime Robot](https://uptimerobot.com/) monitoring nodes

The last two lists are refreshed daily from the respective vendors via Nomad batch job.
