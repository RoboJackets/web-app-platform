variable "region" {
  type = string
  description = "The region in which to run the service"
}

variable "datacenter" {
  type = string
  description = "The datacenter in which to run the service"
}

job "docker-system-prune" {
  region = var.region

  datacenters = [var.datacenter]

  type = "batch"

  priority = 1

  periodic {
    cron = "0 9 * * *"
    prohibit_overlap = true
  }

  group "docker-system-prune" {
    task "docker-system-prune" {
      driver = "raw_exec"

      config {
        command = "/bin/docker"
        args    = [
          "system",
          "prune",
          "--all",
          "--volumes",
          "--force",
        ]
      }
    }
  }
}
