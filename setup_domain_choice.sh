#!/bin/bash

##############################################################################
# Setup Script - Use Subdomain for Chemistry App
# This allows both apps to coexist on chemict.com
##############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "Setup Chemistry App on Subdomain"
echo "=========================================="
echo ""

echo -e "${YELLOW}OPTIONS:${NC}"
echo ""
echo "1. Use subdomain: chemistry.chemict.com (recommended)"
echo "   - Keeps existing app on chemict.com"
echo "   - Chemistry app on chemistry.chemict.com"
echo ""
echo "2. Replace current app and use main domain: chemict.com"
echo "   - Removes GS Student Nursing Center"
echo "   - Chemistry app on chemict.com"
echo ""
read -p "Enter your choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    echo ""
    echo -e "${BLUE}Setting up chemistry.chemict.com...${NC}"
    
    # Use subdomain config
    cp nginx_chemistry_subdomain.conf /etc/nginx/sites-available/chemistry.chemict.com
    ln -sf /etc/nginx/sites-available/chemistry.chemict.com /etc/nginx/sites-enabled/
    
    # Test nginx
    if nginx -t; then
        systemctl reload nginx
        echo -e "${GREEN}✅ Done!${NC}"
        echo ""
        echo "Add this DNS record:"
        echo "  Type: A"
        echo "  Name: chemistry"
        echo "  Value: YOUR_VPS_IP"
        echo ""
        echo "Access at: http://chemistry.chemict.com"
    else
        echo -e "${RED}❌ Nginx config failed${NC}"
        exit 1
    fi
    
elif [ "$choice" = "2" ]; then
    echo ""
    echo -e "${YELLOW}This will configure chemict.com to point to port 8006${NC}"
    echo -e "${YELLOW}Other apps on different ports will NOT be affected${NC}"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "${BLUE}Configuring chemict.com for port 8006...${NC}"
        
        # Remove old chemict.com config only, keep other apps
        rm -f /etc/nginx/sites-enabled/chemict.com
        rm -f /etc/nginx/sites-available/chemict.com
        
        # Add new config for port 8006
        cp nginx_chemict_http_only.conf /etc/nginx/sites-available/chemict.com
        ln -sf /etc/nginx/sites-available/chemict.com /etc/nginx/sites-enabled/
        
        # Test nginx
        if nginx -t; then
            systemctl reload nginx
            echo -e "${GREEN}✅ Done!${NC}"
            echo ""
            echo "chemict.com now points to port 8006"
            echo "Other apps on different ports are unaffected"
            echo "Access at: http://chemict.com"
        else
            echo -e "${RED}❌ Nginx config failed${NC}"
            exit 1
        fi
    else
        echo "Cancelled."
        exit 0
    fi
else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi
