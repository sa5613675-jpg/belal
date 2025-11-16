#!/bin/bash

##############################################################################
# Quick VPS Setup for chemict.com
# Run this on your VPS after pulling from GitHub
##############################################################################

echo "=========================================="
echo "🚀 Quick VPS Setup - chemict.com"
echo "=========================================="

# Check if running as root or with sudo
if [ "$EUID" -eq 0 ]; then 
    echo "✅ Running with root privileges"
else
    echo "⚠️  This script needs sudo privileges"
    echo "Please run: sudo ./quick_vps_setup.sh"
    exit 1
fi

APP_DIR="/var/www/chemict"
DOMAIN="chemict.com"
PORT="8006"

echo "📦 Installing system dependencies..."
apt update
apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git sqlite3

echo "📁 Setting up application directory..."
mkdir -p $APP_DIR
cd $APP_DIR

echo "🐍 Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

echo "📚 Installing Python packages..."
pip install --upgrade pip
pip install flask flask-sqlalchemy flask-session flask-bcrypt werkzeug gunicorn python-dotenv requests flask-cors

echo "🗄️  Initializing database..."
export FLASK_ENV=production
python3 << 'PYEOF'
from app import create_app
from models import db

app = create_app('production')
with app.app_context():
    db.create_all()
    print("✅ Database initialized!")
PYEOF

echo "👥 Setting up accounts..."
python3 setup_accounts.py

echo "🔐 Setting permissions..."
chown -R www-data:www-data $APP_DIR
chmod -R 755 $APP_DIR
chmod 664 $APP_DIR/smartgardenhub.db
chown www-data:www-data $APP_DIR/smartgardenhub.db

echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/chemict.service << 'SVCEOF'
[Unit]
Description=Chemistry and ICT Care Flask Application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/chemict
Environment="PATH=/var/www/chemict/venv/bin"
Environment="FLASK_ENV=production"
ExecStart=/var/www/chemict/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8006 app:app
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

echo "🌐 Creating Nginx configuration..."
cat > /etc/nginx/sites-available/$DOMAIN << 'NGXEOF'
server {
    listen 80;
    server_name chemict.com www.chemict.com;

    location / {
        proxy_pass http://127.0.0.1:8006;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static {
        alias /var/www/chemict/static;
        expires 30d;
    }

    client_max_body_size 16M;
}
NGXEOF

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "🔥 Configuring firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
echo "y" | ufw enable

echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable chemict
systemctl start chemict
nginx -t && systemctl restart nginx

echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "📱 Login Credentials:"
echo "   Teacher: 01734285995 / sir@123@"
echo "   Admin:   01818291546 / sir@123@"
echo ""
echo "🌐 Next Steps:"
echo "   1. Point DNS A records to this server's IP"
echo "   2. Run SSL setup:"
echo "      sudo certbot --nginx -d chemict.com -d www.chemict.com"
echo ""
echo "📊 Service Status:"
systemctl status chemict --no-pager -l
echo ""
echo "🔍 Access at: http://chemict.com (HTTP only until SSL setup)"
echo "=========================================="
