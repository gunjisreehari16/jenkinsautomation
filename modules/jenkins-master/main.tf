resource "aws_instance" "jenkins_master" {
  ami                         = var.jenkins_ami
  instance_type               = var.jenkins_master_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data                   = file(var.user_data_path)

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Jenkins Master"
  }
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_master.id
  domain   = "vpc"
}
