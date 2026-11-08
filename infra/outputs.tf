output "service_url" {
  description = "Offentlig endepunkt for tjenesten"
  value       = aws_ecs_express_gateway_service.app.ingress_paths[0].endpoint
}

output "bucket_name" {
  description = "S3-bucket for bilder"
  value       = aws_s3_bucket.images.bucket
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}