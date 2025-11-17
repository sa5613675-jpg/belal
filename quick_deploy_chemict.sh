#!/bin/bash

##############################################################################
# Quick Deploy Script for chemict.com - Port 8006
# Run this from /var/www/chemict directory
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Quick Deploy: chemict.com (Port 8006)"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [[ ! "$PWD" =~ "chemict" ]]; then
    echo -e "${RED}Error: Please run this from /var/www/chemict directory${NC}"
    echo "Run: cd /var/www/chemict && ./quick_deploy_chemict.sh"
    exit 1
fi

echo -e "${BLUE}[1/8] Setting up Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate

echo -e "${BLUE}[2/8] Installing/Updating Python dependencies...${NC}"
pip install --upgrade pip -q
pip install -r requirements.txt -q

echo -e "${BLUE}[3/8] Setting up database...${NC}"
export FLASK_APP=app.py
export FLASK_ENV=production

python3 << 'EOF'
from app import create_app
from models import db

app = create_app('production')
with app.app_context():
    db.create_all()
    print("✅ Database tables created/verified!")
EOF

echo -e "${BLUE}[4/8] Creating log directory...${NC}"
mkdir -p logs
chmod 775 logs

echo -e "${BLUE}[5/8] Installing systemd service...${NC}"
cp chemict.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable chemict

echo -e "${BLUE}[6/8] Installing Nginx configuration...${NC}"
cp nginx_chemict.conf /etc/nginx/sites-available/chemict.com
ln -sf /etc/nginx/sites-available/chemict.com /etc/nginx/sites-enabled/

# Test nginx config
nginx -t

echo -e "${BLUE}[7/8] Setting permissions...${NC}"
chmod 664 smartgardenhub.db 2>/dev/null || true
chmod -R 775 logs

echo -e "${BLUE}[8/8] Starting services...${NC}"
systemctl restart chemict
systemctl restart nginx

sleep 2

# Check service status
if systemctl is-active --quiet chemict; then
    echo -e "${GREEN}✅ Service started successfully!${NC}"
else
    echo -e "${RED}❌ Service failed to start${NC}"
    journalctl -u chemict -n 20 --no-pager
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}🌐 Access URLs:${NC}"
echo "   Local: http://localhost:8006"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo "   IP: http://$SERVER_IP:8006"
echo "   Domain: https://chemict.com (after SSL)"
echo ""
echo -e "${YELLOW}📊 Service Commands:${NC}"
echo "   Status:  systemctl status chemict"
echo "   Logs:    journalctl -u chemict -f"
echo "   Restart: systemctl restart chemict"
echo ""
echo -e "${YELLOW}🔒 Get SSL Certificate:${NC}"
echo "   certbot --nginx -d chemict.com -d www.chemict.com"
echo ""
echo -e "${YELLOW}✅ Test Health:${NC}"
echo "   curl http://localhost:8006/health"
echo ""
echo "=========================================="
