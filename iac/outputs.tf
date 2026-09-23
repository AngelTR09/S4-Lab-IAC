output "urls" {
  description = "URL de cada frontend, por entorno."
  value = {
    for key, cfg in local.environments :
    key => "http://localhost:${cfg.web_port}"
  }
}
