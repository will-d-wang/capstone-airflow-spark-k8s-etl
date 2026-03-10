output "namespace" {
  value = kubernetes_namespace_v1.pipeline.metadata[0].name
}

output "s3_endpoint" {
  value = local.s3_endpoint
}
