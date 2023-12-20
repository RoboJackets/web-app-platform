# redis

This role runs [Redis](https://redis.io) as a Nomad service. A randomly generated password is stored in Consul KV at `redis/password`. This password can be shared across any services that need to access Redis.
