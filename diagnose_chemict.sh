#!/bin/bash

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║           🔍 DIAGNOSE WHY CHEMISTRY APP ISN'T RUNNING                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

echo "Running comprehensive diagnostics..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  CHECKING SERVICE STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if systemctl list-unit-files | grep -q chemict.service; then
    echo "Service file: ✅ EXISTS"
    echo ""
    systemctl status chemict --no-pager -l || true
    echo ""
    
    if systemctl is-active --quiet chemict; then
        echo "Status: ✅ RUNNING"
    else
        echo "Status: ❌ NOT RUNNING"
        echo ""
        echo "Last 30 lines of service logs:"
        journalctl -u chemict -n 30 --no-pager || true
    fi
else
    echo "Service file: ❌ NOT FOUND at /etc/systemd/system/chemict.service"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  CHECKING PORT 8006"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if netstat -tuln | grep -q ":8006"; then
    echo "Port 8006: ✅ LISTENING"
    echo ""
    netstat -tuln | grep ":8006"
    echo ""
    echo "Process using port 8006:"
    lsof -i:8006 || ss -tlnp | grep :8006
else
    echo "Port 8006: ❌ NOT LISTENING"
    echo ""
    echo "All ports currently in use:"
    netstat -tuln | grep LISTEN | grep -E ":(80|443|5000|8000|8001|8002|8003|8004|8005|8006|8007|8008)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  CHECKING PYTHON/GUNICORN PROCESSES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROCESSES=$(ps aux | grep -E "gunicorn.*8006|python.*wsgi.*8006|flask.*8006" | grep -v grep)
if [ -n "$PROCESSES" ]; then
    echo "Chemistry app processes: ✅ FOUND"
    echo ""
    echo "$PROCESSES"
else
    echo "Chemistry app processes: ❌ NOT FOUND"
    echo ""
    echo "All Python/Gunicorn processes:"
    ps aux | grep -E "python|gunicorn" | grep -v grep | head -10
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  CHECKING APPLICATION FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "/var/www/chemict" ]; then
    echo "App directory: ✅ EXISTS at /var/www/chemict"
    cd /var/www/chemict
    echo ""
    
    echo "Required files:"
    for file in app.py wsgi.py config.py requirements.txt; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file - MISSING"
        fi
    done
    
    echo ""
    if [ -d "venv" ]; then
        echo "Virtual environment: ✅ EXISTS"
        if [ -f "venv/bin/gunicorn" ]; then
            echo "  ✅ gunicorn installed"
        else
            echo "  ❌ gunicorn NOT installed"
        fi
    else
        echo "Virtual environment: ❌ NOT FOUND"
    fi
    
    echo ""
    if [ -f "smartgardenhub.db" ]; then
        echo "Database: ✅ EXISTS ($(du -h smartgardenhub.db | cut -f1))"
    else
        echo "Database: ❌ NOT FOUND"
    fi
    
    echo ""
    if [ -d "logs" ]; then
        echo "Logs directory: ✅ EXISTS"
        if [ -f "logs/error.log" ]; then
            echo ""
            echo "Last 15 lines of error.log:"
            tail -15 logs/error.log
        fi
    else
        echo "Logs directory: ❌ NOT FOUND"
    fi
else
    echo "App directory: ❌ NOT FOUND at /var/www/chemict"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  TESTING APP IMPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "/var/www/chemict" ]; then
    cd /var/www/chemict
    
    if [ -d "venv" ]; then
        source venv/bin/activate
        
        python3 << 'PYTHON'
import sys
print(f"Python version: {sys.version}")
print(f"Python path: {sys.executable}")
print("")

try:
    from app import app
    print("✅ app.py imports successfully")
    print(f"   Flask app: {app.name}")
except Exception as e:
    print(f"❌ Failed to import app.py: {e}")
    import traceback
    traceback.print_exc()

print("")

try:
    from wsgi import app
    print("✅ wsgi.py imports successfully")
except Exception as e:
    print(f"❌ Failed to import wsgi.py: {e}")
    import traceback
    traceback.print_exc()

print("")

try:
    import gunicorn
    print(f"✅ gunicorn installed: {gunicorn.__version__}")
except:
    print("❌ gunicorn NOT installed")
PYTHON
    else
        echo "⚠️  Virtual environment not found - skipping import test"
    fi
else
    echo "⚠️  App directory not found - skipping import test"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  CHECKING PERMISSIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -d "/var/www/chemict" ]; then
    ls -la /var/www/chemict | head -15
else
    echo "⚠️  Directory not found"
fi

echo ""
echo ""
cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║                          🎯 DIAGNOSIS SUMMARY                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

Based on the output above, the issue is likely one of:

1. ❌ Service not started
   FIX: systemctl start chemict

2. ❌ Service file missing or incorrect
   FIX: cd /var/www/chemict && ./quick_deploy_chemict.sh

3. ❌ Virtual environment not set up
   FIX: cd /var/www/chemict && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt

4. ❌ Gunicorn not installed
   FIX: cd /var/www/chemict && source venv/bin/activate && pip install gunicorn

5. ❌ App files missing
   FIX: cd /var/www/chemict && git pull origin main

6. ❌ Permission errors
   FIX: chmod -R 755 /var/www/chemict && chmod 777 /var/www/chemict/logs

7. ❌ Python import errors
   FIX: Check the import test output above for specific errors

╔══════════════════════════════════════════════════════════════════════════════╗
║                       🚀 QUICK FIX - RUN THIS                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

cd /var/www/chemict
git pull origin main
./start_chemict_app.sh

This will diagnose and start the app automatically.

EOF
