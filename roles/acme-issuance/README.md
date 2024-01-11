# acme-issuance

This role will attempt to issue an ACME certificate for the fully-qualified domain name specified in the inventory using the [http-01 challenge](https://letsencrypt.org/docs/challenge-types/). This means that the domain name must be **resolvable in public DNS** and the host must have **port 80 open to the Internet**. If the challenge fails, a self-signed certificate will be used.

For OIT-managed hosts, DNS setup should be completed before system is handed off. Firewall changes must be submitted to the CSR responsible for the VLAN.

The role will check if the http-01 challenge passes from the controller's perspective (i.e. your machine), but if you are running this against an OIT-managed system, that is not necessarily representative of what Let's Encrypt or another ACME issuer would see.

The certificate will also have SANs for `*.{datacenter}.robojackets.net` and `*.robojackets.org`, using dns-01 challenges. You will be prompted for Hurricane Electric credentials when necessary.

The generated certificate will be stored in a Docker volume named after the CA. You can safely swap between CAs and the playbook will either request a new certificate or reuse an existing certificate based on the presence of the Docker volume.

This role will also submit a batch job to Nomad to automatically renew the certificate.
