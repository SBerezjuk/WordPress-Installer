# WordPress-Installer
# WordPress Docker Auto Installer

A Bash script for fast, automated deployment of WordPress on a clean server using Docker Compose.
The script provisions a complete WordPress stack in a single run with minimal manual input.

# What the script does

# The script automatically:

Downloads and extracts the latest WordPress release
Sets correct file ownership and permissions

# Generates secure random credentials for:
MySQL root password
WordPress database name
WordPress database user
WordPress database password

# Prompts the user for:

Domain name
Site title
WordPress admin credentials

# Dynamically creates:
PHP 8.2 FPM Dockerfile
docker-compose.yaml
Nginx virtual host configuration
Custom MySQL server.cnf

# Launches Docker containers:

MySQL 8
PHP-FPM 8.2
Nginx
Redis

Installs WP-CLI inside the PHP container
Generates wp-config.php

Installs WordPress via WP-CLI
After execution, a fully functional WordPress site is available immediately.

# Stack
Docker / Docker Compose
Nginx
PHP 8.2 (FPM)
MySQL 8
Redis
WordPress (latest)
WP-CLI

# Requirements:

Clean Linux server 

Installed:
Docker
Docker Compose
Root or sudo privileges

# Usage
chmod +x install.sh
./install.sh

# Directory layout
/home/
├── wordpress/        # WordPress files
├── db/               # MySQL data
├── docker-compose.yaml
├── php-fpm-dockerfile
├── nginx.conf
└── server.cnf

# Features: 
Fully automated WordPress installation
Secure random credentials generation
Persistent MySQL storage
Minimal user interaction
Ideal for quick setup or development environments

# License

MIT
