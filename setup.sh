#!/bin/bash

set -e

PROJECT_DIR="/opt/odoo/odoo-docker-develop-deploy"
OCA_FILE="$PROJECT_DIR/OCA.txt"
CUSTOM_FILE="$PROJECT_DIR/custom.txt"
OCA_DIR="/opt/odoo/oca_modules"  # Separar directorios para OCA y Custom
ADDONS_DIR="/opt/odoo/custom_modules"
ODOO_CONF="$PROJECT_DIR/config/odoo.conf"

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# Verificar si Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    sudo apt-get install -y docker-compose
fi

# Crear directorios necesarios
mkdir -p "$ADDONS_DIR" "$OCA_DIR" "$PROJECT_DIR/config" "$PROJECT_DIR/postgresql-data"

# Descargar y actualizar repositorios OCA
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

# Descargar y actualizar repositorios Custom
echo "Descargando repositorios Custom..."
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
done < "$CUSTOM_FILE"

# Generar odoo.conf con las rutas de los addons
echo "Generando odoo.conf..."
ADDONS_PATH=$(find "$ADDONS_DIR" -mindepth 1 -maxdepth 1 -type d | paste -sd "," -)
OCA_PATH=$(find "$OCA_DIR" -mindepth 1 -maxdepth 1 -type d | paste -sd "," -)
ADDONS_ALL_PATH="$OCA_PATH,$ADDONS_PATH"  # Combina las rutas de OCA y Custom

# Escribir el archivo de configuración
cat > "$ODOO_CONF" <<EOF
[options]
addons_path = $ADDONS_ALL_PATH
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
admin_passwd = admin
log_level = debug
EOF

# Levantar los servicios de Docker
echo "Levantando entorno Odoo..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "✅ Despliegue completo."
