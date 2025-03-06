resource "aws_vpc" "T_VPC" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "T_VPC"
    }
}

resource "aws_subnet" "T_Subnets" {
    vpc_id     = aws_vpc.T_VPC.id
    for_each = {
        "Priv_Sub1"={cidr="10.0.100.0/24",az="us-east-1a",case=false},
        "Priv_Sub2"={cidr="10.0.200.0/24",az="us-east-1b",case=false},
        "Publ_Sub1"={cidr="10.0.10.0/24",az="us-east-1a",case=true},
        "Publ_Sub2"={cidr="10.0.20.0/24",az="us-east-1b",case=true}
    }
    cidr_block = each.value.cidr
    availability_zone = each.value.az
    map_public_ip_on_launch = each.value.case
    tags = {
        Name = each.key
    }
}

resource "aws_internet_gateway" "T_GW" {
    vpc_id = aws_vpc.T_VPC.id
    tags = {
        Name = "T_GW"
    }
}

resource "aws_eip" "T_EIPNAT1" {
  domain = "vpc"
}
resource "aws_eip" "T_EIPNAT2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "T_NGW" {
    for_each = {
        "Publ_Sub1"={subid=aws_subnet.T_Subnets["Publ_Sub1"].id,
                     eip=aws_eip.T_EIPNAT1.id},
        "Publ_Sub2"={subid=aws_subnet.T_Subnets["Publ_Sub2"].id,
                     eip=aws_eip.T_EIPNAT2.id}
    }
    allocation_id = each.value.eip
    subnet_id = each.value.subid
    tags = {
        Name = "T_NGW_${each.key}"
    }
    depends_on = [aws_internet_gateway.T_GW]
}

resource "aws_route_table" "T_Public_RT" {
    vpc_id = aws_vpc.T_VPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.T_GW.id
    }
    tags = {
        Name = "T_Public_RT"
    }
}

resource "aws_route_table_association" "T_Public_Assoctiate" {
    for_each = {"Publ_Sub1"=aws_subnet.T_Subnets["Publ_Sub1"].id,
                "Publ_Sub2"=aws_subnet.T_Subnets["Publ_Sub2"].id}
    subnet_id      = each.value
    route_table_id = aws_route_table.T_Public_RT.id
}


resource "aws_route_table" "T_Private_RT" {
    vpc_id = aws_vpc.T_VPC.id
    for_each = {"NAT1"=aws_nat_gateway.T_NGW["Publ_Sub1"].id,
                "NAT2"=aws_nat_gateway.T_NGW["Publ_Sub2"].id}
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = each.value
    }
    tags = {
        Name = "T_Private_RT_${each.value}"
    }
}

resource "aws_route_table_association" "T_Private_Assoctiate" {
    for_each = {"Priv_Sub1"={
                subid=aws_subnet.T_Subnets["Priv_Sub1"].id,
                routetable=aws_route_table.T_Private_RT["NAT1"].id
                }
                "Priv_Sub2"={
                subid=aws_subnet.T_Subnets["Priv_Sub2"].id,
                routetable=aws_route_table.T_Private_RT["NAT2"].id
                }
    }
    subnet_id      = each.value.subid
    route_table_id = each.value.routetable
}


variable "ports" {
    type = list(any)
    default = [80,22]
}

resource "aws_security_group" "T_SG" {
  vpc_id = aws_vpc.T_VPC.id

  ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        security_groups  = [aws_security_group.T_ALB_SG.id]
    }

  egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

  tags = {
    Name = "T_SG"
  }
}


