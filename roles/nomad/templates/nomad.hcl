{{ ansible_managed | comment }}

datacenter = "{{ datacenter }}"

data_dir = "/opt/nomad"

server {
  enabled = true

  bootstrap_expect = 1

  default_scheduler_config {
    memory_oversubscription_enabled = true
  }

  oidc_issuer = "https://nomad.{{ datacenter }}.robojackets.net"
}

bind_addr = "127.0.0.1"

advertise {
  http = "127.0.0.1"
  rpc = "127.0.0.1"
  serf = "127.0.0.1"
}

client {
  enabled = true

  servers = ["127.0.0.1"]

  reserved {
    cpu = 1000
    memory = 1024
  }

  host_volume "run" {
    path = "/var/opt/nomad/run/"
  }

  host_volume "firewall_rules" {
    path = "/var/opt/nomad/firewall_rules/"
  }
}

acl {
  enabled = true
}

consul {
  address = "unix:///var/opt/nomad/run/consul.sock"
  token = "{{ ansible_facts['consul_token'] }}"
}

region = "{{ region }}"

name = "{{ node_name }}"

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    auth {
      config = "/root/.docker/config.json"
    }

    # https://developer.hashicorp.com/nomad/docs/drivers/docker#allow_caps - defaults + sys_nice for mysql
    allow_caps = ["audit_write", "chown", "dac_override", "fowner", "fsetid", "kill", "mknod",
                  "net_bind_service", "setfcap", "setgid", "setpcap", "setuid", "sys_chroot", "sys_nice"]

    volumes {
      enabled = true
    }
  }
}

ui {
  enabled = true

  consul {
    ui_url = "https://consul.{{ datacenter }}.robojackets.net/ui/{{ datacenter }}/services"
  }

  label {
    text = "{{ datacenter }}"
  }
}
