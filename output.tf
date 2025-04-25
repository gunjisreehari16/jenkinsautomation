output "jenkins_ui_url" {
  description = "Jenkins Web UI URL"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "jenkins_master_public_ip" {
  description = "Jenkins Master Public IP"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_slave_public_ips" {
  description = "Public IPs of Jenkins slave nodes"
  value       = [for instance in aws_instance.Jenkins_slave : instance.public_ip]
}
