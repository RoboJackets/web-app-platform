# vouch

This role manages a [Vouch](https://github.com/vouch/vouch-proxy) service that is used to authenticate access to the Nomad and Consul UIs. Vouch is available by default at `vouch.{{ datacenter }}.robojackets.net` once Nginx is fully initialized.

A `vouch/config` key must be added to Consul with JSON configuration; this will be parsed and loaded as environment variables for the Vouch server.

Fully configuring Vouch is outside of the scope of this document, but at a minimum, the following keys need to be set:

```json
{
  "VOUCH_DOMAINS": "{{ datacenter }}.robojackets.net",
  "OAUTH_PROVIDER": "pick-a-provider",
  "OAUTH_CLIENT_ID": "client-id-from-provider",
  "OAUTH_CLIENT_SECRET": "client-secret-from-provider",
  "OAUTH_CALLBACK_URL": "https://vouch.{{ datacenter }}.robojackets.net/auth",
}
```

If using Keycloak, use the following configuration:

```json
{
  "VOUCH_WHITELIST": "comma separated list of admin usernames",
  "VOUCH_DOMAINS": "{{ datacenter }}.robojackets.net",
  "OAUTH_PROVIDER": "oidc",
  "OAUTH_CLIENT_ID": "vouch-{{ datacenter }}",
  "OAUTH_CLIENT_SECRET": "client-secret-from-provider",
  "OAUTH_CALLBACK_URL": "https://vouch.{{ datacenter }}.robojackets.net/auth",
  "OAUTH_AUTH_URL": "https://{{ keycloak server }}/realms/{{ realm id }}/protocol/openid-connect/auth",
  "OAUTH_TOKEN_URL": "https://{{ keycloak server }}/realms/{{ realm id }}/protocol/openid-connect/token",
  "OAUTH_USER_INFO_URL": "https://{{ keycloak server }}/realms/{{ realm id }}/protocol/openid-connect/userinfo",
  "OAUTH_SCOPES": "openid"
}
```

When configuring the client within Keycloak:
- Enable "Client authentication"
- Disable "Direct access grants"
- The "Valid redirect URIs" must match what you configure in Consul
- Remove all default "Client scopes"
- Add a mapper to set the Keycloak username in the `email` claim in the token
