#!/bin/bash

set -e

PROJECT_DIR="/opt/odoo/odoo-docker-develop-deploy"
OCA_FILE="$PROJECT_DIR/OCA.txt"
CUSTOM_FILE="$PROJECT_DIR/custom.txt"
ADDONS_DIR="/opt/odoo"
OCA_DIR="$ADDONS_DIR/oca_modules"
CUSTOM_DIR="$ADDONS_DIR/custom_modules"
ODOO_CONF="$PROJECT_DIR/config/odoo.conf"

# Verificar si Docker está instalado, si no lo está, instalarlo
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# Verificar si Docker Compose está instalado, si no lo está, instalarlo
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    sudo apt-get install -y docker-compose
fi

# Crear directorios necesarios
mkdir -p "$OCA_DIR" "$CUSTOM_DIR" "$PROJECT_DIR/config" "$PROJECT_DIR/postgresql-data"

# Descargar los repositorios de OCA
echo "Descargando repositorios OCA..."
while read -r repo_url; do
    repo_name=$(basename "$repo_url" .git)
    target_dir="$OCA_DIR/$repo_name"
    if [ -d "$target_dir" ]; then
        echo "Actualizando $repo_name..."
        git -C "$target_dir" pull
    else
        echo "Clonando $repo_name..."
        git clone "$repo_url" "$target_dir"
    fi
done < "$OCA_FILE"

# Descargar los repositorios personalizados
echo "Descargando repositorios personalizados..."
while read -r repo_url; do
    repo_name=$(basename "$repo_url" .git)
    target_dir="$CUSTOM_DIR/$repo_name"
    if [ -d "$target_dir" ]; then
        echo "Actualizando $repo_name..."
        git -C "$target_dir" pull
    else
        echo "Clonando $repo_name..."
        git clone "$repo_url" "$target_dir"
    fi
done < "$CUSTOM_FILE"

# Generar archivo odoo.conf
echo "Generando archivo odoo.conf..."
ADDONS_PATH=$(find "$OCA_DIR" "$CUSTOM_DIR" -mindepth 1 -maxdepth 1 -type d | paste -sd "," -)

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

# Levantar los contenedores
echo "Levantando entorno Odoo..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "✅ Despliegue completo."
