# acme-account

This role creates an account with Let's Encrypt or another ACME-compatible CA supported by [acme.sh](https://github.com/acmesh-official/acme.sh).

Account keys are stored in a Docker volume named `acme-account-{{ acme_server }}`. You can safely swap between CAs and the playbook will either create a new account or reuse an existing account based on the presence of the Docker volume.

The `owner_contact_email` from the inventory will be provided to the CA. Let's Encrypt will use this information for renewal reminders and other rare cases when they need to notify an administrator. Other CAs may use the email for other purposes.

The account thumbprint will be stored in Consul KV at `acme/{{ acme_server }}-thumbprint` for use with [http-01 validation](https://letsencrypt.org/docs/challenge-types/).

On each run, you will be prompted for a Slack bot token and channel ID so acme.sh can post renewal notifications via `--set-notify`.
