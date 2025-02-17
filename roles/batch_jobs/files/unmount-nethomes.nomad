variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "unmount-nethomes" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  periodic {
    cron = "@hourly"
    prohibit_overlap = true
  }

  group "unmount-nethomes" {
    task "unmount-nethomes" {
      driver = "raw_exec"

      config {
        command = "/bin/bash"
        args    = [
          "-euxo",
          "pipefail",
          "-c",
<<EOH
for user in $(mount | grep /nethome/ | cut --delimiter=/ --fields=7 | cut --delimiter=" " --fields=1); do
    if ! [[ $(who | grep $user) ]]; then
        if ! [[ $user == operator ]]; then
          echo "Unmounting nethome for $user"
          umount /nethome/$user
        fi
    fi
done
EOH
        ]
      }
    }
  }
}
