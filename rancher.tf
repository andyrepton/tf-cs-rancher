provider "cloudstack" {
    api_key       =  "${replace("${file("~/.terraform/nl2_cs_api_key")}", "\n", "")}"
    secret_key    =  "${replace("${file("~/.terraform/nl2_cs_secret_key")}", "\n", "")}"
    api_url       =  "https://nl2.mcc.schubergphilis.com/client/api"
}

resource "template_file" "master-config" {
    count = "${lookup(var.counts, "master")}"
    template = "${file("master.yaml.tpl")}"
    vars {
      terraform_hostname = "kube-master-1"
    }
}

resource "template_file" "node-config" {
    count = "${lookup(var.counts, "worker")}"
    template = "${file("worker.yaml.tpl")}"
    vars {
      terraform_master_ip = "${cloudstack_instance.master.0.ipaddress}"
    }
}

resource "cloudstack_vpc" "vpc" {
    count = "${lookup(var.counts, "vpc")}"
    name = "rancher-${count.index+1}"
    cidr = "${lookup(var.cs_cidrs, "vpc")}"
    vpc_offering = "${lookup(var.offerings, "vpc")}"
    zone = "${lookup(var.cs_zones, "vpc")}"
}

resource "cloudstack_network" "network" {
    count = "${lookup(var.counts, "network")}"
    name = "rancher-network${count.index+1}"
    display_text = "rancher-network${count.index+1}"
    cidr = "${lookup(var.cs_cidrs, "network")}"
    network_offering = "${lookup(var.offerings, "network")}"
    zone = "${lookup(var.cs_zones, "network")}"
    vpc = "${element(cloudstack_vpc.vpc.*.name, count.index)}"
    aclid = "${element(cloudstack_network_acl.acl.*.id, count.index)}"
}

resource "cloudstack_instance" "master" {
  count = "${lookup(var.counts, "master")}"
  zone = "${lookup(var.cs_zones, "master")}"
  service_offering = "${lookup(var.offerings, "master")}"
  template = "${var.cs_template}"
  name = "rancher-master-${count.index+1}"
  network = "${cloudstack_network.network.0.id}"
  expunge = "true"
  user_data = "${element(template_file.master-config.*.rendered, count.index)}"
  keypair = "deployment"
}

resource "cloudstack_instance" "worker" {
  count = "${lookup(var.counts, "worker")}"
  zone = "${lookup(var.cs_zones, "worker")}"
  service_offering = "${lookup(var.offerings, "worker")}"
  template = "${var.cs_template}"
  name = "rancher-worker-${count.index+1}"
  network = "${cloudstack_network.network.0.id}"
  expunge = "true"
  user_data = "${element(template_file.node-config.*.rendered, count.index)}"
  keypair = "deployment"
}

resource "cloudstack_network_acl" "acl" {
  count = "${lookup(var.counts, "vpc")}"
  name = "rancher-acl-${count.index+1}"
  vpc = "${element(cloudstack_vpc.vpc.*.id, count.index)}"
}

resource "cloudstack_network_acl_rule" "acl-rule" {
  count = "${lookup(var.counts, "vpc")}"
  aclid = "${element(cloudstack_network_acl.acl.*.id, count.index)}"

  rule {
    source_cidr = "195.66.90.0/24"
    protocol = "all"
    action = "allow"
    traffic_type = "ingress"
  }
}

resource "cloudstack_ipaddress" "public_ip" {
  count = "${lookup(var.counts, "public_ip")}"
  vpc = "${cloudstack_vpc.vpc.0.id}"
}

resource "cloudstack_port_forward" "master" {
  ipaddress = "${cloudstack_ipaddress.public_ip.0.id}"

  forward {
    protocol = "tcp"
    private_port = "22"
    public_port = "22"
    virtual_machine = "${cloudstack_instance.master.0.id}"
  }
  forward {
    protocol = "tcp"
    private_port = "22"
    public_port = "122"
    virtual_machine = "${cloudstack_instance.worker.0.id}"
  }
  forward {
    protocol = "tcp"
    private_port = "22"
    public_port = "222"
    virtual_machine = "${cloudstack_instance.worker.1.id}"
  }
  forward {
    protocol = "tcp"
    private_port = "8080"
    public_port = "80"
    virtual_machine = "${cloudstack_instance.master.0.id}"
  }
}

resource "cloudstack_static_nat" "workers" {
  count = "${lookup(var.counts, "worker")}"
  ipaddress = "${element(cloudstack_ipaddress.public_ip.*.id, count.index+1)}"
  virtual_machine = "${element(cloudstack_instance.worker.*.id, count.index+1)}"
  network = "${cloudstack_network.network.0.id}"
}

output "addresses" {
  value = "IP addresses are ${join(", ", cloudstack_ipaddress.public_ip.*.ipaddress)}"
}
