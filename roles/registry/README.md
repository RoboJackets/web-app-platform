# registry

This role runs a [CNCF Distribution Registry](https://distribution.github.io/distribution/) as a Nomad service. The registry is available at `registry.{{ datacenter }}.robojackets.net` by default after Nginx has initialized.

A randomly-generated password will be generated on the **control** node at `credentials/registry-password`. The password is hashed using htpasswd and stored in `registry/htpasswd` for the registry server to read. The password is also stored at `/root/.docker/config.json` on the **managed** node so that the root user (and Nomad) can pull images from this registry. The username is `robojacketsregistry`.

This role will also register a batch job to periodically run garbage collection on the registry to remove unneeded layers and manifests.
