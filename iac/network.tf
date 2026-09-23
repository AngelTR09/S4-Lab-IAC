resource "docker_network" "env" {
  for_each = local.environments
  name     = "iac-lab04-${each.key}"
}
