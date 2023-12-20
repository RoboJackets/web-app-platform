# backup

This role submits a batch job to Nomad to back up MySQL databases, Docker volumes, Nomad snapshots, and Consul snapshots to AWS S3.

You must **manually** create a Consul key with the following JSON configuration:

```json
{
  "MYSQLDUMP_SCOPE": "any desired parameters passed directly to mysqldump",
  "DOCKER_VOLUMES": "space-delimited list of Docker volumes you want to back up",
  "AWS_ROLE_ARN": "ARN of AWS IAM role that is configured to trust the Nomad OIDC issuer",
  "AWS_S3_LOCATION": "where to upload backups"
}
```

Example:

```json
{
  "MYSQLDUMP_SCOPE": "--ignore-table=mysql.user --ignore-table=mysql.time_zone --databases mysql",
  "DOCKER_VOLUMES": "acme-account-letsencrypt_test acme-account-letsencrypt",
  "AWS_ROLE_ARN": "arn:aws:iam::622267835773:role/nomad-identity-test",
  "AWS_S3_LOCATION": "s3://robojackets-sandbox-backup-test/"
}
```

Review the AWS documentation for [web identity federation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_oidc.html) to set up the IAM role. You will need to [create an OIDC provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) and a [role that trusts the provider](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html).
