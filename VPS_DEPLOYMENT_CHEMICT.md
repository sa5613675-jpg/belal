# VPS Deployment Guide - Chemistry and ICT Care by Belal Sir

## Server Configuration
- **Domain**: https://chemict.com
- **Port**: 8006 (internal, proxied by Nginx)
- **Database**: SQLite
- **Location**: /var/www/chemict

## Accounts

### Teacher Account (Belal Sir)
- **Phone**: 01734285995
- **Password**: sir@123@
- **Email**: mbhossain430@gmail.com
- **Role**: Teacher

### Admin Account
- **Phone**: 01818291546
- **Password**: sir@123@
- **Email**: admin@chemict.com
- **Role**: Teacher (Admin privileges)

## Quick Deployment Steps

### 1. On Your VPS Server

```bash
# Install required packages
sudo apt update
sudo apt install python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git -y

# Clone repository
cd /var/www
sudo git clone https://github.com/sa5613675-jpg/belal.git chemict
cd chemict

# Make deployment script executable
sudo chmod +x deploy_vps_chemict.sh

# Run deployment script
sudo ./deploy_vps_chemict.sh
```

### 2. Get SSL Certificate

```bash
sudo certbot --nginx -d chemict.com -d www.chemict.com
```

### 3. Configure DNS
Point your domain to your VPS IP address:
- A record: chemict.com → Your VPS IP
- A record: www.chemict.com → Your VPS IP

### 4. Configure Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

## Manual Deployment (Alternative)

If you prefer manual setup:

### 1. Setup Application

```bash
cd /var/www/chemict
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt  # or install packages manually
```

### 2. Initialize Database

```bash
export FLASK_APP=app.py
export FLASK_ENV=production
python3 -c "from app import create_app; from models import db; app = create_app('production'); app.app_context().push(); db.create_all()"
```

### 3. Setup Accounts

```bash
python3 setup_accounts.py
```

### 4. Start with Gunicorn

```bash
gunicorn --workers 3 --bind 127.0.0.1:8006 app:app
```

## Service Management

```bash
# Check service status
sudo systemctl status chemict

# Restart service
sudo systemctl restart chemict

# Stop service
sudo systemctl stop chemict

# View logs
sudo journalctl -u chemict -f

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## Database Backup

```bash
# Backup database
sudo cp /var/www/chemict/smartgardenhub.db /var/www/chemict/backup_$(date +%Y%m%d_%H%M%S).db

# Setup automatic daily backups
echo "0 2 * * * cp /var/www/chemict/smartgardenhub.db /var/www/chemict/backups/backup_\$(date +\%Y\%m\%d_\%H\%M\%S).db" | sudo crontab -
```

## Updating the Application

```bash
cd /var/www/chemict
sudo git pull origin main
source venv/bin/activate
pip install -r requirements.txt  # if dependencies changed
sudo systemctl restart chemict
```

## Troubleshooting

### Service won't start
```bash
sudo journalctl -u chemict -n 50
```

### Database permission issues
```bash
sudo chown www-data:www-data /var/www/chemict/smartgardenhub.db
sudo chmod 664 /var/www/chemict/smartgardenhub.db
```

### Nginx issues
```bash
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## GitHub Setup

```bash
# On your local machine
cd /workspaces/belal
git add .
git commit -m "VPS deployment ready for chemict.com on port 8006"
git push origin main
```

## Access URLs

- **Main Site**: https://chemict.com
- **Login**: https://chemict.com (click Login button)

## Support

For issues, check:
1. Service logs: `sudo journalctl -u chemict -f`
2. Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Database permissions: `ls -la /var/www/chemict/smartgardenhub.db`
4. Port binding: `sudo netstat -tulpn | grep 8006`
