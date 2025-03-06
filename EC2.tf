resource "aws_iam_role" "T_EC2_SSM_Role" {
  name = "T_EC2_SSM_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "T_SSM_Policy_Attachment" {
  name       = "T_SSM_Policy_Attachment"
  roles      = [aws_iam_role.T_EC2_SSM_Role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "T_EC2_Instance_Profile" {
  name = "T_EC2_Instance_Profile"
  role = aws_iam_role.T_EC2_SSM_Role.name
}

resource "aws_instance" "T_WebApp" {
  for_each = {
    "WepApp1" = { subid = aws_subnet.T_Subnets["Priv_Sub1"].id,
    userdata = "#!/bin/bash\nyum update -y\nyum install httpd -y\nsystemctl start httpd\nsystemctl enable httpd\necho 'Server 1' > /var/www/html/index.html" },
    "WepApp2" = { subid = aws_subnet.T_Subnets["Priv_Sub2"].id,
    userdata = "#!/bin/bash\nyum update -y\nyum install httpd -y\nsystemctl start httpd\nsystemctl enable httpd\necho 'Server 2' > /var/www/html/index.html" }
  }
  ami                  = "ami-0ace34e9f53c91c5d"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.T_EC2_Instance_Profile.name
  subnet_id            = each.value.subid
  security_groups      = [aws_security_group.T_SG.id]
  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name = each.key
  }
  user_data                   = each.value.userdata
  user_data_replace_on_change = false
  depends_on                  = [aws_internet_gateway.T_GW, aws_nat_gateway.T_NGW]
}
