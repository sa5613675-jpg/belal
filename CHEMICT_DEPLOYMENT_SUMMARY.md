# chemict.com VPS Deployment Summary

## ✅ Configuration Complete

Your application has been configured for VPS deployment with the following settings:

### Server Configuration
- **Domain**: chemict.com (with www.chemict.com)
- **Port**: 8006 (internal, proxied through Nginx)
- **Application Path**: /var/www/chemict
- **Service Name**: chemict
- **Database**: SQLite at /var/www/chemict/smartgardenhub.db
- **Web Server**: Nginx (reverse proxy with SSL)
- **App Server**: Gunicorn (4 workers)

### Files Created/Updated

#### Configuration Files
- ✅ `config.py` - Updated with production database path
- ✅ `app.py` - Updated default port to 8006
- ✅ `wsgi.py` - Updated port to 8006

#### Deployment Files
- ✅ `nginx_chemict.conf` - Nginx configuration for chemict.com
- ✅ `chemict.service` - Systemd service file
- ✅ `deploy_chemict_vps.sh` - Automated deployment script
- ✅ `check_deployment_ready.sh` - Pre-deployment verification script
- ✅ `CHEMICT_VPS_GUIDE.md` - Complete VPS management guide

## 🚀 Quick Deployment Steps

### On Your Local Machine

```bash
# 1. Verify everything is ready
./check_deployment_ready.sh

# 2. Transfer files to VPS (choose one method)

# Method A: Using SCP
scp -r /workspaces/belal/* user@YOUR_VPS_IP:/tmp/chemict/

# Method B: Using rsync
rsync -avz --exclude='.git' /workspaces/belal/ user@YOUR_VPS_IP:/tmp/chemict/

# Method C: Using Git
git add .
git commit -m "Configure for chemict.com deployment"
git push origin main
```

### On Your VPS Server

```bash
# 1. SSH into your VPS
ssh user@YOUR_VPS_IP

# 2. Copy files to deployment directory (if using SCP/rsync)
sudo cp -r /tmp/chemict /workspaces/belal

# OR clone from git
cd /workspaces
git clone YOUR_REPO_URL belal
cd belal

# 3. Run deployment script
./deploy_chemict_vps.sh

# 4. Configure DNS (point chemict.com and www.chemict.com to YOUR_VPS_IP)

# 5. Get SSL certificate (after DNS propagation)
sudo certbot --nginx -d chemict.com -d www.chemict.com
```

## 🔐 Default Accounts

### Teacher Account (Belal Sir)
- Phone: `01734285995`
- Password: `sir@123@`
- Role: Teacher

### Admin Account
- Phone: `01818291546`
- Password: `sir@123@`
- Role: Admin

**⚠️ Important**: Change these passwords after first login!

## 🌐 DNS Configuration

Add these DNS records to your domain registrar:

```
Type    Name    Value           TTL
A       @       YOUR_VPS_IP     3600
A       www     YOUR_VPS_IP     3600
```

Wait for DNS propagation (can take 1-48 hours).

## 📊 Service Management Commands

```bash
# Check service status
sudo systemctl status chemict

# Start/Stop/Restart
sudo systemctl start chemict
sudo systemctl stop chemict
sudo systemctl restart chemict

# View live logs
sudo journalctl -u chemict -f

# Application logs
tail -f /var/www/chemict/logs/access.log
tail -f /var/www/chemict/logs/error.log
```

## 🔍 Health Checks

```bash
# Local check
curl http://localhost:8006/health

# External check (after deployment)
curl https://chemict.com/health
```

Expected response:
```json
{
  "status": "healthy",
  "app": "SmartGardenHub",
  "environment": "production"
}
```

## 🔧 Troubleshooting

### Service won't start
```bash
sudo journalctl -u chemict -n 50
sudo systemctl status chemict
```

### Database permission errors
```bash
sudo chown www-data:www-data /var/www/chemict/smartgardenhub.db
sudo chmod 664 /var/www/chemict/smartgardenhub.db
```

### Port already in use
```bash
sudo lsof -i :8006
sudo systemctl stop chemict
```

### Nginx configuration errors
```bash
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

## 📁 Directory Structure

```
/var/www/chemict/
├── app.py                      # Main Flask application
├── wsgi.py                     # WSGI entry point
├── config.py                   # Configuration
├── models.py                   # Database models
├── requirements.txt            # Python dependencies
├── chemict.service            # Systemd service file
├── nginx_chemict.conf         # Nginx configuration
├── venv/                      # Python virtual environment
├── logs/                      # Application logs
│   ├── access.log
│   └── error.log
├── static/                    # Static files
├── templates/                 # HTML templates
└── smartgardenhub.db         # SQLite database
```

## 🔒 Security Checklist

- ✅ Application runs as www-data (non-root)
- ✅ Database file has restricted permissions
- ✅ Firewall configured (ports 80, 443)
- ✅ SSL/TLS encryption enabled
- ✅ Nginx security headers configured
- ✅ File upload size limited (50MB)
- ⚠️ Change default passwords after deployment
- ⚠️ Set strong SECRET_KEY in production

## 📚 Additional Resources

- **Complete Guide**: `CHEMICT_VPS_GUIDE.md`
- **Deployment Script**: `deploy_chemict_vps.sh`
- **Verification Script**: `check_deployment_ready.sh`
- **Nginx Config**: `nginx_chemict.conf`
- **Service File**: `chemict.service`

## 🆘 Support Commands

```bash
# Check all services
sudo systemctl status chemict nginx

# Test application directly
curl http://localhost:8006/health

# Check database
ls -lh /var/www/chemict/smartgardenhub.db

# View all logs
sudo journalctl -u chemict -n 100

# Restart everything
sudo systemctl restart chemict nginx
```

## ✨ Features Enabled

- User authentication (Admin, Teacher, Student)
- Batch management
- Exam creation and management
- Online MCQ exams
- Fee management
- SMS notifications
- Attendance tracking
- Results and rankings
- Monthly exams
- Document management
- Dashboard with analytics

---

**Deployment Date**: November 17, 2025
**Application**: Chemistry and ICT Care Management System
**Developer**: Belal Sir
**Domain**: https://chemict.com
