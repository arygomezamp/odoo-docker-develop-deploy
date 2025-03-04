#!/bin/bash

set -e

# Definir las rutas del proyecto y las rutas fuera del proyecto para los módulos y los datos de PostgreSQL
PROJECT_DIR="/opt/odoo/odoo-docker-develop-deploy"
OCA_FILE="$PROJECT_DIR/OCA.txt"
CUSTOM_FILE="$PROJECT_DIR/custom.txt"
OCA_DIR="/opt/odoo/oca_modules"  # Fuera de la estructura del proyecto
ADDONS_DIR="/opt/odoo/custom_modules"  # Fuera de la estructura del proyecto
POSTGRESQL_DATA_DIR="/opt/odoo/postgresql-data"  # Fuera de la estructura del proyecto
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

# Crear directorios necesarios fuera del proyecto
mkdir -p "$ADDONS_DIR" "$OCA_DIR" "$POSTGRESQL_DATA_DIR" "$PROJECT_DIR/config"

# Descargar y actualizar repositorios OCA fuera del proyecto
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

# Descargar y actualizar repositorios Custom fuera del proyecto
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

# Verificar si el archivo de configuración ya existe
if [ -f "$ODOO_CONF" ]; then
    echo "Archivo de configuración odoo.conf encontrado en $ODOO_CONF."
else
    # Generar odoo.conf si no existe
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
    echo "Archivo odoo.conf generado en $ODOO_CONF."
fi

# Levantar los servicios de Docker
echo "Levantando entorno Odoo..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "✅ Despliegue completo."
