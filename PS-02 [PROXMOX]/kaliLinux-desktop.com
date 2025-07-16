# acceso a entorno grafico Kali a través de navegador
Crear contenedor Kali Linux (LXC o Docker).
Instalar entorno gráfico (Xfce, LXDE, etc.) en Kali.
Instalar y configurar un servidor VNC o RDP con acceso web, por ejemplo:
noVNC (VNC sobre WebSocket y HTML5)
xrdp + un gateway web (Guacamole)
Exponer el servicio en un puerto accesible desde navegador.
Acceder desde cualquier navegador apuntando a la IP:puerto.
