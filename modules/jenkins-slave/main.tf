data "template_file" "slave_user_data" {
  count    = var.jenkins_slave_count
  template = file("${path.root}/scripts/jenkins_slave.sh.tpl")

  vars = {
    jenkins_url = var.jenkins_url
    slave_name  = "slave-${count.index + 1}"
  }
}

resource "aws_instance" "jenkins_slave" {
  count                       = var.jenkins_slave_count
  ami                         = var.jenkins_ami
  instance_type               = var.jenkins_slave_instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = false
  key_name                    = var.key_name
  user_data                   = data.template_file.slave_user_data[count.index].rendered

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Jenkins Slave-${count.index + 1}"
  }
}
