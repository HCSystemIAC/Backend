# IAC ISSA — Infraestructura en AWS con Terraform

Proyecto **Infrastructure as Code (IaC)** para desplegar un backend serverless en AWS con **Terraform**.  
Incluye VPC privada, KMS, Aurora PostgreSQL Serverless v2, RDS Proxy, S3 (frontend y adjuntos), Cognito, Lambdas (5 funciones), API Gateway (pendiente), observabilidad base y CloudTrail.

---

## Estructura del repo

```
.
├─ backend/                 # Código fuente de las lambdas (app.py por carpeta)
│  ├─ pacientes/
│  ├─ historias/
│  ├─ episodios/
│  ├─ adjuntos/
│  └─ auditoria/
├─ infra/
│  ├─ modules/              # Módulos reutilizables de Terraform
│  │  ├─ networking/        # VPC privada + SGs + rútas
│  │  ├─ kms/               # Claves KMS (db, adjuntos, lambda env)
│  │  ├─ rds_aurora/        # Aurora PostgreSQL + Secret de master
│  │  ├─ rds_proxy/         # RDS Proxy
│  │  ├─ s3_frontend/       # Bucket para SPA (privado)
│  │  ├─ cloudfront_spa/    # (opcional) CDN para SPA
│  │  ├─ s3_adjuntos/       # Bucket para adjuntos (SSE-KMS + data events)
│  │  ├─ cognito/           # User Pool + Hosted UI + AppClient
│  │  ├─ lambda_function/   # Rol, empaquetado y despliegue de 5 Lambdas
│  │  ├─ apigw/             # API Gateway (pendiente de activar)
│  │  ├─ observability/     # Alarmas CW + SNS
│  │  └─ cloudtrail/        # CloudTrail Mgmt + Data Events (adjuntos)
│  └─ envs/
│     └─ dev/               # Orquestación del entorno dev
│        ├─ main.tf         # Orquestación de todos los módulos
│        ├─ variables.tf    # Variables del entorno dev
│        ├─ outputs.tf      # (opcional) puedes separar los outputs aquí
│        ├─ terraform.tfvars.example
│        └─ backend.tf      # Backend de estado remoto (S3 + DynamoDB)
├─ test/lambda/             # Eventos de prueba para invocar lambdas por CLI
│  ├─ health.json
│  ├─ pacientes_get.json
│  ├─ historias_post.json
└─ Makefile / ci/ / docs/   # utilidades varias
```

---

## Arquitectura (resumen)

- **VPC privada** con 2 subredes privadas (AZ A/B).  
- **Aurora PostgreSQL Serverless v2** (cluster + writer).  
- **RDS Proxy** apuntando al cluster Aurora, con IAM Role para leer el **Secret** (credenciales master en Secrets Manager).  
- **KMS**: claves para DB, adjuntos y variables de entorno de Lambdas.  
- **Lambdas (5)**: `pacientes`, `historias`, `episodios`, `adjuntos`, `auditoria`.  
- **S3**: bucket de frontend (privado) y bucket de **adjuntos** con cifrado SSE-KMS.  
- **Cognito**: autenticación con Hosted UI y PKCE (pendiente usar en API).  
- **API Gateway**: (aún por activar en dev; el módulo ya está listo).  
- **Observabilidad**: log groups + alarmas base.  
- **CloudTrail**: management events + data events sobre bucket de adjuntos.

---

## Requisitos

- **Terraform** ≥ 1.6  
- **AWS CLI** ≥ 2.9  
- Cuenta y credenciales de AWS con permisos para los servicios descritos
- En Windows PowerShell:
  ```powershell
  choco install terraform awscli -y
  ```

---

## Credenciales y perfil

Configura un perfil, p. ej. `hc-dev`:

```powershell
aws configure --profile hc-dev
# AWS Access Key ID: <tu_access_key>
# AWS Secret Access Key: <tu_secret_key>
# Default region name: us-east-1
# Default output format: json

$env:AWS_PROFILE = "hc-dev"
$env:AWS_REGION  = "us-east-1"
aws sts get-caller-identity    # Verifica que responde
```

> Si usas SSO, ejecuta `aws configure sso` y luego `aws sso login --profile hc-dev`.

---

## Backend de estado (S3 + DynamoDB)

El estado remoto se define en `infra/envs/dev/backend.tf`.  
Asegúrate de que existan **bucket** y **tabla DynamoDB** definidos ahí (nombres y región).  
Si cambiaste de cuenta/region, ajusta esos valores y crea el bucket/tabla si no existen.

---

## Variables del entorno (dev)

Copia el ejemplo y rellena:

```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Abre y completa: CIDRs, dominios de Cognito/CloudFront, alias KMS, etc.
```

Valores típicos:

```hcl
project              = "HC"
env                  = "dev"
owner                = "Platform"
data_class           = "PHI"

region               = "us-east-1"
vpc_cidr             = "10.20.0.0/16"
azs                  = ["us-east-1a","us-east-1b"]
private_subnet_cidrs = ["10.20.10.0/24","10.20.20.0/24"]

db_engine_version        = "15.5"
db_username              = "hc_admin"
db_password              = "TuPasswordSegura123!"
db_min_capacity          = 0.5
db_max_capacity          = 2
db_backup_retention_days = 7

kms_alias_db         = "alias/hc-db"
kms_alias_adjuntos   = "alias/hc-adjuntos"
kms_alias_lambda_env = "alias/hc-lambda-env"

s3_frontend_bucket = "hc-frontend-dev-<ACCOUNT_ID>"
s3_adjuntos_bucket = "hc-adjuntos-dev-<ACCOUNT_ID>"

apigw_stage_name   = "dev"
alarm_email        = "tu@correo.com"
```

---

## Despliegue (init → plan → apply)

```bash
cd infra/envs/dev

# Inicializar/actualizar proveedores y backend
terraform init -upgrade

# Validar sintaxis
terraform validate

# Ver plan
terraform plan -out=tfplan.all

# Aplicar
terraform apply "tfplan.all"
```

> El primer `apply` tarda: Aurora Serverless v2 puede demorar ~5–10 min.

### Salidas (outputs)

En este punto, verás `frontend_bucket` y, cuando actives CloudFront/Cognito/APIGW, tendrás sus dominios/IDs en los outputs.

---

## Probar Lambdas sin API Gateway

1) **Ver nombres creados**
```bash
aws lambda list-functions --query "Functions[?starts_with(FunctionName,'hc-dev-lambda')].FunctionName"
```

2) **Invocar** (desde la raíz del repo)
```powershell
aws lambda invoke `
  --function-name hc-dev-lambda-pacientes `
  --cli-binary-format raw-in-base64-out `
  --payload fileb://test\lambda\health.json `
  out.json; Get-Content .\out.json
```

Archivos de ejemplo en `test/lambda`:
- `health.json` – prueba simple
- `pacientes_get.json` – simula GET
- `historias_post.json` – simula POST

> Si recibes `UnrecognizedClientException` o `InvalidClientTokenId`, revisa `$env:AWS_PROFILE` y región.

---

## Destrucción controlada (destroy)

```bash
cd infra/envs/dev

terraform plan -destroy -out=tfplan.destroy
terraform apply "tfplan.destroy"
```

### Nota sobre Secrets Manager
Para evitar “zombies” (secrets en **scheduled deletion** que bloquean futuros `apply` con el mismo nombre), el recurso del secret de DB usa:

```hcl
force_delete_without_recovery = true
```

Así, al hacer `destroy` se borra **sin** ventana de recuperación y no bloquea el próximo `apply`.

Si **ya** te aparece el error:
```
InvalidRequestException: ... already scheduled for deletion
```
Solución rápida:

```powershell
$secretName = "HC-dev-db-master"
$arn = aws secretsmanager list-secrets --query "SecretList[?Name=='$secretName'].ARN | [0]" --output text
aws secretsmanager restore-secret --secret-id $arn
terraform import "module.rds_aurora.aws_secretsmanager_secret.db_master" $arn
terraform plan -out=tfplan.all
terraform apply "tfplan.all"
```

---

## Problemas frecuentes y cómo resolverlos

### 1) State lock en S3
```
Error acquiring the state lock ... PreconditionFailed
```
- Asegúrate de estar usando **la misma región** del bucket de estado.  
- Si no hay nadie aplicando y persiste:
  ```bash
  terraform force-unlock -force <LOCK_ID>
  aws s3api head-object --bucket <bucket> --key envs/dev/terraform.tfstate.tflock
  ```
  Si el objeto no existe, el unlock suele quedar resuelto.

### 2) Fallos de red durante apply (S3 / RDS “no such host”)
- Suele ser conectividad DNS o cambios de perfil/región a mitad de un apply.  
- Repite `terraform plan` y `terraform apply`.  
- Si se generó `errored.tfstate`, puedes empujarlo:
  ```bash
  terraform state push errored.tfstate
  ```

### 3) El editor subraya `force_delete_without_recovery`
- Es un **falso positivo** del esquema local. Ejecuta `terraform init -upgrade`.  
- El atributo existe en provider AWS v5.x.

---

## Presentación rápida (script sugerido)

1. **Mostrar credenciales activas**
   ```bash
   aws sts get-caller-identity
   ```

2. **`init`, `plan` y `apply`** (explicar módulos que se crearán).

3. **Comprobar outputs** y recursos: VPC, KMS, Aurora, RDS Proxy, buckets.

4. **Invocar lambdas** con `test/lambda/health.json` y con `pacientes_get.json`.

5. **`plan -destroy` y `apply destroy`** (explicar `force_delete_without_recovery`).

---

## Costos

- Aurora Serverless v2, S3, CloudWatch y Cognito pueden generar **cargos mínimos**.  
- Para evitar costos, **destruye** el entorno al finalizar: `terraform destroy`.

---

## ¿Qué es cada archivo Terraform?

- **`main.tf`**: orquestación; llama y encadena módulos.  
- **`variables.tf`**: define entradas configurables del entorno.  
- **`outputs.tf`**: expone valores útiles (dominios, ARNs, endpoints).  
- **`terraform.tfvars`**: valores concretos para `variables.tf` (no subir secretos).  
- **`backend.tf`**: configuración del **estado remoto** (S3 + DynamoDB).  
- **`providers.tf` / `versions.tf`** (si los separas): definición de provider AWS y versiones/constraints de Terraform y providers.

---

## Flujo de ramas (sugerido)

- `main` → estable.  
- `feature/<tema>` → cambios por componente (p. ej. `feature/aurora-proxy`, `feature/lambdas`).  
- Pull Request → revisión, squash merge → `main`.

---

## Licencia

Uso académico/demostrativo.

---

## Soporte

Si necesitas ayuda con un error concreto, copia el **mensaje completo** de Terraform/AWS CLI y el **módulo/archivo** relacionado para darte una corrección inmediata.
