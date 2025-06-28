#!/bin/bash

## compruebo que los paquetes están instalados y si no los instalo
PACKAGES=("lxc" "lxc-templates" "bridge-utils" "sudo")

for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo "🔧 Instalando $pkg..."
        sudo apt update && sudo apt install -y "$pkg"
    else
        echo "✅ $pkg ya está instalado."
    fi
done

echo "✅ Paquetes instalados '$PACKAGES'"

read -p "¿Deseas agregar la configuración del brifge en el archivo /etc/network/interfaces y la configuración de los contenedores en /etc/lxc/default.conf? (s/n): " respuesta

            if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then

            echo "Interfaces disponibles:"
            ip link show | awk -F: '$0 !~ "lo|vir|^[^0-9]"{print $2}' | tr -d ' '

## preguntar por la interfaz Ethernet
read -rp "👉 Ingresa el nombre de tu interfaz Ethernet (ej. eth0, eno1, enp3s0): " ETH_INTERFACE

# Verificación simple de que la interfaz existe
            if ! ip link show "$ETH_INTERFACE" &> /dev/null; then
                echo "❌ La interfaz '$ETH_INTERFACE' no existe. Abortando."
                exit 1
            fi

            echo "✅ Interfaz seleccionada: $ETH_INTERFACE"
            
            if [ -f /etc/lxc/default.conf ]; then
                sudo mv /etc/lxc/default.conf /etc/lxc/default.conf.old
            fi

cat <<EOF > /etc/lxc/default.conf
# crea una interfaz virtual tipo veth y la conecta al bridge br0
lxc.net.0.type = veth
lxc.net.0.link = br0
lxc.net.0.flags = up

# permite perfiles AppArmor y anidamiento de contenedores
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1

# Usar systemd como PID 1
lxc.init.cmd = /lib/systemd/systemd

# Montar cgroups y sistemas necesarios
lxc.mount.auto = proc sys cgroup
lxc.mount.entry = /dev/fuse dev/fuse none bind,create=file 0 0            
EOF

            echo -e "\e[33m✅ Archivo modificado en /etc/lxc/default.conf\e[0m"
            echo -e "\e[33m✅ configurando del brifge en el archivo /etc/network/interfaces \e[0m"

                sudo tee -a /etc/network/interfaces > /dev/null <<EOF
 # Bridge que usará la IP del host
 auto br0
 iface br0 inet static
     address 192.168.1.57   # IP-DISPOSITIVO
     netmask 255.255.255.0  # MASCARA DE RED
     gateway 192.168.1.1    # PUERTA DE ENLACE
     bridge_ports $ETH_INTERFACE     
     bridge_stp off
        bridge_fd 0
        bridge_maxwait 0
dns-nameservers 8.8.8.8 1.1.1.1
EOF

            echo -e "\e[33m✅ Para completar la configuración entra en el archivo /etc/network/interfaces y termina de configurar del bridge con tus datos de red \e[0m"
            echo -e "\e[33m✅ Una vez configurado el archivo recuerda reiniciar \e[0m"
            else
                echo -e "\e[33m✅ Saliendo de la configuración sin modificar los archivos de configuración. \e[0m"
            fi

cat <<'EOF' > /usr/bin/kiribako
#!/bin/bash

# Función para mostrar el menú
mostrar_menu() {
    # Mostrar estado actual de los contenedores
    echo "Estado actual de los contenedores:"
    lxc-ls --fancy
    echo ""

RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED} ____  __..__         .__ ___.             __      "
echo -e "|    |/ _||__|_______ |__|\\_ |__  _____   |  | __  ____"
echo -e "|      /  |  |\\_  __ \\|  | | __ \\ \\__  \\  |  |/ / /  _ \\ "
echo -e "|    |  \\ |  | |  | \\/|  | | \\_\\ \\ / __ \\_|    < (  <_> )"
echo -e "|____|__ \\|__| |__|   |__| |___  /(____  /|__|_ \\ \\____/ "
echo -e "        \\/                     \\/      \\/      \\/        ${NC}"

    # Mostrar menú de opciones
    echo "¿Qué deseas hacer?"
    echo "1) Crear una nueva máquina"
    echo "2) Iniciar una máquina en segundo plano"
    echo "3) Acceder a una máquina"
    echo "4) Parar una máquina"
    echo "5) Eliminar una máquina"
    echo "6) Salir"
    read -p "Elige una opción [1-6]: " opcion

    case $opcion in
        1)
            # Selección del tipo de sistema operativo
            echo "¿Qué sistema operativo deseas para la máquina?"
            echo "1) Debian"
            echo "2) Ubuntu"
            echo "3) Kali"
            read -p "Elige una opción [1-3]: " so

            case $so in
                1)
                    tipo_so="debian"
                    ;;
                2)
                    tipo_so="ubuntu"
                    ;;
                3)
                    tipo_so="kali"
                    ;;
                *)
                    echo "Opción no válida. Se usará Debian por defecto."
                    tipo_so="debian"
                    ;;
            esac

            # Nombre de la nueva máquina
            read -p "Introduce el nombre de la nueva máquina: " nombre
            sudo lxc-create -n "$nombre" -t "$tipo_so"
            ;;
        2)
            read -p "Introduce el nombre de la máquina a iniciar: " nombre
            sudo lxc-start -n "$nombre" -d
            ;;
        3)
            read -p "Introduce el nombre de la máquina a la que quieres acceder: " nombre
            sudo lxc-attach -n "$nombre"
            ;;
        4)
            read -p "Introduce el nombre de la máquina que deseas parar: " nombre
            sudo lxc-stop -n "$nombre"
            ;;
        5)
            read -p "Introduce el nombre de la máquina que deseas eliminar: " nombre
            sudo lxc-destroy -n "$nombre"
            ;;
        6)
            echo "Saliendo del script..."
            exit 0
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Bucle que muestra el menú hasta que el usuario decida salir
while true; do
    mostrar_menu
done
EOF

sudo chmod 770 /usr/bin/kiribako

echo -e "\e[33m✅ Termina de modificar el archivo '/etc/network/interfaces', reinicia y utiliza directamente el comando kiribako. \e[0m"
