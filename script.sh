#!/bin/bash

# Descripción del script
echo "Este script configura un entorno de Mosquitto MQTT utilizando Docker Compose. Creado por clixx02"
echo "Borra cualquier contenedor existente en el directorio /prj (este valor puede ser cambiado),crea la estructura de archivos necesaria"
echo "y solicita al usuario que ingrese una contraseña para el usuario 'admin' (este valor puede ser cambiado) en Mosquitto."
echo "Finalmente, inicia los contenedores Mosquitto y muestra el estado del servicio."

# Pedir confirmación al usuario
read -p "¿Estás seguro de que deseas ejecutar este script? (Ingresa 's' para confirmar): " confirmacion

if [ "$confirmacion" != "s" ]; then
    echo "Adiós."
    exit 1
fi

# Definir variables
user="admin"
project_dir="/prj"

# Detener contenedores existentes en el directorio $project_dir
(cd "$project_dir" && sudo docker-compose down > /dev/null)

# Cambiar al directorio $project_dir
cd "$project_dir" || exit

# Instalar mosquitto-clients si no está instalado
sudo apt update > /dev/null
sudo apt install -yq mosquitto-clients > /dev/null

# Borrar la carpeta /prj si existe
sudo rm -rf "$project_dir"

# Crear la carpeta /prj
sudo mkdir "$project_dir"

# Crear archivos docker-compose.yml, mosquitto.conf y passwd
echo "version: '3'

services:
  mosquitto:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    restart: always
    volumes:
      - ./mosquitto.conf:$project_dir/mosquitto.conf
      - ./passwd:$project_dir/passwd
    ports:
      - '1883:1883'
    command: /docker-entrypoint.sh mosquitto -c $project_dir/mosquitto.conf" | sudo tee "$project_dir/docker-compose.yml" > /dev/null

echo "listener 1883"
allow_anonymous false
password_file $project_dir/passwd" | sudo tee "$project_dir/mosquitto.conf" > /dev/null

sudo touch "$project_dir/passwd"
sudo chmod 777 "$project_dir/passwd"

# Crear usuario y contraseña para Mosquitto en el directorio $project_dir
echo Creando el usuario $user ...
sudo docker run -it --rm -v $project_dir:$project_dir eclipse-mosquitto mosquitto_passwd -c $project_dir/passwd $user

# Cambiar al directorio original
cd - > /dev/null || exit

# Mostrar la salida solo del comando anterior
(cd "$project_dir" && sudo docker-compose up -d)
