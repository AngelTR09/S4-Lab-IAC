resource "docker_image" "backend" {
  name = "iac-lab04-api:latest"
  build {
    context = var.backend_build_path
  }
}

resource "docker_container" "api" {
  for_each = local.environments
  name     = "api-${each.key}"
  image    = docker_image.backend.image_id

  networks_advanced {
    name = docker_network.env[each.key].name
  }

  ports {
    internal = 3000
    external = each.value.api_port
  }

  env = [
    "DATABASE_URL=postgresql://${var.db_user}:${var.db_password}@${docker_container.db[each.key].name}:5432/${var.db_name}",
  ]

  depends_on = [docker_container.db]
}
