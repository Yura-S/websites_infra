##############################################

data "aws_availability_zones" "working" {}

data "aws_ami" "latest_amazon_linux" {

  owners      = ["137112412989"]
  most_recent = true

  filter {
  name        = "name"
  values      = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#############################################

resource "aws_default_vpc" "default" {}

resource "default_subnet" "default_az1"{
  availability_zone = data.aws_availability_zone.working.names[0]
}

resource "default_subnet" "default_az2"{
  availability_zone = data.aws_availability_zone.working.names[1]
}

############################################

resource "aws_security_group" "web" {

  name          = "web sg"
  vpc_id        = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each    = ["80", "443"]
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

  name                   = "launch template"
  image_id               = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t2_micro"
  vpc_security_group_ids = [aws_security_group.id]
  userdata               = filebase64("${path.module}/user_data.sh")
}

############################################

resource "aws_autoscaling_group" "web" {

  name                    = "asg-ver $(aws_launch_template.web.latest_version)"
  min_size                = 2
  max_size                = 3
  min_elb_capacity        = 2
  health_check_type       = "ELB"
  vpc_zone_identifier     = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
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

resource "aws_elb" "web" {

  name               = "alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]  
}

resource "aws_lb_target_group" "web" {

  name                 = "target group"
  vpc_id               = aws_default_vpc.default.id
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 10
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
