output "instance_ids" {
  value = [for i in aws_instance.jenkins_slave : i.id]  # Corrected reference to lowercase
}

output "jenkins_slave_private_ips" {
  value = [for instance in aws_instance.jenkins_slave : instance.private_ip]
}
