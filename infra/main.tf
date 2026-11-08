data "aws_caller_identity" "current" {}

locals {
  ecr_repository = "wishifai-${var.candidate_number}"
  image          = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.ecr_repository}:${var.image_tag}"
}

# Bucket for opplastede bilder
resource "aws_s3_bucket" "images" {
  bucket = "wishifai-uploads-${var.candidate_number}"
}

# Task role: det applikasjonskoden bruker for å kalle AWS
resource "aws_iam_role" "task" {
  name = "wishifai-task-role-${var.candidate_number}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "task" {
  name = "wishifai-task-policy-${var.candidate_number}"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.images.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["rekognition:DetectLabels"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["bedrock:InvokeModel"]
        Resource = [
          "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/${var.bedrock_model_id}",
          "arn:aws:bedrock:*::foundation-model/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
      }
    ]
  })
}

# ECS Express-tjeneste
resource "aws_ecs_express_gateway_service" "app" {
  service_name            = "wishifai-${var.candidate_number}"
  execution_role_arn      = var.execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  task_role_arn           = aws_iam_role.task.arn

  cpu               = "512"
  memory            = "1024"
  health_check_path = "/actuator/health"

  primary_container {
    image          = local.image
    container_port = 8080

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.images.bucket
    }

    environment {
      name  = "AWS_REGION"
      value = var.region
    }
  }

  depends_on = [aws_iam_role_policy.task]
}