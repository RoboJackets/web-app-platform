# nomad

This role configures Nomad to require an ACL token to interact with the control plane. The bootstrap token is stored in Consul at `/nomad/token`.

You may want to set up OIDC authentication following the [Single Sign-On docs](https://developer.hashicorp.com/nomad/tutorials/single-sign-on)). Specific instructions for Keycloak are below.

## Using Keycloak

Configure the client like so:
- Enable "Client authentication"
- Disable "Direct access grants"
- The "Valid redirect URIs" must include `http://localhost:4649/oidc/callback` for CLI authentication and `https://nomad.{{ datacenter }}.robojackets.net/ui/settings/tokens` for web authentication (matching redirect URIs in config below)
- Remove all default "Client scopes"
- Add a mapper to set the Keycloak username in the `username` claim in the token
- Add a mapper to set the client roles in the `roles` claim in the token
- Create a client role called `management` and add administrative users to the role

Create a file with the following contents, with your specific values substituted in curly braces:
```json
{
  "OIDCDiscoveryURL": "https://{{ keycloak server }}/realms/{{ realm id }}",
  "OIDCClientID": "{{ client id }}",
  "OIDCClientSecret": "{{ client secret }}",
  "BoundAudiences": ["{{ client id }}"],
  "AllowedRedirectURIs": [
    "http://localhost:4649/oidc/callback",
    "https://nomad.{{ datacenter }}.robojackets.net/ui/settings/tokens"
  ],
  "ClaimMappings": {
    "username": "username"
  },
  "ListClaimMappings": {
    "roles": "roles"
  }
}
```

If you haven't already, specify your Nomad server address and existing token:
```sh
export NOMAD_ADDR=https://nomad.{{ datacenter }}.robojackets.net
export NOMAD_TOKEN=00000000-0000-0000-0000-000000000000 # substitute the bootstrap token or another management token
```

Create the auth method with
```sh
nomad acl auth-method create -type=OIDC \
    -name=Keycloak \
    -default=true \
    -max-token-ttl=1h \
    -token-locality=global \
    -config=@your-config-file.json \
    -token-name-format="keycloak-${value.username}"
```

Create the binding rule with
```sh
nomad acl binding-rule create \
    -auth-method=Keycloak \
    -bind-type=management \
    -selector='management in list.roles'
```

At this point you should be able to use `nomad login` in a terminal or the "Sign in with Keycloak" button in the web interface.
