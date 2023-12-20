# meilisearch

This role deploys [Meilisearch](https://www.meilisearch.com/) as a Nomad service.

As Meilisearch does not provide any backwards compatibility guarantees, each version must be deployed separately with a separate data store and a separate API key. Provide a list of desired versions in the `meilisearch_versions` variable in the inventory.

A "master key" will be automatically generated and stored in Consul KV at `meilisearch/master-key`. Version-specific "admin keys" will be retrieved and stored at `meilisearch/admin-key-v{{ meilisearch_version }}`. Read more about Meilisearch authentication [here](https://www.meilisearch.com/docs/learn/security/master_api_keys).

Each version will also have its own Docker volume for database storage.
