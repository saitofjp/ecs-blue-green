resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_c.id]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_target_group" "blue" {
  name        = "${var.project}-tg-blue"
  vpc_id      = aws_vpc.main.id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/health"
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

resource "aws_lb_target_group" "green" {
  name        = "${var.project}-tg-green"
  vpc_id      = aws_vpc.main.id
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    port = 80
    path = "/health"
  }
}

resource "aws_security_group" "alb" {
  description = "Security Group for ALB"
  name        = "${var.project}-sg-alb"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
