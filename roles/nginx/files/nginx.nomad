variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

variable "certificate_volume" {
  type = string
  description = "The Docker volume to mount, containing a certificate"
}

job "nginx" {
  region = var.region

  datacenters = [var.datacenter]

  type = "service"

  group "nginx" {
    volume "firewall_rules" {
      type = "host"
      source = "firewall_rules"
    }

    volume "run" {
      type = "host"
      source = "run"
    }

    network {
      port "http" {
        static = 80
      }

      port "https" {
        static = 443
      }

      port "vouch-stub" {}
    }

    task "nginx" {
      driver = "docker"

      consul {}

      config {
        image = "nginx"

        force_pull = true

        network_mode = "host"

        mount {
          type   = "bind"
          source = "local/"
          target = "/etc/nginx/conf.d/"
          readonly = true
        }

        mount {
          type = "tmpfs"
          target = "/var/cache/nginx/"
          readonly = false
          tmpfs_options {
            size = 1000000000
          }
        }

        mount {
          type = "volume"
          target = "/certificate/"
          source = var.certificate_volume
          readonly = true

          volume_options {
            no_copy = true
          }
        }

        mount {
          type = "volume"
          target = "/assets/"
          source = "assets"
          readonly = true

          volume_options {
            no_copy = true
          }
        }

        mount {
          type = "volume"
          target = "/dhparam/"
          source = "dhparam"
          readonly = true

          volume_options {
            no_copy = true
          }
        }
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }

      volume_mount {
        volume = "run"
        destination = "/var/opt/nomad/run/"
      }

      volume_mount {
        volume = "firewall_rules"
        destination = "/etc/nginx/firewall_rules/"
        read_only = true
      }

      template {
        data = <<EOH
{{- range services -}}
  {{- range service .Name -}}
    {{- if .Tags | contains "http" -}}
      {{- scratch.Set "registerService" .Name -}}
    {{- else if index .ServiceMeta "socket" -}}
      {{- scratch.Set "registerService" .Name -}}
    {{- end -}}
  {{- end -}}

  {{- if eq .Name (scratch.Get "registerService") -}}
upstream {{ .Name }} {
  {{- range service .Name -}}
    {{- if index .ServiceMeta "socket" }}
  server unix:{{- index .ServiceMeta "socket" -}};{{- else if .Tags | contains "http" }}
  server 127.0.0.1:{{ .Port }};{{ end -}}
  {{- end }}

  keepalive 8;
}

{{ end -}}
{{- end -}}
{{- if not (service "vouch") -}}
upstream vouch {
  server 127.0.0.1:{{ env "NOMAD_PORT_vouch_stub" }};

  keepalive 8;
}
{{ end }}
server {
  server_name _;

  listen 127.0.0.1:{{ env "NOMAD_PORT_vouch_stub" }} default_server;

  location = /validate {
    return 401;
  }

  location / {
    return 503;
  }
}
{{ range safeLs "nginx/config" }}
{{ .Value }}
{{ end }}
{{ range $service, $hostname := (key "nginx/hostnames" | parseJSON) }}
server {
  server_name {{ $hostname }};

  listen {{ env "NOMAD_PORT_http" }};
  listen [::]:{{ env "NOMAD_PORT_http" }};

  location = /robots.txt {
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /";
    allow all;
  }

  include firewall_rules/block-ai-bots.conf;
  include firewall_rules/block-known-vendors.conf;

  return 301 https://{{ $hostname }}$request_uri;
}
{{ if not (service $service) }}
server {
  server_name {{ $hostname }};

  listen {{ env "NOMAD_PORT_https" }} ssl;
  listen [::]:{{ env "NOMAD_PORT_https" }} ssl;
  http2 on;

  listen {{ env "NOMAD_PORT_https" }} quic;
  listen [::]:{{ env "NOMAD_PORT_https" }} quic;
  http3 on;
  http3_hq on;

  return 503;

  location = /robots.txt {
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /";
    allow all;
  }

  include firewall_rules/block-ai-bots.conf;
  include firewall_rules/block-known-vendors.conf;

  add_header X-Frame-Options DENY always;
  add_header X-Content-Type-Options nosniff always;
  add_header Referrer-Policy no-referrer always;
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
  add_header Alt-Svc 'h3=":{{ env "NOMAD_PORT_https" }}"; ma=86400' always;
  add_header X-Robots-Tag none always;
}
{{- else -}}
{{- range service $service -}}
{{- if index .ServiceMeta "nginx-config" }}
server {
  server_name {{ $hostname }};

  listen {{ env "NOMAD_PORT_https" }} ssl;
  listen [::]:{{ env "NOMAD_PORT_https" }} ssl;
  http2 on;

  listen {{ env "NOMAD_PORT_https" }} quic;
  listen [::]:{{ env "NOMAD_PORT_https" }} quic;
  http3 on;
  http3_hq on;

  location = /robots.txt {
    default_type text/plain;
    return 200 "User-agent: *\nDisallow: /";
    allow all;
  }

  root /assets/{{ $service }};

  {{- index .ServiceMeta "nginx-config" -}}
  {{- if index .ServiceMeta "nginx-config-more" -}}
  {{- index .ServiceMeta "nginx-config-more" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-1" -}}
  {{- index .ServiceMeta "nginx-config-1" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-2" -}}
  {{- index .ServiceMeta "nginx-config-2" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-3" -}}
  {{- index .ServiceMeta "nginx-config-3" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-4" -}}
  {{- index .ServiceMeta "nginx-config-4" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-5" -}}
  {{- index .ServiceMeta "nginx-config-5" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-6" -}}
  {{- index .ServiceMeta "nginx-config-6" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-7" -}}
  {{- index .ServiceMeta "nginx-config-7" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-8" -}}
  {{- index .ServiceMeta "nginx-config-8" -}}
  {{- end -}}
  {{- if index .ServiceMeta "nginx-config-9" -}}
  {{- index .ServiceMeta "nginx-config-9" -}}
  {{- end -}}

  {{- if not (index .ServiceMeta "no-default-headers") -}}
  {{- if index .ServiceMeta "x-frame-options" -}}
  add_header X-Frame-Options {{ index .ServiceMeta "x-frame-options" }} always;
  {{- else -}}
  add_header X-Frame-Options DENY always;
  {{- end -}}
  add_header X-Content-Type-Options nosniff always;
  {{- if index .ServiceMeta "referrer-policy" -}}
  add_header Referrer-Policy {{ index .ServiceMeta "referrer-policy" }} always;
  {{- else -}}
  add_header Referrer-Policy no-referrer always;
  {{- end -}}
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;
  add_header X-Robots-Tag none always;
  {{- end -}}
  add_header Alt-Svc 'h3=":{{ env "NOMAD_PORT_https" }}"; ma=86400' always;

  {{- if index .ServiceMeta "firewall-rules" -}}
    {{- range (index .ServiceMeta "firewall-rules" | parseJSON) -}}
      {{- if eq . "internet" }}
  include firewall_rules/block-ai-bots.conf;
  include firewall_rules/block-known-vendors.conf;
  allow all;
      {{- else }}
  include firewall_rules/{{- . -}}.conf;
      {{- end -}}
    {{- end -}}
  {{- end }}
  deny all;
}
  {{if index .ServiceMeta "nginx-config" | contains "proxy_cache" -}}
proxy_cache_path /var/cache/nginx/{{ .Name }}/ use_temp_path=off keys_zone={{ .Name }}:1m inactive=24h;
  {{- end}}
{{ end -}}
{{- end -}}
{{- end -}}
{{- end -}}
EOH

        change_mode = "signal"
        change_signal = "SIGHUP"

        destination = "local/nginx.conf"
      }

      service {
        name = "nginx"

        port = "http"

        tags = [
          "http"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "1s"

          name = "HTTP"
          path = "/ping"
          port = "http"
          protocol = "http"
          timeout = "1s"
          type = "http"
        }

        check_restart {
          limit = 5
          grace = "20s"
        }
      }

      service {
        name = "nginx"

        port = "https"

        tags = [
          "https"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "1s"

          name = "HTTPS"
          path = "/ping"
          port = "https"
          protocol = "https"
          tls_skip_verify = true
          timeout = "1s"
          type = "http"
        }

        check_restart {
          limit = 5
          grace = "20s"
        }
      }

      restart {
        attempts = 5
        delay = "10s"
        interval = "1m"
        mode = "fail"
      }
    }
  }

  reschedule {
    delay = "10s"
    delay_function = "fibonacci"
    max_delay = "60s"
    unlimited = true
  }

  update {
    max_parallel = 0
  }
}
