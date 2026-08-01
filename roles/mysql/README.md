# mysql

This role runs a MySQL database server as a Nomad service.

The root password will be automatically generated (32 characters) if missing and stored in Consul KV at `mysql/root_password`.

Data is stored in a Docker volume named `mysql`. The server listens on `127.0.0.1:3306` and also exposes a Unix socket under `/var/opt/nomad/run/` (path published in Consul service metadata as `socket`). The backup role uses that password and socket metadata when dumping databases.

Inventory vars used when submitting the job: `region`, `datacenter`.
