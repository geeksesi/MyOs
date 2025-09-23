#!/bin/bash

# WordPress Multi-Site Creator Script
# Usage: ./create-wp-site.sh <project_name> [php_version] [custom_domain]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITES_DIR="$SCRIPT_DIR"
DEFAULT_PHP_VERSION=""
MYSQL_ROOT_PASSWORD="rootpassword"
MYSQL_USER="wordpress"
MYSQL_PASSWORD="wordpress123"
MYSQL_HOST="127.0.0.1"
MYSQL_PORT="1002"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install PHP and required packages
install_php() {
    local php_version=$1
    local php_package="php${php_version//./}"

    print_status "Checking PHP $php_version installation..."

    if ! command_exists "php$php_version"; then
        print_status "Installing PHP $php_version and required packages..."

        # Install PHP and common extensions
        yay -S --noconfirm \
            "$php_package" \
            "${php_package}-fpm" \
            "${php_package}-mysql" \
            "${php_package}-mysqli" \
            "${php_package}-curl" \
            "${php_package}-gd" \
            "${php_package}-mbstring" \
            "${php_package}-xml" \
            "${php_package}-zip" \
            "${php_package}-json" \
            "${php_package}-openssl" \
            "${php_package}-tokenizer" \
            "${php_package}-fileinfo" \
            "${php_package}-bcmath" \
            "${php_package}-ctype" \
            "${php_package}-pdo" \
            2>/dev/null || {
            print_warning "Some PHP packages might not be available or already installed"
        }

        print_success "PHP $php_version installed successfully"
    else
        print_success "PHP $php_version is already installed"
    fi

    # Start and enable PHP-FPM
    print_status "Starting PHP-FPM service..."
    sudo systemctl enable "php${php_version//./}-fpm" 2>/dev/null || true
    sudo systemctl start "php${php_version//./}-fpm" 2>/dev/null || true
}

# Function to install required system packages
install_dependencies() {
    print_status "Checking system dependencies..."

    local packages_to_install=()

    if ! command_exists docker; then
        packages_to_install+=("docker")
    fi

    if ! command_exists docker-compose; then
        packages_to_install+=("docker-compose")
    fi

    if ! command_exists nginx; then
        packages_to_install+=("nginx")
    fi

    if ! command_exists wget; then
        packages_to_install+=("wget")
    fi

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_status "Installing system packages: ${packages_to_install[*]}"
        yay -S --noconfirm "${packages_to_install[@]}"
    fi

    # Start and enable services
    print_status "Starting required services..."
    sudo systemctl enable docker 2>/dev/null || true
    sudo systemctl start docker 2>/dev/null || true
    sudo systemctl enable nginx 2>/dev/null || true
    sudo systemctl start nginx 2>/dev/null || true
}

# Function to start Docker services
start_docker_services() {
    print_status "Starting Docker services..."

    if [ ! -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        print_error "docker-compose.yml not found in $SCRIPT_DIR"
        exit 1
    fi

    cd "$SCRIPT_DIR"
    docker-compose up -d

    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SELECT 1" >/dev/null 2>&1; then
            print_success "MySQL is ready"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            print_error "MySQL failed to start after $max_attempts attempts"
            exit 1
        fi

        print_status "Attempt $attempt/$max_attempts - waiting for MySQL..."
        sleep 2
        ((attempt++))
    done
}

# Function to create database
create_database() {
    local project_name=$1
    local db_name="wp_${project_name}"

    print_status "Creating database: $db_name"

    # Create database
    docker-compose exec -T mysql mysql -u root -p$MYSQL_ROOT_PASSWORD -e "
        CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
        GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$MYSQL_USER'@'%';
        FLUSH PRIVILEGES;
    "

    print_success "Database $db_name created successfully"
}

# Function to download WordPress
download_wordpress() {
    local project_dir=$1

    print_status "Downloading WordPress..."

    cd "$project_dir"
    wget -q https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz

    print_success "WordPress downloaded successfully"
}

# Function to configure WordPress
configure_wordpress() {
    local project_name=$1
    local project_dir=$2
    local db_name="wp_${project_name}"

    print_status "Configuring WordPress..."

    cd "$project_dir"

    # Create wp-config.php
    cat > wp-config.php << EOF
<?php
define('DB_NAME', '$db_name');
define('DB_USER', '$MYSQL_USER');
define('DB_PASSWORD', '$MYSQL_PASSWORD');
define('DB_HOST', '$MYSQL_HOST:$MYSQL_PORT');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// WordPress Mail Configuration (Mailpit)
define('SMTP_HOST', '127.0.0.1');
define('SMTP_PORT', 1004);
define('SMTP_AUTH', false);

\$table_prefix = 'wp_';

define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);

if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

    # Set proper permissions
    chmod 644 wp-config.php

    print_success "WordPress configured successfully"
}

# Function to add entry to /etc/hosts
add_hosts_entry() {
    local domain=$1

    print_status "Adding $domain to /etc/hosts..."

    if ! grep -q "127.0.0.1 $domain" /etc/hosts; then
        echo "127.0.0.1 $domain" | sudo tee -a /etc/hosts > /dev/null
        print_success "Added $domain to /etc/hosts"
    else
        print_warning "$domain already exists in /etc/hosts"
    fi
}

# Function to create Nginx configuration
create_nginx_config() {
    local project_name=$1
    local domain=$2
    local project_dir=$3
    local php_version=$4

    print_status "Creating Nginx configuration for $domain..."

    local nginx_config="/etc/nginx/sites-available/$project_name"
    local php_sock="/run/php-fpm/php${php_version//./}-fpm.sock"

    sudo tee "$nginx_config" > /dev/null << EOF
server {
    listen 80;
    server_name $domain;
    root $project_dir;
    index index.php index.html index.htm;

    access_log /var/log/nginx/${project_name}_access.log;
    error_log /var/log/nginx/${project_name}_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:$php_sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;

        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

    # Create sites-enabled directory if it doesn't exist
    sudo mkdir -p /etc/nginx/sites-enabled

    # Enable the site
    sudo ln -sf "$nginx_config" "/etc/nginx/sites-enabled/$project_name"

    # Test nginx configuration
    if sudo nginx -t; then
        sudo systemctl reload nginx
        print_success "Nginx configuration created and enabled for $domain"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Main function
main() {
    local project_name=$1
    local php_version=${2:-$DEFAULT_PHP_VERSION}
    local custom_domain=$3

    if [ -z "$project_name" ]; then
        print_error "Usage: $0 <project_name> [php_version] [custom_domain]"
        print_error "Example: $0 mysite 8.2 mysite.local"
        exit 1
    fi

    local domain="${custom_domain:-${project_name}.test}"
    local project_dir="$SITES_DIR/$project_name"

    print_status "Creating WordPress site: $project_name"
    print_status "Domain: $domain"
    print_status "PHP Version: $php_version"
    print_status "Project Directory: $project_dir"

    # Check if project already exists
    if [ -d "$project_dir" ]; then
        print_error "Project directory $project_dir already exists"
        exit 1
    fi

    # Install dependencies
    install_dependencies
    install_php "$php_version"

    # Start Docker services
    start_docker_services

    # Create project directory
    mkdir -p "$project_dir"

    # Create database
    create_database "$project_name"

    # Download and configure WordPress
    download_wordpress "$project_dir"
    configure_wordpress "$project_name" "$project_dir"

    # Add hosts entry
    add_hosts_entry "$domain"

    # Create Nginx configuration
    create_nginx_config "$project_name" "$domain" "$project_dir" "$php_version"

    print_success "WordPress site created successfully!"
    print_success "Site URL: http://$domain"
    print_success "Database: wp_${project_name}"
    print_success "Mailpit: http://127.0.0.1:1001"
    print_success "phpMyAdmin: http://127.0.0.1:1003"
    print_success "Project Directory: $project_dir"
}

# Run main function with all arguments
main "$@"