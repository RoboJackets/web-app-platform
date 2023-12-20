# acme-account

This role creates an account with Let's Encrypt or another ACME-compatible CA supported by [acme.sh](https://github.com/acmesh-official/acme.sh).

Account keys are stored in a Docker volume named after the CA. You can safely swap between CAs and the playbook will either create a new account or reuse an existing account based on the presence of the Docker volume.

The `owner_contact_email` from the inventory will be provided to the CA. Let's Encrypt will use this information for renewal reminders and other rare cases when they need to notify an administrator. Other CAs may use the email for other purposes.

The account thumbprint will be stored in Consul for use with [http-01 validation](https://letsencrypt.org/docs/challenge-types/).
