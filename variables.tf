variable "cs_cidrs" {
  default = {
    vpc = "10.101.0.0/16"
    network = "10.101.0.0/24"
  }
}

variable "cs_zones" {
  default = {
    network = "NL2"
    master = "NL2"
    worker = "NL2"
    vpc = "NL2"
  }
}

variable "offerings" {
  default = {
    master = "MCC_v2.1vCPU.4GB.SBP1"
    worker = "MCC_v2.1vCPU.4GB.SBP1"
    network = "MCC-VPC-LB"
    vpc = "MCC-VPC-SBP1"
  }
}

variable "counts" {
  default = {
    vpc = "1"
    network = "1"
    master = "1"
    worker = "2"
    public_ip = "3"
  }
}

variable "cs_template" {
        default = "Linux-gnu-x86_64-Coreos-XenServer-latest"
}
