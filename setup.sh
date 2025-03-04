#!/bin/bash

set -e

PROJECT_DIR="/opt/odoo/odoo-docker-develop-deploy"
OCA_FILE="$PROJECT_DIR/OCA.txt"
CUSTOM_FILE="$PROJECT_DIR/custom.txt"
OCA_DIR="/opt/oca_modules"
CUSTOM_DIR="/opt/custom_modules"

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

# Verificar si el archivo OCA.txt tiene contenido
if [ -s "$OCA_FILE" ]; then
    # Descargar los repositorios de OCA
    echo "Descargando repositorios OCA..."
    while read -r repo_url; do
        repo_name=$(basename "$repo_url" .git)
        target_dir="$OCA_DIR/$repo_name"

        if [ -d "$target_dir" ]; then
            echo "Actualizando $repo_name..."
            git -C "$target_dir" pull  # Actualiza el repositorio existente
        else
            echo "Clonando $repo_name..."
            git clone "$repo_url" "$target_dir"  # Clona el repositorio si no existe
        fi
    done < "$OCA_FILE"
else
    echo "No se encontraron repositorios OCA en $OCA_FILE. Saltando descarga."
fi

# Verificar si el archivo custom.txt tiene contenido
if [ -s "$CUSTOM_FILE" ]; then
    # Descargar los repositorios personalizados
    echo "Descargando repositorios personalizados..."
    while read -r repo_url; do
        repo_name=$(basename "$repo_url" .git)
        target_dir="$CUSTOM_DIR/$repo_name"

        if [ -d "$target_dir" ]; then
            echo "Actualizando $repo_name..."
            git -C "$target_dir" pull  # Actualiza el repositorio existente
        else
            echo "Clonando $repo_name..."
            git clone "$repo_url" "$target_dir"  # Clona el repositorio si no existe
        fi
    done < "$CUSTOM_FILE"
else
    echo "No se encontraron repositorios personalizados en $CUSTOM_FILE. Saltando descarga."
fi

# Levantar los contenedores
echo "Levantando entorno Odoo..."
docker-compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "✅ Despliegue completo."
