#!/bin/bash

##############################################################################
# VPS Deployment Script for Chemistry and ICT Care by Belal Sir
# Domain: https://chemict.com
# Port: 8006
# Database: SQLite
# Path: /var/www/chemict
##############################################################################

set -e  # Exit on error

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
SERVICE_NAME="chemict"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run as root. Run as regular user with sudo privileges.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Installing system dependencies...${NC}"
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx git

echo -e "${BLUE}Step 2: Creating application directory...${NC}"
sudo mkdir -p $APP_DIR
sudo mkdir -p $APP_DIR/logs
sudo chown -R $USER:$USER $APP_DIR

echo -e "${BLUE}Step 3: Copying application files...${NC}"
# Copy all files from current directory to app directory
cp -r * $APP_DIR/ 2>/dev/null || true
cp -r .* $APP_DIR/ 2>/dev/null || true

cd $APP_DIR

echo -e "${BLUE}Step 4: Setting up Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate

echo -e "${BLUE}Step 5: Installing Python dependencies...${NC}"
pip install --upgrade pip
pip install -r requirements.txt 2>/dev/null || {
    echo "requirements.txt not found, installing basic dependencies..."
    pip install flask flask-sqlalchemy flask-session flask-cors flask-bcrypt werkzeug gunicorn
}

echo -e "${BLUE}Step 6: Setting up database...${NC}"
export FLASK_APP=app.py
export FLASK_ENV=production

# Initialize database
python3 << 'EOF'
from app import create_app
from models import db

app = create_app('production')
with app.app_context():
    db.create_all()
    print("Database tables created successfully!")
EOF

echo -e "${BLUE}Step 7: Creating default accounts...${NC}"
# Create default accounts if script exists
if [ -f "setup_accounts.py" ]; then
    python3 setup_accounts.py
else
    echo "setup_accounts.py not found, skipping..."
fi

echo -e "${BLUE}Step 8: Setting file permissions...${NC}"
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
sudo chmod 664 $APP_DIR/smartgardenhub.db 2>/dev/null || true
sudo chown www-data:www-data $APP_DIR/smartgardenhub.db 2>/dev/null || true
sudo chmod -R 775 $APP_DIR/logs

echo -e "${BLUE}Step 9: Setting up systemd service...${NC}"
sudo cp chemict.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

echo -e "${BLUE}Step 10: Setting up Nginx configuration...${NC}"
sudo cp nginx_chemict.conf /etc/nginx/sites-available/$DOMAIN
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

echo -e "${BLUE}Step 11: Configuring firewall...${NC}"
sudo ufw allow 80/tcp 2>/dev/null || true
sudo ufw allow 443/tcp 2>/dev/null || true
sudo ufw allow 8006/tcp 2>/dev/null || true

echo -e "${BLUE}Step 12: Starting services...${NC}"
sudo systemctl restart $SERVICE_NAME
sudo systemctl restart nginx

# Wait a moment for service to start
sleep 3

# Check service status
if sudo systemctl is-active --quiet $SERVICE_NAME; then
    echo -e "${GREEN}✅ Service started successfully!${NC}"
else
    echo -e "${RED}❌ Service failed to start. Check logs:${NC}"
    echo "sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}📱 Teacher Account (Belal Sir):${NC}"
echo "   Phone: 01734285995"
echo "   Password: sir@123@"
echo ""
echo -e "${YELLOW}🔐 Admin Account:${NC}"
echo "   Phone: 01818291546"
echo "   Password: sir@123@"
echo ""
echo -e "${YELLOW}🌐 Access URLs:${NC}"
echo "   Local: http://localhost:8006"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
echo "   IP: http://$SERVER_IP:8006"
echo "   Domain (after SSL): https://$DOMAIN"
echo ""
echo -e "${YELLOW}📊 Service Management:${NC}"
echo "   Status:  sudo systemctl status $SERVICE_NAME"
echo "   Restart: sudo systemctl restart $SERVICE_NAME"
echo "   Stop:    sudo systemctl stop $SERVICE_NAME"
echo "   Logs:    sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo -e "${YELLOW}📝 Application Logs:${NC}"
echo "   Access:  tail -f $APP_DIR/logs/access.log"
echo "   Error:   tail -f $APP_DIR/logs/error.log"
echo ""
echo -e "${YELLOW}🔒 SSL Certificate Setup:${NC}"
echo "   Run this command to get FREE SSL certificate:"
echo "   ${GREEN}sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}⚠️  Important Next Steps:${NC}"
echo "   1. Configure DNS A records:"
echo "      $DOMAIN        → $SERVER_IP"
echo "      www.$DOMAIN    → $SERVER_IP"
echo ""
echo "   2. Get SSL certificate (after DNS is configured):"
echo "      sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "   3. Set up auto-renewal:"
echo "      sudo certbot renew --dry-run"
echo ""
echo "   4. Test your deployment:"
echo "      curl http://localhost:8006/health"
echo ""
echo "=========================================="
