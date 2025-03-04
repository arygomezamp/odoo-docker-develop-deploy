# Odoo Docker Dev

Despliegue automático de Odoo para desarrollo con Docker y módulos externos desde GitHub.

## 🚀 Instalación rápida

```bash
git clone git@github.com:arygomezamp/odoo-docker-develop-deploy.git /opt/odoo-docker-develop-deploy
cd /opt/odoo-docker-develop-deploy
chmod +x setup.sh
./setup.sh
```

Accede en [http://localhost:8069](http://localhost:8069)

## ⚙️ Personalización

Edita `requirements.txt` para agregar más repositorios OCA o personalizados.

Los módulos se descargan automáticamente en cada ejecución del script.
