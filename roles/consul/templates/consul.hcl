{{ ansible_managed | comment }}

datacenter = "{{ datacenter }}"

data_dir = "/opt/consul"

ui_config {
  enabled = true
}

server = true

bind_addr = "127.0.0.1"

bootstrap_expect = 1

acl {
  enabled = true
  default_policy = "deny"
{% if 'consul_token' in ansible_facts and ansible_facts['consul_token'] != None %}
  tokens {
    agent = "{{ ansible_facts['consul_token'] }}"
  }
{% endif %}
{% if consul_bootstrap is defined and consul_bootstrap.json.SecretID != None %}
  tokens {
    agent = "{{ consul_bootstrap.json.SecretID }}"
  }
{% endif %}
}

http_config {
  response_headers = {
    "Strict-Transport-Security" = "max-age=31536000; includeSubDomains"
    "Content-Security-Policy" = "block-all-mixed-content"
    "X-Frame-Options" = "DENY"
    "X-Content-Type-Options" = "nosniff"
    "Referrer-Policy" = "no-referrer"
  }
}

unix_sockets {
  user = "{{ ansible_facts.getent_passwd.consul.1 }}"
  group = "{{ ansible_facts.getent_passwd.consul.2 }}"
  mode = "777"
}

addresses {
  http = "unix:///var/opt/nomad/run/consul.sock"
}

node_name = "{{ node_name }}"

limits {
  http_max_conns_per_client = 1000
}

ports {
  dns = -1
  https = -1
  grpc = -1
  grpc_tls = -1
  serf_wan = -1
}

retry_join = ["127.0.0.1"]
