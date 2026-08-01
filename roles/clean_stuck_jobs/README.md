# clean-stuck-jobs

This role will check for any service jobs registered with Nomad that are not healthy in Consul and remove them.

While cleanup runs, the Nomad node is marked ineligible for scheduling, then restored to eligible afterward. If any services are removed, Nomad garbage collection will also be triggered.

Later roles or other mechanisms are responsible for restoring any jobs that are removed by this role.
