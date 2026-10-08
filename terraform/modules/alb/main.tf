# ALB module
# Internet-facing Application Load Balancer in the public subnets, forwarding HTTP :80
# to the app instance on the app port. The target group health-checks /health, which
# only returns 200 when the app can reach the database.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_security_group_id]


  drop_invalid_header_fields = true

  tags = {
    Name = "${local.name_prefix}-alb"
    Tier = "web"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${local.name_prefix}-tg"
  target_type = "instance"
  protocol    = "HTTP"
  port        = var.app_port
  vpc_id      = var.vpc_id


  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.app_instance_id
  port             = var.app_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
