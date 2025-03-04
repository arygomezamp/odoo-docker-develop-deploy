#!/bin/bash

set -e

PROJECT_DIR="/opt/odoo/odoo-docker-develop-deploy"
REQUIREMENTS_FILE="$PROJECT_DIR/requirements.txt"
ADDONS_DIR="$PROJECT_DIR/addons"
ODOO_CONF="$PROJECT_DIR/config/odoo.conf"

if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    sudo apt-get install -y docker-compose
fi

mkdir -p "$ADDONS_DIR" "$PROJECT_DIR/config" "$PROJECT_DIR/postgresql-data"

echo "Descargando repositorios..."
while read -r repo_url; do
    repo_name=$(basename "$repo_url" .git)
    target_dir="$ADDONS_DIR/$repo_name"
    if [ -d "$target_dir" ]; then
        echo "Actualizando $repo_name..."
        git -C "$target_dir" pull
    else
        echo "Clonando $repo_name..."
        git clone "$repo_url" "$target_dir"
    fi
done < "$REQUIREMENTS_FILE"

echo "Generando odoo.conf..."
ADDONS_PATH=$(find "$ADDONS_DIR" -mindepth 1 -maxdepth 1 -type d | paste -sd "," -)

cat > "$ODOO_CONF" <<EOF
[options]
addons_path = $ADDONS_PATH
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
admin_passwd = admin
log_level = debug
EOF

echo "Levantando entorno Odoo..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "✅ Despliegue completo."
