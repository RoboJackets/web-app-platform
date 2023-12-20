# consul

This role installs Consul directly on the system from the HashiCorp Linux repository.

It will also [bootstrap Consul ACLs](https://developer.hashicorp.com/consul/tutorials/day-0/access-control-setup) to limit access to Consul. You will need to use the generated bootstrap token or manually configure another mechanism to authenticate to Consul.

The bootstrap token will be stored inside `/etc/consul.d/consul.hcl` as it's also required for Consul to operate internally.

The Consul UI will be available at `consul.{{ datacenter }}.robojackets.net` once Nginx is fully configured.
