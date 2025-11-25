# ci/run-checkov.sh
#!/usr/bin/env bash
set -euo pipefail

# Ruta al root del repo (carpeta donde está el Jenkinsfile)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# En este proyecto, la IAC está en /infra (no /terraform)
cd "${ROOT_DIR}/infra"

echo "Directorio actual (Terraform root): $(pwd)"
echo "Ejecutando Checkov..."

# Modo "soft-fail": reporta findings pero NO devuelve exit code 1
checkov -d . --quiet --soft-fail

echo "Checkov finalizado (puede haber findings, pero no rompen el pipeline)."