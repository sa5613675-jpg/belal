# Chemistry and ICT Care (chemict.com) - VPS Deployment Guide

## Quick Deployment

```bash
# 1. Clone or copy your code to the server
cd /workspaces/belal

# 2. Make deployment script executable
chmod +x deploy_chemict_vps.sh

# 3. Run deployment script
./deploy_chemict_vps.sh
```

## Server Configuration

- **Domain**: chemict.com
- **Port**: 8006 (internal)
- **Path**: /var/www/chemict
- **Service**: chemict.service
- **Database**: SQLite (/var/www/chemict/smartgardenhub.db)
- **Web Server**: Nginx (reverse proxy)
- **App Server**: Gunicorn (4 workers)

## Default Accounts

### Teacher Account (Belal Sir)
- Phone: 01734285995
- Password: sir@123@

### Admin Account
- Phone: 01818291546
- Password: sir@123@

## DNS Configuration

Point your domain to your VPS IP address:

```
A Record:     chemict.com        → YOUR_VPS_IP
A Record:     www.chemict.com    → YOUR_VPS_IP
```

## SSL Certificate (Let's Encrypt)

After DNS is configured and propagated:

```bash
# Get SSL certificate
sudo certbot --nginx -d chemict.com -d www.chemict.com

# Test auto-renewal
sudo certbot renew --dry-run
```

## Service Management

```bash
# Check service status
sudo systemctl status chemict

# Start service
sudo systemctl start chemict

# Stop service
sudo systemctl stop chemict

# Restart service
sudo systemctl restart chemict

# View live logs
sudo journalctl -u chemict -f

# View last 100 lines
sudo journalctl -u chemict -n 100
```

## Application Logs

```bash
# Access logs
tail -f /var/www/chemict/logs/access.log

# Error logs
tail -f /var/www/chemict/logs/error.log
```

## Nginx Management

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# View nginx logs
tail -f /var/log/nginx/chemict.com.access.log
tail -f /var/log/nginx/chemict.com.error.log
```

## Health Checks

```bash
# Check application health
curl http://localhost:8006/health

# Check database health
curl http://localhost:8006/health/db

# Check from outside
curl https://chemict.com/health
```

## Database Management

```bash
# Backup database
cp /var/www/chemict/smartgardenhub.db /var/www/chemict/backup_$(date +%Y%m%d_%H%M%S).db

# View database location
ls -lh /var/www/chemict/smartgardenhub.db
```

## Firewall Configuration

```bash
# Allow HTTP
sudo ufw allow 80/tcp

# Allow HTTPS
sudo ufw allow 443/tcp

# Allow direct port access (optional)
sudo ufw allow 8006/tcp

# Check firewall status
sudo ufw status
```

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status chemict

# View recent logs
sudo journalctl -u chemict -n 50

# Check if port is already in use
sudo lsof -i :8006
```

### Permission issues

```bash
# Fix permissions
sudo chown -R www-data:www-data /var/www/chemict
sudo chmod -R 755 /var/www/chemict
sudo chmod 664 /var/www/chemict/smartgardenhub.db
```

### Nginx configuration errors

```bash
# Test configuration
sudo nginx -t

# Check error log
sudo tail -f /var/log/nginx/error.log
```

### Database locked or permission errors

```bash
# Check database permissions
ls -lh /var/www/chemict/smartgardenhub.db

# Fix ownership
sudo chown www-data:www-data /var/www/chemict/smartgardenhub.db
sudo chmod 664 /var/www/chemict/smartgardenhub.db
```

## Updating the Application

```bash
# 1. Stop the service
sudo systemctl stop chemict

# 2. Backup database
cp /var/www/chemict/smartgardenhub.db /var/www/chemict/backup_$(date +%Y%m%d_%H%M%S).db

# 3. Pull latest code or copy new files
cd /var/www/chemict
# git pull origin main  # if using git

# 4. Activate virtual environment and update dependencies
source venv/bin/activate
pip install -r requirements.txt

# 5. Run any database migrations if needed
# python migrate_script.py

# 6. Restart service
sudo systemctl start chemict
```

## Performance Tuning

### Increase Gunicorn workers

Edit `/etc/systemd/system/chemict.service`:

```ini
ExecStart=/var/www/chemict/venv/bin/gunicorn --workers 8 --bind 127.0.0.1:8006 ...
```

Then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart chemict
```

### Monitor resource usage

```bash
# CPU and memory
htop

# Disk usage
df -h
du -sh /var/www/chemict/*
```

## Security Checklist

- ✅ Firewall configured (UFW)
- ✅ SSL certificate installed
- ✅ Application running as www-data (non-root)
- ✅ Database file permissions restricted
- ✅ Nginx security headers enabled
- ✅ File upload size limited
- ✅ Strong passwords on production accounts

## Support

For issues or questions:
- Check logs: `sudo journalctl -u chemict -f`
- Review nginx logs: `/var/log/nginx/chemict.com.error.log`
- Test health endpoint: `curl http://localhost:8006/health`
