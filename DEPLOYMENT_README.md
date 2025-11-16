# Chemistry and ICT Care by Belal Sir - VPS Deployment

## 🚀 Quick VPS Deployment (Recommended)

### On Your VPS Server:

```bash
# 1. Clone the repository
cd /var/www
sudo git clone https://github.com/sa5613675-jpg/belal.git chemict
cd chemict

# 2. Run the quick setup script
sudo chmod +x quick_vps_setup.sh
sudo ./quick_vps_setup.sh

# 3. Setup SSL certificate
sudo certbot --nginx -d chemict.com -d www.chemict.com
```

That's it! Your site will be live at https://chemict.com

---

## 📋 System Information

- **Domain**: https://chemict.com
- **Port**: 8006 (internal, proxied by Nginx)
- **Database**: SQLite at `/var/www/chemict/smartgardenhub.db`
- **Application**: Flask + Gunicorn + Nginx

---

## 👥 Login Accounts

### Teacher Account (Belal Sir)
- **Phone**: `01734285995`
- **Password**: `sir@123@`
- **Email**: mbhossain430@gmail.com

### Admin Account
- **Phone**: `01818291546`
- **Password**: `sir@123@`
- **Email**: admin@chemict.com

---

## 🔧 Service Management

```bash
# Check service status
sudo systemctl status chemict

# Restart application
sudo systemctl restart chemict

# View logs
sudo journalctl -u chemict -f

# Restart Nginx
sudo systemctl restart nginx
```

---

## 📦 Updating the Application

```bash
cd /var/www/chemict
sudo git pull origin main
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart chemict
```

---

## 💾 Database Backup

```bash
# Manual backup
sudo cp /var/www/chemict/smartgardenhub.db ~/backup_$(date +%Y%m%d).db

# Or use the included script
sudo python3 /var/www/chemict/backup_db.py
```

---

## 🌐 DNS Configuration

Point your domain to your VPS IP address:

| Type | Name | Value |
|------|------|-------|
| A | chemict.com | YOUR_VPS_IP |
| A | www.chemict.com | YOUR_VPS_IP |

---

## 🔒 SSL Certificate

Get a free SSL certificate from Let's Encrypt:

```bash
sudo certbot --nginx -d chemict.com -d www.chemict.com
```

Auto-renewal is set up automatically!

---

## ⚠️ Troubleshooting

### Site not loading?
```bash
# Check if service is running
sudo systemctl status chemict

# Check if port is listening
sudo netstat -tulpn | grep 8006

# Check Nginx
sudo nginx -t
sudo systemctl status nginx
```

### Database errors?
```bash
# Check permissions
ls -la /var/www/chemict/smartgardenhub.db

# Fix permissions
sudo chown www-data:www-data /var/www/chemict/smartgardenhub.db
sudo chmod 664 /var/www/chemict/smartgardenhub.db
```

### View application logs
```bash
sudo journalctl -u chemict -n 100 --no-pager
```

---

## 📞 Support

For any issues or questions, contact the administrator at 01818291546

---

## 🎓 Features

- Student & Teacher Management
- Attendance Tracking
- Online Exams
- Monthly Exams & Results
- Fee Management
- SMS Notifications
- Result Publishing
- Batch Management

Access all features after logging in at https://chemict.com
