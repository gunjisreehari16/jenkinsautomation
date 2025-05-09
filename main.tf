provider "aws" {
  region = var.region
}

module "network" {
  source               = "./modules/network"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = "RSP-IOT"
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  availability_zone    = var.availability_zone
}

module "jenkins_master" {
  source                       = "./modules/jenkins-master"
  jenkins_ami                  = var.jenkins_ami
  jenkins_master_instance_type = var.jenkins_master_instance_type
  subnet_id                    = module.network.public_subnet_id
  security_group_id            = module.network.security_group_id
  key_name                     = var.key_name
  user_data_path               = "${path.module}/scripts/jenkins_master.sh"
}

module "jenkins_slave" {
  source                    = "./modules/jenkins-slave"
  jenkins_ami               = var.jenkins_ami
  jenkins_slave_instance_type = var.jenkins_slave_instance_type
  jenkins_slave_count       = var.jenkins_slave_count
  subnet_id                 = module.network.private_subnet_id
  security_group_id         = module.network.security_group_id
  key_name                  = var.key_name
  jenkins_url               = "http://${module.jenkins_master.public_ip}:8080"
  slave_script_path         = "${path.module}/scripts/slave.sh.tpl"
}
