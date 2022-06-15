provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.my_key.private_key_openssh
  filename        = var.key_path
  file_permission = "0600"
}

resource "aws_vpc" "testdatadog" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.app_name}_vpc"
  }
}

resource "aws_security_group" "ping" {
  vpc_id      = aws_vpc.testdatadog.id
  name        = "allow_ping"
  description = "Allow ping"
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ssh bastion
resource "aws_security_group" "ssh_access_public" {
  vpc_id      = aws_vpc.testdatadog.id
  name        = "allow_ssh_traffic_public"
  description = "Allow ssh traffic public"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.app_name}_allow_ssh_traffic_public"
  }
}

resource "aws_security_group" "web_traffic" {
  vpc_id      = aws_vpc.testdatadog.id
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  dynamic "ingress" {
    for_each = var.ingress_web
    content {
      description = ingress.key
      from_port   = ingress.value.port_from
      to_port     = ingress.value.port_to
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "${var.app_name}_allow_web_traffic"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.testdatadog.id
  cidr_block              = var.public_subnet_a_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.app_name}_public_subnet_a"
  }
}

resource "aws_internet_gateway" "testdatadog" {
  vpc_id = aws_vpc.testdatadog.id
  tags = {
    Name = "${var.app_name}_gw"
  }
}

resource "aws_route_table" "public_a" {
  vpc_id = aws_vpc.testdatadog.id
  tags = {
    Name = "${var.app_name}_public_a_route_table"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_a.id
}

resource "aws_route" "public_a" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public_a.id
  gateway_id             = aws_internet_gateway.testdatadog.id
}

resource "aws_lb" "nlb" {
  name = "nlb"
  internal = false
  load_balancer_type = "network"
  subnets = [aws_subnet.public_a.id,]
  enable_deletion_protection = false
  # cross_zone_load_balancing   = true
  enable_cross_zone_load_balancing = true
  # security_groups = [
  #   aws_security_group.ssh_access_public.id,
  #   aws_security_group.ping.id
  # ]
  tags = {
    Name = "network_lb"
  }
}

resource "aws_lb_target_group" "nlb_p22" {
  name = "nlb22-tg"
  port = 22
  protocol = "TCP"
  vpc_id = aws_vpc.testdatadog.id
  health_check {
    port     = 22
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "nlb_p80" {
  name = "nlb80-tg"
  port = 80
  protocol = "TCP"
  target_type = "ip"
  vpc_id = aws_vpc.testdatadog.id
  health_check {
    port     = 80
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "nlb_p8080" {
  name = "nlb8080-tg"
  port = 8080
  protocol = "TCP"
  target_type = "ip"
  vpc_id = aws_vpc.testdatadog.id
  health_check {
    port     = 8080
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "nlb_p22" {
  load_balancer_arn = aws_lb.nlb.arn
  port = "22"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_p22.arn
  }
}

resource "aws_lb_listener" "nlb_p80" {
  load_balancer_arn = aws_lb.nlb.arn
  port = "80"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_p80.arn
  }
}

resource "aws_lb_listener" "nlb_p8080" {
  load_balancer_arn = aws_lb.nlb.arn
  port = "8080"
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nlb_p8080.arn
  }
}

resource "aws_launch_configuration" "testinstance" {
  name            = "launch_configuration_for_test_instance"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.ssh_access_public.id, aws_security_group.ping.id, aws_security_group.web_traffic.id]
  key_name        = var.key_name
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "testinstance" {
  vpc_zone_identifier = [aws_subnet.public_a.id, ]
  # availability_zones   = [var.availability_zone_a, var.availability_zone_b]
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  launch_configuration = aws_launch_configuration.testinstance.name
  depends_on = [
    aws_launch_configuration.testinstance,
  ]
}

resource "aws_autoscaling_attachment" "asg_attachment_testinstance" {
  autoscaling_group_name = aws_autoscaling_group.testinstance.id
  # elb                    = aws_elb.bastion.id
  lb_target_group_arn    = aws_lb_target_group.nlb_p22.arn
}