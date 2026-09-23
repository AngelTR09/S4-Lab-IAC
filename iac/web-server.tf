resource "docker_image" "frontend" {
  name = "iac-lab04-web:latest"
  build {
    context = var.frontend_build_path
  }
}

resource "docker_container" "web" {
  for_each = local.environments
  name     = "web-${each.key}"
  image    = docker_image.frontend.image_id

  networks_advanced {
    name = docker_network.env[each.key].name
  }

  ports {
    internal = 80
    external = each.value.web_port
  }

  depends_on = [docker_container.api]
}
