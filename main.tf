provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "jenkins-vpc" }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = { Name = "jenkins-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags   = { Name = "jenkins-igw" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "jenkins-rt" }
}

resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  vpc_id      = aws_vpc.jenkins_vpc.id
  description = "Allow Jenkins traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}

resource "aws_instance" "jenkins_master" {
  ami                         = "ami-0e35ddab05955cf57"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  key_name                    = "mumbaipemkey"
  user_data                   = file("scripts/jenkins_master.sh")

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Jenkins Master"
  }
}

resource "aws_eip" "jenkins_eip" {
  domain   = "vpc"
  instance = aws_instance.jenkins_master.id
  depends_on = [aws_internet_gateway.gw]
}

data "template_file" "slave_user_data" {
  count    = 2
  template = file("scripts/jenkins_slave.sh.tpl")

  vars = {
    jenkins_url = "http://${aws_eip.jenkins_eip.public_ip}:8080"
    slave_name  = "slave-${count.index + 1}"
  }
}

resource "aws_instance" "Jenkins_slave" {
  count                       = 2
  ami                         = "ami-0e35ddab05955cf57"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  key_name                    = "mumbaipemkey"
  user_data                   = data.template_file.slave_user_data[count.index].rendered
  depends_on                  = [aws_instance.jenkins_master, aws_eip.jenkins_eip]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Jenkins Slave-${count.index + 1}"
  }
}
