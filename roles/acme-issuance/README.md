# acme-issuance

This role will attempt to issue an ACME certificate for the fully-qualified domain name specified in the inventory using the [http-01 challenge](https://letsencrypt.org/docs/challenge-types/). This means that the domain name must be **resolvable in public DNS** and the host must have **port 80 open to the Internet**. If the challenge fails, a self-signed certificate will be used.

For OIT-managed hosts, DNS setup should be completed before system is handed off. Firewall changes must be submitted to the CSR responsible for the VLAN.

The role will check if the http-01 challenge passes from the controller's perspective (i.e. your machine), but if you are running this against an OIT-managed system, that is not necessarily representative of what Let's Encrypt or another ACME issuer would see.

The certificate will also have SANs for `*.{datacenter}.robojackets.net` and `*.robojackets.org`, using dns-01 challenges. You will be prompted for Hurricane Electric credentials when necessary.
