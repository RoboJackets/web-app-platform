# dhparam

This role generates Diffie-Hellman key agreement parameters for use during TLS handshakes. This process takes several minutes and only needs to be executed once.

The parameters file is stored in a Docker volume called `dhparam`.
