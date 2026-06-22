terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "cicd" {
  name = "cicd-network"
}

resource "docker_image" "sentiment" {
  name         = "ghcr.io/stella/sentiment-ai:${var.image_tag}"
  keep_locally = true
}

resource "docker_container" "sentiment_staging" {
  name  = "sentiment-staging"
  image = docker_image.sentiment.image_id
  
  networks_advanced {
    name = docker_network.cicd.name
  }

  ports {
    internal = 8000
    external = 8001
  }
}
