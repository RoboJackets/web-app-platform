# self-signed-certificate

This role creates a self-signed certificate that is used for initially bootstrapping Nginx before http-01 challenges can pass.

The certificate and private key are stored in a Docker volume called `self-signed-certificate`.
