variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "vpc_name" {
  type        = string
  description = "Name of the pre-created VPC"
}

variable "subnet1_name" {
  type        = string
  description = "Name of public subnet 1"
}

variable "subnet2_name" {
  type        = string
  description = "Name of public subnet 2"
}

variable "sg_ssh_name" {
  type        = string
  description = "Name of security group for SSH"
}

variable "sg_http_name" {
  type        = string
  description = "Name of security group for EC2 HTTP"
}

variable "sg_lb_name" {
  type        = string
  description = "Name of security group for Load Balancer"
}

variable "lb_name" {
  type        = string
  description = "Name of Application Load Balancer"
}

variable "blue_tg_name" {
  type        = string
  description = "Name of Blue Target Group"
}

variable "green_tg_name" {
  type        = string
  description = "Name of Green Target Group"
}

variable "blue_template_name" {
  type        = string
  description = "Name of Blue Launch Template"
}

variable "green_template_name" {
  type        = string
  description = "Name of Green Launch Template"
}

variable "blue_asg_name" {
  type        = string
  description = "Name of Blue Auto Scaling Group"
}

variable "green_asg_name" {
  type        = string
  description = "Name of Green Auto Scaling Group"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "blue_weight" {
  type        = number
  description = "Traffic weight for Blue environment"
}

variable "green_weight" {
  type        = number
  description = "Traffic weight for Green environment"
}
