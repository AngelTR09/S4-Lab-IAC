resource "docker_image" "postgres" {
  name = var.postgres_image
}

resource "docker_container" "db" {
  for_each = local.environments
  name     = "bd-${each.key}"
  image    = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.env[each.key].name
  }

  ports {
    internal = 5432
    external = each.value.db_port
  }

  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]
}
