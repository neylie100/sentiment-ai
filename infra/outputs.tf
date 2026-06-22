output "container_id" {
  value       = docker_container.sentiment_staging.id
  description = "ID du conteneur de Staging"
}

output "staging_url" {
  value       = "http://localhost:8001/health"
  description = "URL de test de l'API de Staging"
}
