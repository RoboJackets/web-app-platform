# docker-system-prune

This role runs `docker system prune --all --volumes --force` once during the playbook to free disk space before other roles run.

For ongoing periodic pruning, see the `docker-system-prune` job submitted by the `batch_jobs` role.
