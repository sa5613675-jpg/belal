#!/bin/bash

##############################################################################
# VPS Deployment Script for Chemistry and ICT Care by Belal Sir
# Domain: https://chemict.com
# Port: 8006
# Database: SQLite
##############################################################################

echo "=========================================="
echo "Chemistry and ICT Care VPS Deployment"
echo "Domain: https://chemict.com"
echo "Port: 8006"
echo "=========================================="

# Configuration
APP_DIR="/var/www/chemict"
APP_USER="www-data"
DOMAIN="chemict.com"
PORT="8006"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Creating application directory...${NC}"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR
cd $APP_DIR

echo -e "${YELLOW}Step 2: Setting up Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate

echo -e "${YELLOW}Step 3: Installing dependencies...${NC}"
pip install --upgrade pip
pip install flask flask-sqlalchemy flask-session werkzeug gunicorn

echo -e "${YELLOW}Step 4: Copying application files...${NC}"
# This assumes you've pulled from GitHub
# If running from local, copy files:
# cp -r /path/to/your/local/belal/* $APP_DIR/

echo -e "${YELLOW}Step 5: Setting up database...${NC}"
export FLASK_APP=app.py
export FLASK_ENV=production

# Initialize database
python3 << EOF
from app import create_app
from models import db

app = create_app('production')
with app.app_context():
    db.create_all()
    print("Database tables created successfully!")
EOF

echo -e "${YELLOW}Step 6: Setting up accounts...${NC}"
python3 setup_accounts.py

echo -e "${YELLOW}Step 7: Setting permissions...${NC}"
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chmod 664 $APP_DIR/smartgardenhub.db
sudo chown www-data:www-data $APP_DIR/smartgardenhub.db

echo -e "${YELLOW}Step 8: Creating systemd service...${NC}"
sudo tee /etc/systemd/system/chemict.service > /dev/null << EOF
[Unit]
Description=Chemistry and ICT Care Flask Application
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/venv/bin"
Environment="FLASK_ENV=production"
ExecStart=$APP_DIR/venv/bin/gunicorn --workers 3 --bind 127.0.0.1:$PORT app:app

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}Step 9: Creating Nginx configuration...${NC}"
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration (update paths after getting SSL certificate)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static {
        alias $APP_DIR/static;
        expires 30d;
    }

    client_max_body_size 16M;
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

echo -e "${YELLOW}Step 10: Getting SSL Certificate...${NC}"
echo "Run this command to get SSL certificate:"
echo "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"

echo -e "${YELLOW}Step 11: Starting services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable chemict
sudo systemctl start chemict
sudo systemctl restart nginx

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo "📱 Teacher Account (Belal Sir):"
echo "   Phone: 01734285995"
echo "   Password: sir@123@"
echo ""
echo "🔐 Admin Account:"
echo "   Phone: 01818291546"
echo "   Password: sir@123@"
echo ""
echo "🌐 Access your site at:"
echo "   https://$DOMAIN"
echo ""
echo "📊 Service Management:"
echo "   sudo systemctl status chemict"
echo "   sudo systemctl restart chemict"
echo "   sudo systemctl stop chemict"
echo ""
echo "📝 View Logs:"
echo "   sudo journalctl -u chemict -f"
echo ""
echo "⚠️  Don't forget to:"
echo "   1. Run: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "   2. Configure your domain DNS to point to this VPS IP"
echo "   3. Update firewall: sudo ufw allow 80,443/tcp"
echo ""
echo "=========================================="
