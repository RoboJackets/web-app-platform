# batch-jobs

This role submits batch jobs to Nomad to periodically perform maintenance tasks.

## docker-system-prune

Runs `docker system prune --all --volumes --force` to delete any unused Docker images or volumes. This helps manage disk usage on the host.

## unmount-nethomes

Removes any home directories mounted to `/nethome/` if the corresponding user does not have an active session. This prevents hung NFS mounts preventing login after network or system maintenance.
