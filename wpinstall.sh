#!/bin/bash
set -e

# ===== Кольори =====
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${YELLOW}→ Downloading WordPress...${NC}"
cd /home/
wget -q https://wordpress.org/latest.zip -O latest.zip
unzip -q latest.zip

# Права
chown -R 33:33 /home/wordpress
find /home/wordpress -type d -exec chmod 755 {} \;
find /home/wordpress -type f -exec chmod 644 {} \;

# ===== Генерація паролів =====
MYSQL_ROOT_PASS=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
WP_DB=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
WP_USER=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
WP_PASS=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 16)

# ===== Ввід параметрів =====
echo
read -rp "Domain (без http://): " DOMAIN
read -rp "Site Name: " SITE_TITLE
read -rp "Admin Login: " ADMIN_USER
read -rp "Admin Password: " ADMIN_PASS
read -rp "Admin Email: " ADMIN_EMAIL


# ===== PHP-FPM Dockerfile =====
cat > php-fpm-dockerfile <<'EOF'
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libonig-dev \
        unzip \
        curl \
        sudo \
        mariadb-client \
    && docker-php-ext-install zip pdo pdo_mysql mysqli gd mbstring \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/bin:/usr/local/bin:${PATH}"
EOF

# ===== nginx.conf =====
cat > nginx.conf <<'EOF'
server {
    listen 80;
    server_name hosted-domain;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF


sed -i "s/hosted-domain/${DOMAIN}/" nginx.conf

# ===== docker-compose.yaml =====
cat > docker-compose.yaml <<EOF
version: '3.8'

services:
  mysql:
    image: mysql:8
    container_name: mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASS}
      MYSQL_DATABASE: ${WP_DB}
      MYSQL_USER: ${WP_USER}
      MYSQL_PASSWORD: ${WP_PASS}
    volumes:
      - /home/db:/var/lib/mysql
      - /home/server.cnf:/etc/mysql/conf.d/server.cnf:ro
    ports:
      - "3306:3306"

  redis:
    image: redis:latest
    container_name: redis

  php-fpm:
    build:
      context: .
      dockerfile: php-fpm-dockerfile
    container_name: php-fpm
    volumes:
      - /home/wordpress:/var/www/html

  nginx:
    image: nginx:latest
    container_name: nginx
    volumes:
      - /home/wordpress:/var/www/html
      - /home/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "80:80"
      - "443:443"
EOF


cat > /home/server.cnf <<EOF
[mysqld]
sql-mode=""
EOF

# ===== Запуск Docker =====
echo -e "${YELLOW}→ Running Docker Compose...${NC}"
docker compose up -d

echo -e "${YELLOW}→ Waiting for MySQL start...${NC}"
sleep 25

# ===== Встановлення WP-CLI =====
echo -e "${YELLOW}→ WP-CLI Installation...${NC}"
docker exec -i php-fpm bash -c "
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar &&
chmod +x wp-cli.phar &&
mv wp-cli.phar /usr/local/bin/wp
"

# ===== Cretaion wp-config and WordPress installation =====
echo -e "${YELLOW}→ WordPress Initialisation over...${NC}"
docker exec -i php-fpm bash -c "
cd /var/www/html &&
wp config create \
  --dbname='${WP_DB}' \
  --dbuser='${WP_USER}' \
  --dbpass='${WP_PASS}' \
  --dbhost='mysql' \
  --allow-root &&
wp core install \
  --url='http://${DOMAIN}' \
  --title='${SITE_TITLE}' \
  --admin_user='${ADMIN_USER}' \
  --admin_password='${ADMIN_PASS}' \
  --admin_email='${ADMIN_EMAIL}' \
  --skip-email \
  --allow-root
"

echo -e "${GREEN}✅ WordPress succesfully installed!"
echo -e "${GREEN}URL: http://${DOMAIN}"
echo -e "${GREEN}Admin Login Details: ${ADMIN_USER} / ${ADMIN_PASS}${NC}"

