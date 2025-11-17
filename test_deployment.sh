#!/bin/bash

##############################################################################
# Post-Deployment Testing Script for chemict.com
# Run this after deployment to verify everything is working
##############################################################################

echo "=========================================="
echo "chemict.com Post-Deployment Tests"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="chemict.com"
PORT="8006"
PASSED=0
FAILED=0

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_code=$3
    
    echo -n "Testing $name... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    
    if [ "$response" = "$expected_code" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $response, expected $expected_code)"
        ((FAILED++))
    fi
}

# Test 1: Local port connectivity
echo -e "${BLUE}[1] Testing local port connectivity...${NC}"
test_endpoint "Localhost:$PORT" "http://localhost:$PORT/health" "200"
echo ""

# Test 2: Service status
echo -e "${BLUE}[2] Checking service status...${NC}"
if sudo systemctl is-active --quiet chemict; then
    echo -e "${GREEN}✓ PASS${NC} - Service is running"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Service is not running"
    ((FAILED++))
fi
echo ""

# Test 3: Nginx status
echo -e "${BLUE}[3] Checking Nginx status...${NC}"
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ PASS${NC} - Nginx is running"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Nginx is not running"
    ((FAILED++))
fi
echo ""

# Test 4: API endpoints
echo -e "${BLUE}[4] Testing API endpoints...${NC}"
test_endpoint "Health Check" "http://localhost:$PORT/health" "200"
test_endpoint "Database Health" "http://localhost:$PORT/health/db" "200"
test_endpoint "Login Page" "http://localhost:$PORT/" "200"
echo ""

# Test 5: Database
echo -e "${BLUE}[5] Checking database...${NC}"
DB_PATH="/var/www/chemict/smartgardenhub.db"
if [ -f "$DB_PATH" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Database file exists"
    ((PASSED++))
    
    # Check permissions
    DB_PERMS=$(stat -c "%a" "$DB_PATH" 2>/dev/null)
    if [ "$DB_PERMS" = "664" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Database permissions correct (664)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Database permissions: $DB_PERMS (expected 664)"
        ((FAILED++))
    fi
    
    # Check ownership
    DB_OWNER=$(stat -c "%U:%G" "$DB_PATH" 2>/dev/null)
    if [ "$DB_OWNER" = "www-data:www-data" ]; then
        echo -e "${GREEN}✓ PASS${NC} - Database ownership correct"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Database ownership: $DB_OWNER (expected www-data:www-data)"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Database file not found"
    ((FAILED++))
fi
echo ""

# Test 6: Logs
echo -e "${BLUE}[6] Checking log files...${NC}"
if [ -d "/var/www/chemict/logs" ]; then
    echo -e "${GREEN}✓ PASS${NC} - Logs directory exists"
    ((PASSED++))
    
    if [ -f "/var/www/chemict/logs/access.log" ]; then
        LOG_SIZE=$(du -h "/var/www/chemict/logs/access.log" 2>/dev/null | cut -f1)
        echo -e "${GREEN}✓ PASS${NC} - Access log exists (Size: $LOG_SIZE)"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Access log not found (will be created on first request)"
    fi
else
    echo -e "${RED}✗ FAIL${NC} - Logs directory not found"
    ((FAILED++))
fi
echo ""

# Test 7: SSL Certificate (if available)
echo -e "${BLUE}[7] Checking SSL certificate...${NC}"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}✓ PASS${NC} - SSL certificate found"
    ((PASSED++))
    
    # Check expiry
    EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" 2>/dev/null | cut -d= -f2)
    echo -e "  Certificate expires: $EXPIRY"
    
    # Test HTTPS
    test_endpoint "HTTPS Connection" "https://$DOMAIN/health" "200"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - SSL certificate not found (run: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN)"
fi
echo ""

# Test 8: Firewall
echo -e "${BLUE}[8] Checking firewall rules...${NC}"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "80.*ALLOW" && sudo ufw status | grep -q "443.*ALLOW"; then
        echo -e "${GREEN}✓ PASS${NC} - Firewall rules configured"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ WARNING${NC} - Firewall rules may not be configured"
        echo "  Run: sudo ufw allow 80/tcp && sudo ufw allow 443/tcp"
    fi
else
    echo -e "${YELLOW}⚠ INFO${NC} - UFW not installed"
fi
echo ""

# Test 9: Process check
echo -e "${BLUE}[9] Checking running processes...${NC}"
if pgrep -f "gunicorn.*chemict" > /dev/null; then
    WORKER_COUNT=$(pgrep -f "gunicorn.*chemict" | wc -l)
    echo -e "${GREEN}✓ PASS${NC} - Gunicorn workers running ($WORKER_COUNT workers)"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Gunicorn not running"
    ((FAILED++))
fi

if pgrep -f nginx > /dev/null; then
    echo -e "${GREEN}✓ PASS${NC} - Nginx is running"
    ((PASSED++))
else
    echo -e "${RED}✗ FAIL${NC} - Nginx not running"
    ((FAILED++))
fi
echo ""

# Test 10: Disk space
echo -e "${BLUE}[10] Checking disk space...${NC}"
DISK_USAGE=$(df -h /var/www/chemict | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}✓ PASS${NC} - Disk usage is $DISK_USAGE% (healthy)"
    ((PASSED++))
elif [ "$DISK_USAGE" -lt 90 ]; then
    echo -e "${YELLOW}⚠ WARNING${NC} - Disk usage is $DISK_USAGE% (monitor closely)"
else
    echo -e "${RED}✗ FAIL${NC} - Disk usage is $DISK_USAGE% (critical)"
    ((FAILED++))
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    echo ""
    echo "Your application is running at:"
    echo "  • http://localhost:$PORT"
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "  • https://$DOMAIN"
        echo "  • https://www.$DOMAIN"
    else
        echo ""
        echo "To enable HTTPS, run:"
        echo "  sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
    fi
    echo ""
    echo "Default login credentials:"
    echo "  Teacher: 01734285995 / sir@123@"
    echo "  Admin:   01818291546 / sir@123@"
else
    echo -e "${RED}❌ Some tests failed. Please review and fix.${NC}"
    echo ""
    echo "Useful debugging commands:"
    echo "  sudo systemctl status chemict"
    echo "  sudo journalctl -u chemict -n 50"
    echo "  tail -f /var/www/chemict/logs/error.log"
    echo "  sudo nginx -t"
fi
echo "=========================================="
