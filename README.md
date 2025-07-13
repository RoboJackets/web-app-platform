# web-app-platform
[![ansible-lint](https://github.com/RoboJackets/web-app-platform/actions/workflows/ansible-lint.yml/badge.svg?branch=main)](https://github.com/RoboJackets/web-app-platform/actions/workflows/ansible-lint.yml)

Ansible playbook for shared infrastructure

## Prerequisites

- A Red Hat Enterprise Linux 9 host - request one from OIT [here](https://gatech.service-now.com/technology?id=sc_cat_item&sys_id=4d656885dba3c850fc9efe8d0f96194f&sysparm_category=eb2e1a60db11c0987bbc68461b96191f)
- Ansible - see install guide [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

You do **not** need Nomad or Consul installed locally, but they may be helpful.

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
      datacenter_tag_color: "#002FFF"
      dns_resolvers:
      # these are the OIT-managed recursive resolvers, aka brahmas
      # this list is join()'ed and passed to the resolver directive in nginx; you can add additional config if you'd like
      - 130.207.244.251
      - 130.207.244.244
      - 128.61.244.254
```

Run the playbook like so:

```sh
ansible-playbook playbook.yml
```
