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

provider "openstack" {
  auth_url    = "https://platform.cloud.schwarz:5000/v3"
  region      = "RegionOne"
  tenant_name = "openshift"
  tenant_id   = "8daeed38df5047ecbf3319ea7c599c54"
  domain_name = "default"
}

data "openstack_networking_network_v2" "external_network" {
  name     = var.external_network_name
  external = true
}

# https://www.terraform.io/docs/providers/tls/index.html
resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "openstack_compute_keypair_v2" "deployer" {
  name       = "${var.cluster_name}-deployer-key"
  public_key = "${tls_private_key.ssh-key.public_key_openssh}"
}

resource "openstack_networking_network_v2" "network" {
  name           = "${var.cluster_name}-cluster"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name            = "${var.cluster_name}-cluster"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = var.subnet_dns_servers
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.cluster_name}-cluster"
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_router_interface_v2" "router_subnet_link" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_networking_secgroup_v2" "securitygroup" {
  name        = "${var.cluster_name}-cluster"
  description = "Security group for the Kubeone Kubernetes cluster ${var.cluster_name}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_allow_internal_ipv4" {
  description       = "Allow security group internal IPv4 traffic"
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.securitygroup.id
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_ssh" {
  description       = "Allow SSH"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_apiserver" {
  description       = "Allow kube-apiserver"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.securitygroup.id
}

resource "openstack_compute_instance_v2" "control_plane" {
  name  = "${var.cluster_name}-cp"
  image_name      = var.image
  flavor_name     = var.control_plane_flavor
  key_pair        = openstack_compute_keypair_v2.deployer.name
  security_groups = [openstack_networking_secgroup_v2.securitygroup.name]

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    volume_size           = 50
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.control_plane.id
  }
}

resource "openstack_networking_port_v2" "control_plane" {
  admin_state_up     = "true"
  network_id         = openstack_networking_network_v2.network.id
  security_group_ids = [openstack_networking_secgroup_v2.securitygroup.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet.id
  }
}

resource "openstack_networking_floatingip_v2" "control_plane" {
  pool  = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "control_plane" {
  floating_ip = openstack_networking_floatingip_v2.control_plane.address
  port_id = openstack_networking_port_v2.control_plane.id
}
