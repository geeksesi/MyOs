# WordPress Multi-Site Setup

This setup allows you to create multiple dynamic WordPress sites with shared dependencies using Docker and Nginx.

## Services

The Docker setup provides these services:
- **MySQL**: Database server (Port 1002)
- **phpMyAdmin**: Database management (Port 1003)
- **Mailpit**: Email testing (Port 1001)

## Quick Start

1. **Start Docker services:**
   ```bash
   docker-compose up -d
   ```

2. **Create a new WordPress site:**
   ```bash
   ./create-wp-site.sh mysite
   ```

3. **Access your site:**
   - Website: http://mysite.test
   - phpMyAdmin: http://127.0.0.1:1003
   - Mailpit: http://127.0.0.1:1001

## Script Usage

```bash
./create-wp-site.sh <project_name> [php_version] [custom_domain]
```

### Examples:
```bash
# Basic site with default PHP 8.2
./create-wp-site.sh myproject

# Specify PHP version
./create-wp-site.sh myproject 8.1

# Custom domain
./create-wp-site.sh myproject 8.2 myproject.local
```

## What the Script Does

1. **Installs dependencies** (Docker, Nginx, MySQL client, PHP)
2. **Creates project folder** with the specified name
3. **Downloads WordPress** to the project folder
4. **Creates database** (`wp_projectname`)
5. **Configures WordPress** with database and mail settings
6. **Adds domain to /etc/hosts** (projectname.test)
7. **Creates Nginx configuration** with PHP-FPM support
8. **Starts all services**

## Directory Structure

```
wordpress/
├── docker-compose.yml          # Docker services
├── create-wp-site.sh          # Site creation script
├── project1/                  # WordPress site 1
├── project2/                  # WordPress site 2
└── ...                        # More sites
```

## Database Credentials

- **Root Password**: `rootpassword`
- **WordPress User**: `wordpress`
- **WordPress Password**: `wordpress123`
- **Host**: `127.0.0.1:1002`

## Mail Configuration

All sites are configured to use Mailpit for email testing:
- **SMTP Host**: `127.0.0.1`
- **SMTP Port**: `1025`
- **Web Interface**: http://127.0.0.1:1001

## Nginx Configuration

Each site gets its own Nginx configuration in `/etc/nginx/sites-available/` and is automatically enabled.

## Troubleshooting

1. **Permission issues**: Make sure the script is executable
2. **Port conflicts**: Ensure ports 1001, 1002, 1003 are available
3. **PHP issues**: The script auto-installs PHP and required extensions
4. **Nginx issues**: Check `sudo nginx -t` for configuration errors