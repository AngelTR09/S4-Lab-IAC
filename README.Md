# IAC-LAB04

Laboratorio de la asignatura ISIA-107 (Infraestructura como Código, UPAO).
Usa Terraform (provider kreuzwerker/docker) para levantar, en Docker
local, dos entornos aislados y en paralelo, DEV y QA, cada uno con tres
contenedores: frontend (nginx), backend (Node) y base de datos
(PostgreSQL 17).

## Arquitectura

Cada entorno tiene su propia red Docker, así que DEV y QA no se ven
entre sí. Dentro de cada entorno, los contenedores se resuelven por
nombre (bd-dev, bd-qa, etc.) gracias al DNS interno de la red de
Docker. web-* habla con api-*, y api-* habla con bd-* usando el nombre
del contenedor de base de datos como host.

Puertos publicados en el host:

- DEV: web-dev 4001, api-dev 4002, bd-dev 4003
- QA: web-qa 5001, api-qa 5002, bd-qa 5003

## Estructura del repositorio

- iac/providers.tf: terraform{} + provider "docker"
- iac/variables.tf: variables de puertos/BD + locals.environments
- iac/network.tf: docker_network, una por entorno
- iac/db-server.tf: docker_image + docker_container de Postgres
- iac/api-server.tf: docker_image + docker_container del backend
- iac/web-server.tf: docker_image + docker_container del frontend
- iac/outputs.tf: output "urls"
- iac/terraform.tfvars.example: plantilla de variables, sin secretos reales
- backend/: Dockerfile (node:20-alpine) + index.js + package.json
- frontend/: Dockerfile (nginx:alpine) + index.html

iac/terraform.tfvars, con los valores reales incluida la contraseña de
la BD, no se commitea, está en .gitignore porque contiene un secreto.
Se genera localmente copiando el .example.

## Prerrequisitos

- Terraform >= 1.x
- Docker Engine corriendo localmente (el provider usa el socket de Docker)

## Variables (iac/variables.tf)

- dev_web_port / dev_api_port / dev_db_port: puertos en el host para DEV. Default 4001 / 4002 / 4003.
- qa_web_port / qa_api_port / qa_db_port: puertos en el host para QA. Default 5001 / 5002 / 5003.
- frontend_build_path: carpeta con el Dockerfile del frontend. Default ../frontend.
- backend_build_path: carpeta con el Dockerfile del backend. Default ../backend.
- postgres_image: imagen oficial de Postgres, se descarga en vez de construirse. Default postgres:17.
- db_name / db_user / db_password: credenciales de Postgres. No tienen default, son obligatorias y se definen en terraform.tfvars.

Un bloque locals en el mismo archivo reensambla los seis puertos
escalares en el mapa dev/qa que usan los for_each de network.tf,
db-server.tf, api-server.tf y web-server.tf. Así se evita duplicar
cada bloque de recurso una vez para DEV y otra para QA.

Para configurar tus valores:

```bash
cd iac
cp terraform.tfvars.example terraform.tfvars
# edita terraform.tfvars y pon tu propio db_password
```

terraform plan/apply cargan terraform.tfvars automáticamente, no hace
falta -var-file ni exportar variables de entorno.

## Qué hace cada archivo .tf

providers.tf declara el provider kreuzwerker/docker v4.6.0 y lo
instancia sin configuración extra, usa el socket Docker local por
defecto.

network.tf tiene un docker_network con for_each = local.environments,
crea iac-lab04-dev e iac-lab04-qa. Es lo que aísla ambos entornos
entre sí.

db-server.tf tiene dos recursos. docker_image.postgres descarga
postgres:17 de Docker Hub, sin bloque build, así que el provider hace
pull en vez de construir. docker_container.db crea un contenedor
bd-dev/bd-qa por entorno, conectado a la red de su propio entorno, con
el puerto 5432 publicado en el puerto de host correspondiente, e
inicializado con POSTGRES_DB/POSTGRES_USER/POSTGRES_PASSWORD desde las
variables db_*.

api-server.tf construye la imagen del backend una sola vez (el
contenido no cambia entre entornos) y crea un contenedor api-dev/api-qa
por entorno, puerto interno 3000 publicado en el puerto de host
correspondiente, con la variable de entorno DATABASE_URL apuntando a
postgresql://user:pass@bd-<entorno>:5432/db. El host se resuelve por
DNS porque ambos contenedores comparten la red de su entorno.
depends_on fuerza que la BD se cree antes que el backend.

web-server.tf sigue el mismo patrón que el backend: build único de la
imagen de nginx, un contenedor web-dev/web-qa por entorno, puerto
interno 80 publicado en el puerto de host correspondiente, depends_on
sobre el backend.

outputs.tf imprime, al final de cada apply, la URL de cada frontend.

## Levantar todo

```bash
cd iac
terraform init
terraform plan
terraform apply
```

Al terminar, Terraform imprime algo como:

```
urls = {
  "dev" = "http://localhost:4001"
  "qa"  = "http://localhost:5001"
}
```

## Verificar el aislamiento DEV/QA y la conectividad interna

```bash
# api-dev debe poder resolver a su propia base de datos
docker exec api-dev getent hosts bd-dev

# api-dev NO debe poder resolver nada de QA, confirma el aislamiento de redes
docker exec api-dev getent hosts bd-qa

# endpoints expuestos en el host
curl http://localhost:4001   # frontend dev
curl http://localhost:4002   # backend dev
curl http://localhost:5001   # frontend qa
curl http://localhost:5002   # backend qa

# qué contenedores tiene cada red
docker network inspect iac-lab04-dev --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}'
docker network inspect iac-lab04-qa  --format '{{range .Containers}}{{.Name}}{{"\n"}}{{end}}'
```

## Apagar todo

```bash
cd iac
terraform destroy
```

## Convención de commits

El proyecto sigue Conventional Commits 1.0.0, sin coautoría. El
historial refleja la construcción incremental del stack: provider,
variables, red, base de datos, backend, frontend, outputs.
