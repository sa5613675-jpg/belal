# 🚀 Multi-App VPS Management Guide

## Your VPS Setup (194.233.74.48)

### Active Applications

| Domain | Port | App | Service |
|--------|------|-----|---------|
| saroyarsir.com | 8001 | Sarovar App | saroyarsir.service |
| hosp.com | 8005 | Hospital App | hosp.service |
| **chemict.com** | **8006** | **Chemistry/ICT** | **chemict.service** |
| nazipuruhs.com | ? | Nazipur HS | ? |
| gsteaching.com | ? | GS Teaching | ? |
| madrasha | ? | Madrasha | ? |

## 🎯 How Nginx Routes Multiple Apps on Same IP

When a request comes to `194.233.74.48`, Nginx looks at the `Host` header to determine which app to serve:

```
User Browser → chemict.com → DNS → 194.233.74.48:80 
                                         ↓
                                    Nginx checks Host header
                                         ↓
                        Host: chemict.com? → Proxy to localhost:8006
                        Host: saroyarsir.com? → Proxy to localhost:8001  
                        Host: hosp.com? → Proxy to localhost:8005
```

## 📁 Nginx Configuration Structure

```
/etc/nginx/
├── sites-available/          # All available configs
│   ├── chemict.com          # Your chemistry app config
│   ├── saroyarsir.com       # Sarovar app config
│   ├── hosp.com             # Hospital app config
│   └── default              # Default catch-all (disable this!)
├── sites-enabled/           # Active configs (symlinks)
│   ├── chemict.com → ../sites-available/chemict.com
│   ├── saroyarsir.com → ../sites-available/saroyarsir.com
│   └── hosp.com → ../sites-available/hosp.com
└── nginx.conf               # Main config
```

## 🔧 Troubleshooting "Wrong App Shows Up"

### Issue: chemict.com shows GS Student Nursing Center instead of Chemistry app

**Possible Causes:**

1. **Nginx config not enabled**
   ```bash
   # Check if symlink exists
   ls -la /etc/nginx/sites-enabled/chemict.com
   
   # If missing, create it
   ln -sf /etc/nginx/sites-available/chemict.com /etc/nginx/sites-enabled/
   systemctl reload nginx
   ```

2. **Default server block catching requests**
   ```bash
   # Check for default_server directive
   grep -r "default_server" /etc/nginx/sites-enabled/
   
   # Temporarily disable default
   rm /etc/nginx/sites-enabled/default
   systemctl reload nginx
   ```

3. **Another config has same server_name**
   ```bash
   # Check all server names
   grep -r "server_name" /etc/nginx/sites-enabled/
   
   # Look for conflicts or wildcards
   ```

4. **Browser cache**
   ```bash
   # Test with curl first
   curl -I http://chemict.com
   
   # Then try incognito mode in browser
   ```

5. **Service not running on port 8006**
   ```bash
   # Check service status
   systemctl status chemict
   
   # Check if port is listening
   netstat -tuln | grep 8006
   
   # Restart if needed
   systemctl restart chemict
   ```

## 📝 Standard Nginx Config Template for Each App

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Optional: redirect www to non-www
    if ($host = www.your-domain.com) {
        return 301 http://your-domain.com$request_uri;
    }
    
    # Proxy to your app port
    location / {
        proxy_pass http://127.0.0.1:YOUR_PORT;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static files (if needed)
    location /static/ {
        alias /var/www/your-app/static/;
        expires 30d;
    }
    
    # Access logs
    access_log /var/log/nginx/your-domain.access.log;
    error_log /var/log/nginx/your-domain.error.log;
}
```

## 🚦 Port Management Strategy

**Used Ports:**
- 8001: saroyarsir.com
- 8005: hosp.com
- **8006: chemict.com** ← Your new app

**Available Ports:** 8002, 8003, 8004, 8007, 8008, etc.

**Best Practice:**
- Keep a spreadsheet/doc of port assignments
- Use sequential ports (8001, 8002, 8003...)
- Reserve 80 for Nginx, 443 for SSL
- Never use system ports (0-1024) for apps

## 🔍 Diagnostic Commands

### Check all running apps
```bash
# See all Python/Gunicorn processes
ps aux | grep -E "gunicorn|python" | grep -v grep

# See what ports are in use
netstat -tuln | grep LISTEN

# See all systemd services
systemctl list-units --type=service --state=running | grep -E "chemict|saroyar|hosp|madrasha"
```

### Test each app directly
```bash
# Test port 8001 (saroyarsir)
curl http://localhost:8001/health

# Test port 8005 (hosp)
curl http://localhost:8005/health

# Test port 8006 (chemict)
curl http://localhost:8006/health
```

### Test through Nginx
```bash
# Test with Host header
curl -H "Host: chemict.com" http://localhost/health
curl -H "Host: saroyarsir.com" http://localhost/health
curl -H "Host: hosp.com" http://localhost/health

# Test actual domains
curl http://chemict.com/health
curl http://saroyarsir.com/health
curl http://hosp.com/health
```

### Check Nginx routing
```bash
# See active Nginx configs
ls -la /etc/nginx/sites-enabled/

# Test Nginx config syntax
nginx -t

# View full Nginx config
nginx -T | less

# Check Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

## 🔄 Adding a New App to VPS

### Step-by-step process:

1. **Choose next available port** (e.g., 8007)

2. **Deploy app files**
   ```bash
   mkdir -p /var/www/newapp
   cd /var/www/newapp
   git clone your-repo .
   ```

3. **Set up virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Create systemd service** (`/etc/systemd/system/newapp.service`)
   ```ini
   [Unit]
   Description=New App
   After=network.target
   
   [Service]
   User=root
   Group=root
   WorkingDirectory=/var/www/newapp
   ExecStart=/var/www/newapp/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:8007 wsgi:app
   Restart=always
   
   [Install]
   WantedBy=multi-user.target
   ```

5. **Create Nginx config** (`/etc/nginx/sites-available/newapp.com`)
   ```nginx
   server {
       listen 80;
       server_name newapp.com www.newapp.com;
       
       location / {
           proxy_pass http://127.0.0.1:8007;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

6. **Enable and start**
   ```bash
   # Enable Nginx config
   ln -sf /etc/nginx/sites-available/newapp.com /etc/nginx/sites-enabled/
   nginx -t && systemctl reload nginx
   
   # Enable and start service
   systemctl enable newapp
   systemctl start newapp
   systemctl status newapp
   ```

7. **Update DNS**
   - Point newapp.com A record to 194.233.74.48

## 🛡️ Security Best Practices

### Firewall rules
```bash
# Allow only necessary ports
ufw allow 80/tcp     # HTTP
ufw allow 443/tcp    # HTTPS
ufw allow 22/tcp     # SSH

# Block direct access to app ports from outside
ufw deny 8001:8010/tcp

# Enable firewall
ufw enable
```

### SSL Certificates
```bash
# Install certbot
apt install certbot python3-certbot-nginx

# Get certificate for each domain
certbot --nginx -d chemict.com -d www.chemict.com
certbot --nginx -d saroyarsir.com -d www.saroyarsir.com

# Auto-renewal is configured automatically
certbot renew --dry-run
```

## 📊 Monitoring Multiple Apps

### Create a status check script
```bash
#!/bin/bash
# /root/check_all_apps.sh

echo "=== App Status Check ==="
echo ""

apps=("chemict:8006" "saroyarsir:8001" "hosp:8005")

for app in "${apps[@]}"; do
    name="${app%:*}"
    port="${app#*:}"
    
    echo "[$name] Port $port:"
    if systemctl is-active --quiet $name; then
        echo "  ✅ Service: Running"
    else
        echo "  ❌ Service: Stopped"
    fi
    
    if netstat -tuln | grep -q ":$port"; then
        echo "  ✅ Port: Listening"
    else
        echo "  ❌ Port: Not listening"
    fi
    
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health)
    if [ "$response" = "200" ]; then
        echo "  ✅ Health: OK"
    else
        echo "  ❌ Health: Failed (HTTP $response)"
    fi
    echo ""
done
```

### Set up automated monitoring
```bash
# Add to crontab
crontab -e

# Check every 5 minutes, restart if down
*/5 * * * * /root/check_all_apps.sh >> /var/log/app_monitor.log
```

## 🎯 Quick Reference Commands

```bash
# Restart all apps
systemctl restart chemict saroyarsir hosp

# Reload Nginx without downtime
systemctl reload nginx

# View all app logs at once
journalctl -u chemict -u saroyarsir -u hosp -f

# Check which app is using which port
netstat -tuln | grep -E ":(8001|8005|8006)"

# Test all domains at once
for domain in chemict.com saroyarsir.com hosp.com; do
    echo "=== $domain ==="
    curl -s http://$domain/health
    echo ""
done
```

## 🔧 Emergency Recovery

### If everything breaks:
```bash
# 1. Stop all services
systemctl stop chemict saroyarsir hosp nginx

# 2. Check what's using ports
netstat -tuln | grep -E ":(80|443|8001|8005|8006)"

# 3. Kill any stuck processes
lsof -ti:8006 | xargs kill -9

# 4. Start services one by one
systemctl start chemict && sleep 2
systemctl start saroyarsir && sleep 2  
systemctl start hosp && sleep 2
systemctl start nginx

# 5. Verify each app
curl http://localhost:8006/health
curl http://localhost:8001/health
curl http://localhost:8005/health
```

---

## 📞 Support Checklist

When asking for help, provide:
- [ ] VPS IP address
- [ ] Domain name having issues
- [ ] Expected app port
- [ ] Output of `systemctl status <service-name>`
- [ ] Output of `curl http://localhost:<port>/health`
- [ ] Output of `curl -I http://domain.com`
- [ ] Nginx error logs: `tail -20 /var/log/nginx/error.log`

---

**Last Updated:** November 17, 2025
**VPS IP:** 194.233.74.48
**Apps Running:** chemict (8006), saroyarsir (8001), hosp (8005)
