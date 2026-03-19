# Wealthfolio Self-Hosting Setup

This repository contains a complete self-hosting setup for Wealthfolio with Docker and Nginx reverse proxy.

## 🏗️ Project Structure

```
wealthfolio_deploy/
├── startup.sh              # Interactive setup script
├── docker-compose.yml      # Container orchestration
├── nginx/
│   └── nginx.conf          # Nginx reverse proxy config
├── backup.sh               # Backup utility
├── stop.sh                 # Stop services
├── update.sh               # Update Wealthfolio
├── .env.template           # Environment variables template
└── .env.docker            # Generated configuration (created by startup.sh)
```

## Features

- 🐳 **Docker Compose**: Complete containerized setup
- 🔒 **Security**: Automated secret key and password hash generation
- 🌐 **Nginx Reverse Proxy**: Production-ready web server
- 📦 **Data Persistence**: Automatic volume mounting for data safety
- 🔧 **Management Scripts**: Easy backup, update, and stop operations
- 🏥 **Health Checks**: Built-in container health monitoring

## Quick Start

1. **Clone or download this repository**

2. **Run the setup script:**
   ```bash
   ./startup.sh
   ```

3. **Follow the interactive prompts:**
   - Choose a port for Nginx (default: 80)
   - Set a secure password for Wealthfolio login

4. **Access Wealthfolio:**
   - Open `http://localhost:[port]` in your browser
   - Login with the password you set during setup

## What Gets Created

The setup script creates:

- `.env.docker` - Environment variables for Wealthfolio (auto-generated)
- Docker volumes for data persistence
- Network configuration for container communication

Static files (already provided):
- `docker-compose.yml` - Container orchestration configuration
- `nginx/nginx.conf` - Nginx reverse proxy configuration
- Management scripts (`backup.sh`, `update.sh`, `stop.sh`)

### View Logs
```bash
docker-compose logs -f
```

### Stop Services
```bash
docker-compose down
```

### Backup Data
```bash
./backup.sh
```

### Update Wealthfolio
```bash
./update.sh
```

### Restart Services
```bash
docker-compose restart
```

## Configuration

The setup creates a `.env.docker` file with all necessary configuration:

- **WF_SECRET_KEY**: Auto-generated 32-byte secret
- **WF_AUTH_PASSWORD_HASH**: Argon2id hash of your password
- **WF_LISTEN_ADDR**: Set to `0.0.0.0:8088` for Docker
- **WF_DB_PATH**: Database location inside container
- **WF_CORS_ALLOW_ORIGINS**: Set to `*` (adjust for production)

## Data Storage

Your Wealthfolio data is stored in a Docker volume:
- **Volume name**: `wealthfolio_deploy_wealthfolio-data`
- **Contains**: SQLite database, encrypted secrets, add-ons

## Security Recommendations

For production use:

1. **Use HTTPS**: Set up SSL certificates with Let's Encrypt
2. **Restrict CORS**: Update `WF_CORS_ALLOW_ORIGINS` in `.env.docker`
3. **Firewall**: Limit access to necessary ports only
4. **Backups**: Run regular backups with `./backup.sh`
5. **Updates**: Keep Wealthfolio updated with `./update.sh`

## Adding HTTPS/SSL

To add HTTPS support, you can:

1. **Use Cloudflare**: Put your domain behind Cloudflare for free SSL
2. **Use Let's Encrypt**: Modify the nginx configuration to include SSL certificates
3. **Use a reverse proxy**: Put another reverse proxy (like Traefik) in front

Example Nginx SSL configuration:
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://wealthfolio:8088;
        # ... rest of proxy configuration
    }
}
```

## Troubleshooting

### Container won't start
```bash
# Check logs
docker-compose logs wealthfolio

# Common issues:
# - Port already in use: Change NGINX_PORT in docker-compose.yml
# - Permission issues: Check docker daemon is running
```

### Cannot access Wealthfolio
```bash
# Check if containers are running
docker-compose ps

# Check port mapping
docker-compose port nginx 80

# Check nginx logs
docker-compose logs nginx
```

### Database issues
```bash
# Check data volume
docker volume inspect wealthfolio_deploy_wealthfolio-data

# Backup and restore if needed
./backup.sh
```

## Requirements

- Docker and Docker Compose
- OpenSSL (for generating secrets)
- At least 1GB RAM and 2GB disk space

## Support

- **Documentation**: [wealthfolio.app/docs](https://wealthfolio.app/docs/guide/self-hosting/)
- **Discord Community**: [discord.gg/WDMCY6aPWK](https://discord.gg/WDMCY6aPWK)
- **GitHub Issues**: [github.com/afadil/wealthfolio/issues](https://github.com/afadil/wealthfolio/issues)

## License

This setup script is provided as-is. Wealthfolio itself is subject to its own license terms.