# nginx

This role runs an [Nginx](https://nginx.org/) web server as a Nomad service.

A JSON map of Nomad service names to hostnames must be loaded in Consul KV at `nginx/hostnames`. Default values will be populated if not set. If a listed service is not running, a server block with the corresponding hostname will be created to serve a 503 error page.

The default hostname map is:

```json
{
    "nomad": "nomad.{{ datacenter }}.robojackets.net",
    "registry": "registry.{{ datacenter }}.robojackets.net",
    "vouch": "vouch.{{ datacenter }}.robojackets.net"
}
```

Note that `consul.{{ datacenter }}.robojackets.net` is allocated for Consul, but does not appear in this map because the Consul service registration is different from normal services.

Additional hosts may be added; the role will not modify the key if it already exists.

Additional configuration blocks will be stored in Consul KV under the `nginx/config/` prefix. Administrators may add additional keys as needed. Keys created by this role should not be modified directly within Consul, as changes will be overwritten when the role executes again.

Nginx is configured to serve on the following ports:
- Plain-text HTTP on TCP port 80
    - The default server will serve http-01 challenge responses and a simple HTML page with the node's information
    - Other servers will redirect to their corresponding HTTPS server
- HTTPS and HTTP/2 on TCP port 443
    - The default server will serve a simple HTML page with the node's information
    - Other servers will serve apps as configured in the `nginx/hostnames` map and the services' Consul metadata
- HTTP/3 and QUIC on UDP port 443 matching the TCP port 443 configuration
- A randomly-assigned port will be used to serve a stub to provide a 503 page if Vouch is unavailable

All servers have a `robots.txt` file that requests bots not index the server.

Static assets for each service may be copied into a Docker volume named `assets` within a directory named after the service.
