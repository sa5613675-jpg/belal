#!/bin/bash

##############################################################################
# Pre-Deployment Verification Script for chemict.com
# Run this before deploying to ensure everything is ready
##############################################################################

echo "=========================================="
echo "Pre-Deployment Checklist for chemict.com"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

# Check 1: Required files exist
echo -e "${YELLOW}[1/10] Checking required files...${NC}"
REQUIRED_FILES=(
    "app.py"
    "wsgi.py"
    "config.py"
    "requirements.txt"
    "nginx_chemict.conf"
    "chemict.service"
    "deploy_chemict_vps.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (MISSING)"
        ((ERRORS++))
    fi
done
echo ""

# Check 2: Port configuration
echo -e "${YELLOW}[2/10] Checking port configuration (8006)...${NC}"
if grep -q "8006" app.py && grep -q "8006" wsgi.py && grep -q "8006" chemict.service && grep -q "8006" nginx_chemict.conf; then
    echo -e "  ${GREEN}✓${NC} Port 8006 configured correctly"
else
    echo -e "  ${RED}✗${NC} Port 8006 not configured in all files"
    ((ERRORS++))
fi
echo ""

# Check 3: Domain configuration
echo -e "${YELLOW}[3/10] Checking domain configuration (chemict.com)...${NC}"
if grep -q "chemict.com" nginx_chemict.conf; then
    echo -e "  ${GREEN}✓${NC} Domain chemict.com configured in nginx"
else
    echo -e "  ${RED}✗${NC} Domain not configured"
    ((ERRORS++))
fi
echo ""

# Check 4: Database path
echo -e "${YELLOW}[4/10] Checking database configuration...${NC}"
if grep -q "/var/www/chemict/smartgardenhub.db" config.py; then
    echo -e "  ${GREEN}✓${NC} Production database path configured"
else
    echo -e "  ${RED}✗${NC} Database path not configured for production"
    ((ERRORS++))
fi
echo ""

# Check 5: Python syntax
echo -e "${YELLOW}[5/10] Checking Python syntax...${NC}"
if python3 -m py_compile app.py 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} app.py syntax is valid"
else
    echo -e "  ${RED}✗${NC} app.py has syntax errors"
    ((ERRORS++))
fi

if python3 -m py_compile config.py 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} config.py syntax is valid"
else
    echo -e "  ${RED}✗${NC} config.py has syntax errors"
    ((ERRORS++))
fi
echo ""

# Check 6: Nginx configuration syntax
echo -e "${YELLOW}[6/10] Checking nginx configuration syntax...${NC}"
if command -v nginx &> /dev/null; then
    if sudo nginx -t -c nginx_chemict.conf 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Nginx configuration is valid"
    else
        echo -e "  ${YELLOW}⚠${NC} Cannot validate nginx config (will be checked on server)"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Nginx not installed locally (will be checked on server)"
fi
echo ""

# Check 7: Service file format
echo -e "${YELLOW}[7/10] Checking systemd service file...${NC}"
if grep -q "ExecStart" chemict.service && grep -q "WorkingDirectory" chemict.service; then
    echo -e "  ${GREEN}✓${NC} Service file has required sections"
else
    echo -e "  ${RED}✗${NC} Service file is incomplete"
    ((ERRORS++))
fi
echo ""

# Check 8: Deployment script executable
echo -e "${YELLOW}[8/10] Checking deployment script permissions...${NC}"
if [ -x "deploy_chemict_vps.sh" ]; then
    echo -e "  ${GREEN}✓${NC} Deployment script is executable"
else
    echo -e "  ${YELLOW}⚠${NC} Making deployment script executable..."
    chmod +x deploy_chemict_vps.sh
    echo -e "  ${GREEN}✓${NC} Fixed"
fi
echo ""

# Check 9: Git status (if in git repo)
echo -e "${YELLOW}[9/10] Checking git status...${NC}"
if [ -d ".git" ]; then
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "  ${GREEN}✓${NC} Working directory is clean"
    else
        echo -e "  ${YELLOW}⚠${NC} You have uncommitted changes"
        echo "  Modified files:"
        git status --short | sed 's/^/    /'
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Not a git repository"
fi
echo ""

# Check 10: Dependencies
echo -e "${YELLOW}[10/10] Checking Python dependencies...${NC}"
if [ -f "requirements.txt" ]; then
    DEPS_COUNT=$(wc -l < requirements.txt)
    echo -e "  ${GREEN}✓${NC} Found $DEPS_COUNT dependencies in requirements.txt"
    
    # Check for essential packages
    ESSENTIAL=(flask gunicorn flask-sqlalchemy)
    for pkg in "${ESSENTIAL[@]}"; do
        if grep -qi "$pkg" requirements.txt; then
            echo -e "    ${GREEN}✓${NC} $pkg"
        else
            echo -e "    ${RED}✗${NC} $pkg (MISSING)"
            ((ERRORS++))
        fi
    done
else
    echo -e "  ${RED}✗${NC} requirements.txt not found"
    ((ERRORS++))
fi
echo ""

# Summary
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready for deployment.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Copy files to your VPS server"
    echo "2. Run: ./deploy_chemict_vps.sh"
    echo "3. Configure DNS to point to your VPS IP"
    echo "4. Run: sudo certbot --nginx -d chemict.com -d www.chemict.com"
    echo ""
else
    echo -e "${RED}❌ Found $ERRORS error(s). Please fix before deploying.${NC}"
    echo ""
fi
echo "=========================================="
