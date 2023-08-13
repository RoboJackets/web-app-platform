# web-app-platform
Ansible playbook for shared infrastructure

## Prerequisites

- A Red Hat Enterprise Linux 9.x host - request one from OIT [here](https://gatech.service-now.com/technology?id=sc_cat_item&sys_id=4d656885dba3c850fc9efe8d0f96194f&sysparm_category=eb2e1a60db11c0987bbc68461b96191f)
- Ansible - see install guide [here](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

Set up an inventory file like so:

```yaml
---
platform:
  hosts:
    rj-bcdc1:
      ansible_host: 1.2.3.4
      ansible_user: gburdell3
      ansible_become: true
      datacenter: bcdc
      node_name: bcdc1
```

Run the playbook like so:

```sh
ansible-playbook --inventory inventory.yml playbook.yml
```
