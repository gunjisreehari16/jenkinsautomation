output "vpc_id" {
  value = aws_vpc.RSP_IOT_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.RSP_IOT_public_subnet.id
}

output "private_subnet_id" {
  value = aws_subnet.RSP_IOT_private_subnet.id
}

output "security_group_id" {
  value = aws_security_group.jenkins_sg.id
}
