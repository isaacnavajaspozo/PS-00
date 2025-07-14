#!/bin/bash
# rclone nunca guarda tu contraseña, solo almacena tokens OAuth que permiten acceso temporal a OneDrive sin necesidad de la contraseña.

# Ve a: https://account.live.com/consent/Manage
# Busca la app autorizada como “rclone” o “Microsoft Graph”.
# Haz clic en Quitar estos permisos o Revocar acceso.

ARCHIVO="$1"
REMOTO="onedrive"
DESTINO="backup"

if [ -z "$ARCHIVO" ]; then
  echo "Uso: $0 archivo_a_subir"
  exit 1
fi

rclone copy "$ARCHIVO" "$REMOTO:$DESTINO"

if [ $? -eq 0 ]; then
  echo "Archivo '$ARCHIVO' subido correctamente a OneDrive en '$DESTINO'."
else
  echo "Error al subir '$ARCHIVO'."
fi
