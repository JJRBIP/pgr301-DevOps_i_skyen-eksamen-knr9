locals {
  ecs_cluster  = "default"
  ecs_service  = "wishifai-9"
  cw_namespace = "wishifai"
  cw_region    = "eu-west-1"
}

resource "aws_cloudwatch_dashboard" "wishifai" {
  dashboard_name = "wishifai-9-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Business: analyserte bilder per romtype"
          region = local.cw_region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"
          metrics = [
            [local.cw_namespace, "wishifai.images.analyzed.count", "roomType", "stue"],
            [local.cw_namespace, "wishifai.images.analyzed.count", "roomType", "barnerom"],
            [local.cw_namespace, "wishifai.images.analyzed.count", "roomType", "garasje"],
            [local.cw_namespace, "wishifai.images.analyzed.count", "roomType", "annet"],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Business: foreslåtte gaver og parse-feil"
          region = local.cw_region
          stat   = "Sum"
          period = 60
          view   = "timeSeries"
          metrics = [
            [local.cw_namespace, "wishifai.gifts.suggested.count"],
            [local.cw_namespace, "wishifai.bedrock.parse.failures.count"],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "Applikasjon: Bedrock og Rekognition (ms)"
          region = local.cw_region
          period = 60
          view   = "timeSeries"
          metrics = [
            [local.cw_namespace, "wishifai.bedrock.duration.avg", { stat = "Average", label = "Bedrock snitt" }],
            [local.cw_namespace, "wishifai.bedrock.duration.max", { stat = "Maximum", label = "Bedrock maks" }],
            [local.cw_namespace, "wishifai.rekognition.duration.avg", { stat = "Average", label = "Rekognition snitt", yAxis = "right" }],
            [local.cw_namespace, "wishifai.rekognition.duration.max", { stat = "Maximum", label = "Rekognition maks", yAxis = "right" }],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Applikasjon: HTTP-latens (snitt)"
          region = local.cw_region
          period = 60
          view   = "timeSeries"
          metrics = [
            [{
              expression = "SEARCH('{wishifai,error,exception,method,outcome,status,uri} MetricName=\"http.server.requests.avg\"', 'Average', 60)"
              id         = "http1"
            }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "Applikasjon: JVM heap brukt"
          region = local.cw_region
          period = 60
          view   = "timeSeries"
          metrics = [
            [{
              expression = "SEARCH('{wishifai,area,id} MetricName=\"jvm.memory.used.value\" area=\"heap\"', 'Average', 60)"
              id         = "jvm1"
            }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 12, width = 12, height = 6
        properties = {
          title  = "Applikasjon: GC-pauser (snitt)"
          region = local.cw_region
          period = 60
          view   = "timeSeries"
          metrics = [
            [{
              expression = "SEARCH('{wishifai,action,cause,gc} MetricName=\"jvm.gc.pause.avg\"', 'Average', 60)"
              id         = "gc1"
            }]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 18, width = 12, height = 6
        properties = {
          title  = "Infrastruktur: ECS CPU og minne (%)"
          region = local.cw_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.ecs_cluster, "ServiceName", local.ecs_service],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.ecs_cluster, "ServiceName", local.ecs_service],
          ]
        }
      },
      {
        type = "metric", x = 12, y = 18, width = 12, height = 6
        properties = {
          title  = "Infrastruktur: antall tasks"
          region = local.cw_region
          stat   = "Average"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ECS", "LiveTaskCount", "ClusterName", local.ecs_cluster, "ServiceName", local.ecs_service],
          ]
        }
      },
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishifai-9-bedrock-treg"
  alarm_description   = "Gjennomsnittlig Bedrock-svartid over 20 sekunder"
  namespace           = local.cw_namespace
  metric_name         = "wishifai.bedrock.duration.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 20000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}