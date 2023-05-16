##############################################

data "aws_availability_zones" "working" {}

data "aws_ami" "latest_ubuntu" {

  owners      = ["099720109477"]
  most_recent = true

  filter {
  name        = "name"
  values      = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#############################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "default" {
  count = length(data.aws_subnets.default.ids)
  id    = data.aws_subnets.default.ids[count.index]
}

############################################

resource "aws_security_group" "web" {

  name          = "web sg"
  vpc_id        = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each    = ["80", "443", "22"]
    content {
    from_port   = ingress.value
    to_port     = ingress.value
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
  from_port     = 0
  to_port       = 0
  protocol      = "-1"
  cidr_blocks   = ["0.0.0.0/0"]
  }
}

############################################

resource "aws_launch_template" "web" {

  name                   = "LaunchTemplate"
  image_id               = data.aws_ami.latest_ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data               = filebase64("${path.module}/user_data.sh")
}

############################################

resource "aws_autoscaling_group" "web" {

  name                    = "asg-ver $(aws_launch_template.web.latest_version)"
  min_size                = 2
  max_size                = 3
  min_elb_capacity        = 2
  health_check_type       = "ELB"
  vpc_zone_identifier     = [data.aws_subnets.default.ids[0],data.aws_subnets.default.ids[1]]
  target_group_arns       = [aws_lb_target_group.web.arn]

  launch_template{
  id                      = aws_launch_template.web.id
  version                 = aws_launch_template.web.latest_version
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

############################################

resource "aws_lb" "web" {

  name               = "alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [data.aws_subnets.default.ids[0],data.aws_subnets.default.ids[1]] 
}

resource "aws_lb_target_group" "web" {

  name                 = "TargetGroup"
  vpc_id               = data.aws_vpc.default.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 10

  health_check {
    path = "/index.html"
  }
}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

############################################

output "load_balancer_url" {
value = aws_lb.web.dns_name
}
