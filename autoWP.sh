#!/bin/bash

# Nombre : AutoWP 
# Creador: Wvverez
# Github : https://github.com/wvverez
# Instalación LAMP + Wordpress- Kubuntu/ Ubuntu24


# VARIABLES

WP_DIR="MiWordpress"
DB_NAME="MiWordpress"
DB_USER="wpuser"
DB_PASS="Con_seña_2025!"
PHP_VERSION="8.3"

# COMPROBAR SI ES ROOT

if ["$EUID" -ne 0];then
	echo "[+] Este script debe ejecutarse como root pedazo de chorvo"
	exit 1
fi

echo "[+] Iniciando instalación LAMP + Wordpress..."


# Paso 1 ACTUALIZAR Y UPGRADEAR SISTEMA

add-apt-repository ppa:ondrej/php -y
apt update && apt upgrade -y 

# Paso 2 Instalar apache

apt install apache2 -y 
ufw allow http
ufw allow https
systemctl enable apache2
systemctl restart apache2

# Paso 3 Instalar MYSQL

apt install mysql-server -y
systemctl enable mysql
systemctl start mysql

# Paso 4 instalar php y extensiones

apt install -y \
php${PHP_VERSION} \
libapache2-mod-php${PHP_VERSION} \
php${PHP_VERSION}-mysql \
php${PHP_VERSION}-cli \
php${PHP_VERSION}-common \
php${PHP_VERSION}-curl \
php${PHP_VERSION}-xml \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-zip \
php${PHP_VERSION}-gd \
php${PHP_VERSION}-soap \
php${PHP_VERSION}-intl

systemctl restart apache2

# Paso 5 configurar mysql (BBDD + USUARIO)

mysql <<EOF
CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '{DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}'; 
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Paso 6 Descargar wordpress

apt install curl -y 
cd /tmp || exit
curl -O https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
mv wordpress /var/www/html/${WP_DIR}
rm latest.tar.gz

# Paso 7 Permisos WP

chown -R www-data:www-data /var/www/html/${WP_DIR}
chmod -R 755 /var/www/html/${WP_DIR}

# Paso 8 Configurar apache virtualhost

cat <<EOF > /etc/apache2/sites-available/${WP_DIR}.conf
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/html/${WP_DIR}
	ServerName localhost

<Directory /var/www/html/${WP_DIR}>
	Options Indexes FollowSymLinks
	AllowOverride All
	Require all granted
</Directory>

	ErrorLog \${APACHE_LOG_DIR}/${WP_DIR}_error.log
	CustomLog \${APACHE_LOG_DIR}/${WP_DIR}_access.log combined
</VirtualHost>
EOF

a2ensite ${WP_DIR}.conf
a2enmod rewrite
systemctl reload apache2
systemctl restart apache2

# Paso 9 Configurar Wordpress

cd /var/www/html/${WP_DIR} || exit
cp wp-config.php-sample.php wp-config.php

sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sed -i "s/username_here/${DB_USER}/" wp-config.php
sed -i "s/password_here/${DB_PASS}/" wp-config.php

# Paso 10 final

echo "[+] Instalación completada"
echo "---------------------------------------------"
echo "[+] Accede a Wordpress"
echo "[+] URL :  http://localhost/${WP_DIR}"
echo "[+] URL : http://${IP}/{WP_DIR}"
echo "---------------------------------------------"

echo "Acaba de completar la instalación desde el navegador..."
echo ""
echo "Wvverez estuvo por aquí..."


