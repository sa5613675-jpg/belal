#!/bin/bash

##############################################################################
# Fix Nginx - Ensure Chemistry App is Active on chemict.com
##############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Fix chemict.com - Force Chemistry App"
echo "=========================================="
echo ""

echo -e "${BLUE}[1/6] Checking current nginx configurations...${NC}"
echo "Active configurations:"
ls -la /etc/nginx/sites-enabled/ | grep -v "^total" | grep -v "^l.*default"
echo ""

echo -e "${BLUE}[2/6] Removing ONLY chemict.com configuration...${NC}"
# Only remove chemict.com config, leave other apps untouched
rm -f /etc/nginx/sites-enabled/chemict.com
rm -f /etc/nginx/sites-available/chemict.com
echo "✓ Old chemict.com config removed (other apps untouched)"
echo ""

echo -e "${BLUE}[3/6] Installing fresh Chemistry app config...${NC}"
# Copy the HTTP-only config for chemistry app
cp nginx_chemict_http_only.conf /etc/nginx/sites-available/chemict.com
ln -sf /etc/nginx/sites-available/chemict.com /etc/nginx/sites-enabled/chemict.com
echo "✓ New config installed"
echo ""

echo -e "${BLUE}[4/6] Testing nginx configuration...${NC}"
if nginx -t 2>&1; then
    echo -e "${GREEN}✓ Nginx configuration is valid${NC}"
else
    echo -e "${RED}✗ Nginx configuration failed${NC}"
    echo "Showing errors:"
    nginx -t
    exit 1
fi
echo ""

echo -e "${BLUE}[5/6] Checking if chemistry service is running on port 8006...${NC}"
if systemctl is-active --quiet chemict; then
    echo -e "${GREEN}✓ Chemistry service is running${NC}"
    
    # Check if port is listening
    if netstat -tuln | grep -q ":8006" || ss -tuln | grep -q ":8006"; then
        echo -e "${GREEN}✓ Port 8006 is listening${NC}"
    else
        echo -e "${YELLOW}⚠ Port 8006 is not listening, restarting service...${NC}"
        systemctl restart chemict
        sleep 2
    fi
else
    echo -e "${YELLOW}⚠ Chemistry service not running, starting it...${NC}"
    systemctl start chemict
    sleep 2
fi
echo ""

echo -e "${BLUE}[6/6] Reloading nginx...${NC}"
systemctl reload nginx
sleep 1

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}✗ Nginx failed to reload${NC}"
    systemctl status nginx --no-pager
    exit 1
fi
echo ""

echo -e "${GREEN}=========================================="
echo "✅ FIX COMPLETE!"
echo "==========================================${NC}"
echo ""

echo -e "${YELLOW}Testing the application...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8006/health 2>/dev/null)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Application responding correctly!${NC}"
    echo ""
    echo "Access your Chemistry app at:"
    echo "  http://chemict.com"
    echo ""
    echo "If you still see the old app:"
    echo "1. Clear your browser cache (Ctrl+Shift+Delete)"
    echo "2. Try incognito/private mode"
    echo "3. Or add ?v=2 to the URL: http://chemict.com?v=2"
else
    echo -e "${RED}✗ Application not responding on port 8006${NC}"
    echo "Check service status:"
    echo "  systemctl status chemict"
    echo "  journalctl -u chemict -n 20"
fi
echo ""
echo "=========================================="
