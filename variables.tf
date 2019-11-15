/*
Copyright 2019 The KubeOne Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

variable "cluster_name" {
  description = "Name of the cluster"
}

variable "worker_os" {
  description = "OS to run on worker machines"

  # valid choices are:
  # * ubuntu
  # * centos
  # * coreos
  default = "ubuntu"
}

variable "ssh_port" {
  description = "SSH port to be used to provision instances"
  default     = 22
}

variable "ssh_username" {
  description = "SSH user, used only in output"
  default     = "ubuntu"
}

# Provider specific settings

variable "control_plane_flavor" {
  description = "OpenStack instance flavor for the control plane nodes"
}

variable "worker_flavor" {
  description = "OpenStack instance flavor for the worker nodes"
}

variable "image" {
  description = "image name to use"
}

variable "image_id" {
  description = "image name to use"
}

variable "subnet_cidr" {
  description = "OpenStack subnet cidr"
}

variable "external_network_name" {
  description = "OpenStack external network name"
}

variable "subnet_dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "8.8.4.4"]
}

