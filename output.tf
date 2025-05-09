output "jenkins_master_public_ip" {
  value = module.jenkins_master.public_ip
}

output "jenkins_slave_instance_ids" {
  value = module.jenkins_slave.instance_ids
}

output "jenkins_slave_private_ips" {
  value = module.jenkins_slave.jenkins_slave_private_ips  # Reference module output
}
