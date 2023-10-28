# web-app-platform
Ansible playbook for shared infrastructure

## Prerequisites

- A Red Hat Enterprise Linux 9 host - request one from OIT [here](https://gatech.service-now.com/technology?id=sc_cat_item&sys_id=4d656885dba3c850fc9efe8d0f96194f&sysparm_category=eb2e1a60db11c0987bbc68461b96191f)
- Ansible - see install guide [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

You do **not** need Nomad or Consul installed locally, but they may be helpful.

### Notes on certificate issuance

This playbook will attempt to issue an ACME certificate for the fully-qualified domain name specified in the inventory using the [http-01 challenge](https://letsencrypt.org/docs/challenge-types/). This means that the domain name must be **resolvable in public DNS** and the host must have **port 80 open to the Internet**. If the challenge fails, a self-signed certificate will be used.

For OIT-managed hosts, DNS setup should be completed before system is handed off. Firewall changes must be submitted to the CSR responsible for the VLAN.

The playbook will check if the http-01 challenge passes from the controller's perspective (i.e. your machine), but if you are running this against an OIT-managed system, that is not necessarily representative of what Let's Encrypt or another ACME issuer would see.

The certificate will also have SANs for `*.{datacenter}.robojackets.net` and `*.robojackets.org`, using dns-01 challenges. You will be prompted for Hurricane Electric credentials when necessary.

Set up an inventory file like so:

```yaml
---
ungrouped:
  hosts:
    bcdc1:
      # ansible_host is assumed to be an IP address in several places
      ansible_host: 1.2.3.4
      ansible_user: gburdell3
      ansible_become: true
      datacenter: bcdc
      node_name: bcdc1
      region: campus
      owner_contact_name: George Burdell
      owner_contact_email: gburdell3@gatech.edu
      acme_server: letsencrypt_test
      fully_qualified_domain_name: bcdc1.gatech.edu
      dns_resolvers:
      # these are the OIT-managed recursive resolvers, aka brahmas
      # this list is join()'ed and passed to the resolver directive in nginx; you can add additional config if you'd like
      - 130.207.244.251
      - 130.207.244.244
      - 128.61.244.254
      meilisearch_versions:
      - 1.1
      - 1.2
      - 1.3
```

Run the playbook like so:

```sh
ansible-playbook playbook.yml
```
