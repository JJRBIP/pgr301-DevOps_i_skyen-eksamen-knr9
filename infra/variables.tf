variable "region" {
  description = "AWS-region tjenesten kjører i"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_number" {
  description = "Kandidatnummer, brukes i navn på ressurser"
  type        = string
  default     = "9"
}

variable "image_tag" {
  description = "Tag på imaget i ECR (commit-SHA fra pipeline)"
  type        = string
  default     = "latest"
}

variable "execution_role_arn" {
  description = "Eksisterende task execution role"
  type        = string
  default     = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
}

variable "infrastructure_role_arn" {
  description = "Eksisterende infrastructure role for ECS Express"
  type        = string
  default     = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
}

variable "bedrock_model_id" {
  description = "Bedrock inference profile som appen bruker"
  type        = string
  default     = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
}