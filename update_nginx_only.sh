#!/bin/bash

##############################################################################
# Update Nginx Configuration Only - chemict.com
# Quick script to update nginx without full redeployment
##############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Nginx Configuration Update - chemict.com"
echo "=========================================="
echo ""

DOMAIN="chemict.com"

echo -e "${BLUE}[1/4] Checking for SSL certificate...${NC}"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}✅ SSL certificate found${NC}"
    echo "Using HTTPS configuration..."
    CONFIG_FILE="nginx_chemict.conf"
else
    echo -e "${YELLOW}⚠️  No SSL certificate found${NC}"
    echo "Using HTTP-only configuration..."
    CONFIG_FILE="nginx_chemict_http_only.conf"
fi
echo ""

echo -e "${BLUE}[2/4] Installing nginx configuration...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" /etc/nginx/sites-available/$DOMAIN
    ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    echo -e "${GREEN}✅ Configuration file installed${NC}"
else
    echo -e "${RED}❌ Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}[3/4] Testing nginx configuration...${NC}"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration test failed:${NC}"
    nginx -t
    exit 1
fi
echo ""

echo -e "${BLUE}[4/4] Reloading nginx...${NC}"
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to reload nginx${NC}"
    systemctl status nginx --no-pager
    exit 1
fi
echo ""

echo -e "${GREEN}=========================================="
echo "✅ Nginx Updated Successfully!"
echo "==========================================${NC}"
echo ""

# Show current status
echo -e "${YELLOW}📊 Current Configuration:${NC}"
if [ "$CONFIG_FILE" = "nginx_chemict.conf" ]; then
    echo "   Protocol: HTTPS (SSL enabled)"
    echo "   HTTP redirects to HTTPS"
else
    echo "   Protocol: HTTP only"
    echo "   To enable HTTPS, run:"
    echo "   certbot --nginx -d chemict.com -d www.chemict.com"
    echo "   Then run this script again"
fi
echo ""

echo -e "${YELLOW}🌐 Access URLs:${NC}"
if [ "$CONFIG_FILE" = "nginx_chemict.conf" ]; then
    echo "   https://chemict.com"
    echo "   https://www.chemict.com"
else
    echo "   http://chemict.com"
    echo "   http://www.chemict.com"
fi
echo ""

echo -e "${YELLOW}✅ Test:${NC}"
if [ "$CONFIG_FILE" = "nginx_chemict.conf" ]; then
    echo "   curl https://chemict.com/health"
else
    echo "   curl http://chemict.com/health"
fi
echo ""

echo "=========================================="
