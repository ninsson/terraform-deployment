data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "subnet1" {
  filter {
    name   = "tag:Name"
    values = [var.subnet1_name]
  }
}

data "aws_subnet" "subnet2" {
  filter {
    name   = "tag:Name"
    values = [var.subnet2_name]
  }
}

data "aws_security_group" "sg_ssh" {
  filter {
    name   = "group-name"
    values = [var.sg_ssh_name]
  }
}

data "aws_security_group" "sg_http" {
  filter {
    name   = "group-name"
    values = [var.sg_http_name]
  }
}

data "aws_security_group" "sg_lb" {
  filter {
    name   = "group-name"
    values = [var.sg_lb_name]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_lb_target_group" "blue" {
  name     = var.blue_tg_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = var.blue_tg_name
  }
}

resource "aws_lb_target_group" "green" {
  name     = var.green_tg_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = var.green_tg_name
  }
}

resource "aws_lb" "main" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.sg_lb.id]
  subnets            = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  tags = {
    Name = var.lb_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = var.blue_weight
      }

      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = var.green_weight
      }
    }
  }
}

resource "aws_launch_template" "blue" {
  name_prefix   = "${var.blue_template_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    data.aws_security_group.sg_ssh.id,
    data.aws_security_group.sg_http.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y || yum update -y
              dnf install -y httpd || yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Blue Environment</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.blue_template_name}-instance"
    }
  }

  tags = {
    Name = var.blue_template_name
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "${var.green_template_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    data.aws_security_group.sg_ssh.id,
    data.aws_security_group.sg_http.id
  ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y || yum update -y
              dnf install -y httpd || yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Green Environment</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.green_template_name}-instance"
    }
  }

  tags = {
    Name = var.green_template_name
  }
}

resource "aws_autoscaling_group" "blue" {
  name                = var.blue_asg_name
  vpc_zone_identifier = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  target_group_arns   = [aws_lb_target_group.blue.arn]
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.blue_asg_name
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = var.green_asg_name
  vpc_zone_identifier = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  target_group_arns   = [aws_lb_target_group.green.arn]
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.green_asg_name
    propagate_at_launch = true
  }
}
