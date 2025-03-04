# Odoo Docker Dev

Despliegue automático de Odoo para desarrollo con Docker y módulos externos desde GitHub.

## 🚀 Instalación rápida

```bash
git clone https://github.com/TU_USUARIO/odoo-docker-dev.git /opt/odoo-docker-dev
cd /opt/odoo-docker-dev
chmod +x setup.sh
./setup.sh
```

Accede en [http://localhost:8069](http://localhost:8069)

## ⚙️ Personalización

Edita `requirements.txt` para agregar más repositorios OCA o personalizados.

Los módulos se descargan automáticamente en cada ejecución del script.
