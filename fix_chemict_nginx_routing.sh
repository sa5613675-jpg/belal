#!/bin/bash

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║         🔧 FIX NGINX ROUTING FOR CHEMICT.COM → PORT 8006                     ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

echo "📋 Step 1: Checking which Nginx config is handling chemict.com..."
echo ""

# Check if chemict.com config exists and is enabled
if [ -f /etc/nginx/sites-available/chemict.com ]; then
    echo "✅ Found: /etc/nginx/sites-available/chemict.com"
    echo ""
    echo "📄 Current configuration:"
    cat /etc/nginx/sites-available/chemict.com
    echo ""
else
    echo "❌ NOT FOUND: /etc/nginx/sites-available/chemict.com"
fi

# Check if it's linked in sites-enabled
if [ -L /etc/nginx/sites-enabled/chemict.com ]; then
    echo "✅ Config is enabled (linked in sites-enabled)"
else
    echo "⚠️  Config is NOT enabled"
    echo "🔧 Creating symlink..."
    ln -sf /etc/nginx/sites-available/chemict.com /etc/nginx/sites-enabled/
    echo "✅ Symlink created"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 2: Checking for conflicting server blocks..."
echo ""

# List all enabled sites and their server names
echo "All enabled Nginx sites:"
for site in /etc/nginx/sites-enabled/*; do
    if [ -f "$site" ]; then
        echo ""
        echo "File: $(basename $site)"
        grep -E "server_name|proxy_pass|listen" "$site" | head -5
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 3: Testing Nginx configuration..."
echo ""

nginx -t
NGINX_TEST=$?

if [ $NGINX_TEST -eq 0 ]; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors - please fix them first"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 4: Checking if chemict service is running..."
echo ""

systemctl status chemict --no-pager -l | head -10
SERVICE_STATUS=$?

if systemctl is-active --quiet chemict; then
    echo "✅ chemict service is running"
    
    # Check if it's actually listening on port 8006
    if netstat -tuln | grep -q ":8006"; then
        echo "✅ Port 8006 is listening"
    else
        echo "❌ Port 8006 is NOT listening!"
        echo "🔧 Restarting service..."
        systemctl restart chemict
        sleep 2
    fi
else
    echo "❌ chemict service is NOT running"
    echo "🔧 Starting service..."
    systemctl start chemict
    sleep 2
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 5: Testing actual routing..."
echo ""

echo "Test 1: Direct app access (port 8006)"
curl -s http://localhost:8006/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8006/health

echo ""
echo "Test 2: Through Nginx with Host header"
curl -s -H "Host: chemict.com" http://localhost/health | python3 -m json.tool 2>/dev/null || curl -s -H "Host: chemict.com" http://localhost/health

echo ""
echo "Test 3: Through Nginx using domain name"
curl -s http://chemict.com/health | python3 -m json.tool 2>/dev/null || curl -s http://chemict.com/health

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Step 6: Reloading Nginx..."
echo ""

systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✅ Nginx reloaded successfully"
else
    echo "⚠️  Nginx reload failed, trying restart..."
    systemctl restart nginx
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Final Test: Accessing chemict.com..."
echo ""

sleep 2
echo "Response from http://chemict.com/health:"
curl -s http://chemict.com/health | python3 -m json.tool 2>/dev/null || curl -s http://chemict.com/health

echo ""
echo ""
cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                            🎯 EXPECTED RESULT                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

You should see:
{
  "app": "SmartGardenHub",
  "environment": "production", 
  "status": "healthy"
}

If you see this, chemict.com is correctly routing to port 8006! ✅

If you see different content, there may be:
1. A default server block catching the request
2. Another config with higher priority
3. Browser cache (try incognito mode)

╔══════════════════════════════════════════════════════════════════════════════╗
║                         📝 TROUBLESHOOTING STEPS                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

If chemict.com still shows wrong app:

1. Check for default server block:
   grep -r "default_server" /etc/nginx/sites-enabled/

2. Disable default site temporarily:
   rm /etc/nginx/sites-enabled/default
   systemctl reload nginx

3. Check browser cache:
   - Open chemict.com in incognito/private mode
   - Or clear browser cache completely

4. Verify DNS (wait 5 minutes after changes):
   curl -I http://chemict.com

5. Check Nginx error logs:
   tail -f /var/log/nginx/error.log

EOF
