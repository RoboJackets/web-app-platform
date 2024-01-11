# clean-stuck-jobs

This role will check for any service jobs registered with Nomad that are not healthy in Consul and remove them.

If any services are removed, Nomad garbage collection will also be triggered.

Later roles or other mechanisms are responsible for restoring any jobs that are removed by this role.
