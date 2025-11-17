#!/bin/bash

cat << 'EOF'

╔══════════════════════════════════════════════════════════════════════════════╗
║              🚀 START CHEMISTRY APP ON PORT 8006                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

EOF

echo "📍 Current directory: $(pwd)"
echo ""

# Step 1: Check if we're in the right directory
if [ ! -f "app.py" ]; then
    echo "❌ app.py not found. Changing to /var/www/chemict..."
    cd /var/www/chemict
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 1: Checking if service exists..."
echo ""

if [ -f /etc/systemd/system/chemict.service ]; then
    echo "✅ Service file exists"
    
    echo ""
    echo "🔍 Current service status:"
    systemctl status chemict --no-pager -l | head -15
    
    echo ""
    echo "🛑 Stopping any existing service..."
    systemctl stop chemict
    sleep 2
else
    echo "⚠️  Service file not found - will run manually"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 2: Checking for processes on port 8006..."
echo ""

# Kill any process using port 8006
if lsof -ti:8006 > /dev/null 2>&1; then
    echo "⚠️  Port 8006 is in use. Killing existing processes..."
    lsof -ti:8006 | xargs kill -9
    sleep 2
    echo "✅ Port 8006 cleared"
else
    echo "✅ Port 8006 is free"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 3: Checking virtual environment..."
echo ""

if [ ! -d "venv" ]; then
    echo "⚠️  Virtual environment not found. Creating..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
fi

echo "🔧 Activating virtual environment..."
source venv/bin/activate

echo ""
echo "📦 Installing/updating dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

echo "✅ Dependencies ready"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 4: Checking database..."
echo ""

if [ ! -f "smartgardenhub.db" ]; then
    echo "⚠️  Database not found. Initializing..."
    python3 << 'PYTHON'
from app import app, db
with app.app_context():
    db.create_all()
    print("✅ Database initialized")
PYTHON
else
    echo "✅ Database exists: smartgardenhub.db"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 5: Creating logs directory..."
echo ""

mkdir -p logs
chmod -R 777 logs
echo "✅ Logs directory ready"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Step 6: Testing app configuration..."
echo ""

python3 << 'PYTHON'
try:
    from app import app
    from config import config
    
    print(f"✅ App loaded successfully")
    print(f"   Environment: {app.config.get('ENV', 'unknown')}")
    print(f"   Debug: {app.config.get('DEBUG', False)}")
    print(f"   Database: {app.config.get('SQLALCHEMY_DATABASE_URI', 'not set')}")
    
    # Check if port 8006 is in config
    import os
    port = int(os.environ.get('PORT', 8006))
    print(f"   Port: {port}")
    
    if port != 8006:
        print(f"   ⚠️  WARNING: Port is {port}, expected 8006")
        
except Exception as e:
    print(f"❌ Error loading app: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
PYTHON

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ App configuration test failed. Please fix the errors above."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 7: Starting the app..."
echo ""

cat << 'INFO'
╔══════════════════════════════════════════════════════════════════════════════╗
║                        CHOOSE STARTUP METHOD                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

Option 1: Start as systemd service (RECOMMENDED for production)
   systemctl start chemict
   systemctl status chemict
   
Option 2: Run with Gunicorn manually (for testing)
   gunicorn --workers 4 --bind 0.0.0.0:8006 wsgi:app
   
Option 3: Run with Flask development server (for debugging)
   python3 wsgi.py

INFO

echo ""
echo "🔄 Starting with Gunicorn (manual mode for testing)..."
echo ""

# Check if gunicorn is installed
if ! command -v gunicorn &> /dev/null; then
    echo "⚠️  Gunicorn not found. Installing..."
    pip install gunicorn
fi

echo "Starting app on http://0.0.0.0:8006 ..."
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start gunicorn
gunicorn --workers 4 --bind 0.0.0.0:8006 --access-logfile logs/access.log --error-logfile logs/error.log wsgi:app

# If gunicorn exits, show the error
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Gunicorn stopped"
echo ""
echo "Last 20 lines of error log:"
if [ -f logs/error.log ]; then
    tail -20 logs/error.log
else
    echo "No error log found"
fi
