terraform {
  backend "s3" {
    bucket         = "jenkins-terraform-state-ap-south-1"
    key            = "jenkins/main.tfstate"
    region         = "ap-south-1"
    #dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
