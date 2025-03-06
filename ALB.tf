resource "aws_lb_target_group" "T_TargetGroup" {
  name     = "t-target-group"
  port     = 80  # Forward to EC2 on port 80 (or change if EC2 uses 8000)
  protocol = "HTTP"
  vpc_id   = aws_vpc.T_VPC.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "T_TargetGroup"
  }
}

resource "aws_lb_target_group_attachment" "T_Target_Attach" {
  for_each         = aws_instance.T_WebApp
  target_group_arn = aws_lb_target_group.T_TargetGroup.arn
  target_id        = each.value.id
  port             = 80 
}


resource "aws_security_group" "T_ALB_SG" {
  vpc_id = aws_vpc.T_VPC.id
  
  ingress {

        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "T_ALB_SG"
  }
}

resource "aws_security_group_rule" "T_Add_ingress_T_SG" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = "${aws_security_group.T_ALB_SG.id}"
    source_security_group_id = "${aws_security_group.T_SG.id}"
}
resource "aws_security_group_rule" "T_Add_egress_T_SG" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = "${aws_security_group.T_ALB_SG.id}"
    source_security_group_id = "${aws_security_group.T_SG.id}"
}

resource "aws_lb" "T_ALB" {
  name               = "t-alb"
  internal           = false  # Set to 'false' to make it internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.T_ALB_SG.id]
  subnets           = [aws_subnet.T_Subnets["Publ_Sub1"].id, aws_subnet.T_Subnets["Publ_Sub2"].id] 

  tags = {
    Name = "T_ALB"
  }
}

resource "aws_lb_listener" "T_ALB_Listener" {
  load_balancer_arn = aws_lb.T_ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.T_TargetGroup.arn
  }
}

