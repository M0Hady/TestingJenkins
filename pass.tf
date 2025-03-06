provider "aws" {
  access_key = "FAKEAWSACCESSKEY1234567890"
  secret_key = "FAKEAWSSECRETKEY0987654321"
  region     = "us-east-1"
}

resource "aws_instance" "test" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  tags = {
    Name = "TestInstance"
  }
}

variable "db_password" {
  default = "SuperSecretDBPassword!"
}

variable "api_key" {
  default = "my-api-key-12345"
}

