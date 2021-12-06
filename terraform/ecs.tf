resource "aws_ecs_cluster" "main" {
  name = var.project
}

resource "aws_ecs_service" "main" {
  name            = var.project
  cluster         = aws_ecs_cluster.main.arn
  task_definition = "${aws_ecs_task_definition.main.family}:${max(aws_ecs_task_definition.main.revision, data.aws_ecs_task_definition.main.revision)}"
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_c.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_security_group" "ecs" {
  description = "Security Group for ECS"
  name        = "${var.project}-sg-ecs"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.main.family
}

resource "aws_ecs_task_definition" "main" {
  family                   = var.project
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = aws_ecr_repository.app.repository_url
      essential = true
      environment = [
        { name : "VERSION", value : "initial" }
      ]
      logConfiguration = {
        logDriver : "awslogs",
        options : {
          awslogs-region : data.aws_region.current.name,
          awslogs-stream-prefix : "app",
          awslogs-group : aws_cloudwatch_log_group.ecs_app.name
        }
      },
    },
    {
      name      = "nginx"
      image     = aws_ecr_repository.nginx.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver : "awslogs",
        options : {
          awslogs-region : data.aws_region.current.name,
          awslogs-stream-prefix : "nginx",
          awslogs-group : aws_cloudwatch_log_group.ecs_nginx.name
        }
      }
    }
  ])
}

data "aws_iam_role" "ecsTaskExecutionRole" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecr_repository" "app" {
  name = "${var.project}-app"
}

resource "aws_ecr_repository" "nginx" {
  name = "${var.project}-nginx"
}

resource "aws_cloudwatch_log_group" "ecs_app" {
  name = "/${var.project}/ecs/app"
}

resource "aws_cloudwatch_log_group" "ecs_nginx" {
  name = "/${var.project}/ecs/nginx"
}
