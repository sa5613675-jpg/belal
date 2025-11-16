# VPS Deployment Guide - SQLite Production Ready

## 🚀 Quick Deploy to VPS

### 1️⃣ **On Your VPS Server**

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Navigate to project directory
cd /root/saroyarsir

# Pull latest code from GitHub
git pull origin main

# Stop the service
sudo systemctl stop saro_vps

# Install/update dependencies
pip3 install -r requirements.txt

# Set production environment
export FLASK_ENV=production
export DATABASE_URL=sqlite:////root/saroyarsir/smartgardenhub_production.db

# Initialize production database (if first time)
python3 << 'EOF'
from app import create_app
from models import db

app = create_app('production')
with app.app_context():
    db.create_all()
    print("✅ Production database tables created!")
EOF

# Create admin and teacher accounts for production
python3 << 'EOF'
from app import create_app
from models import db, User, UserRole
from flask_bcrypt import Bcrypt

app = create_app('production')
bcrypt = Bcrypt(app)

with app.app_context():
    # Create super user
    admin = User.query.filter_by(phoneNumber='01700000000').first()
    if not admin:
        admin = User(
            first_name='Admin',
            last_name='User',
            phoneNumber='01700000000',
            role=UserRole.SUPER_USER,
            is_active=True,
            email='admin@gsteaching.com'
        )
        admin.password_hash = bcrypt.generate_password_hash('admin123').decode('utf-8')
        db.session.add(admin)
        print("✅ Created SUPER USER: 01700000000 / admin123")
    
    # Create teacher account
    teacher = User.query.filter_by(phoneNumber='01800000000').first()
    if not teacher:
        teacher = User(
            first_name='Teacher',
            last_name='One',
            phoneNumber='01800000000',
            role=UserRole.TEACHER,
            is_active=True,
            email='teacher@gsteaching.com'
        )
        teacher.password_hash = bcrypt.generate_password_hash('teacher123').decode('utf-8')
        db.session.add(teacher)
        print("✅ Created TEACHER: 01800000000 / teacher123")
    
    db.session.commit()
    print("\n🎉 Production accounts ready!")
EOF

# Copy service file
sudo cp saro_vps.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Start the service
sudo systemctl start saro_vps

# Enable on boot
sudo systemctl enable saro_vps

# Check status
sudo systemctl status saro_vps
```

---

## 📁 **Database File Locations**

### Development (Local):
```
/workspaces/saroyarsir/smartgardenhub.db
```

### Production (VPS):
```
/root/saroyarsir/smartgardenhub_production.db
```

---

## 🔧 **Configuration Files Already Set**

### 1. `config.py`
```python
PRODUCTION = {
    'SQLALCHEMY_DATABASE_URI': 'sqlite:////root/saroyarsir/smartgardenhub_production.db',
    'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    'SECRET_KEY': os.getenv('SECRET_KEY', 'your-secret-key-here'),
    'DEBUG': False
}
```

### 2. `app.py`
- Automatically uses SQLite based on environment
- Production mode when `FLASK_ENV=production`

### 3. `gunicorn.conf.py`
- Port: 8001
- Workers: 2
- Bind: 0.0.0.0:8001

### 4. `saro_vps.service`
```ini
[Unit]
Description=Chemistry and ICT Care Application
After=network.target

[Service]
User=root
WorkingDirectory=/root/saroyarsir
Environment="FLASK_ENV=production"
Environment="DATABASE_URL=sqlite:////root/saroyarsir/smartgardenhub_production.db"
ExecStart=/usr/bin/python3 -m gunicorn -c gunicorn.conf.py app:app
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## ✅ **What's Included in This Push**

### **New Features:**
1. ✅ **Online Exam System**
   - MCQ exams with 40 questions max
   - Auto-submit when timer expires
   - Instant results
   - Bangla text support
   - Scientific equation support (MathJax)
   - Mobile-responsive interface

2. ✅ **Fee System Updates**
   - 14 columns: 12 months + exam_fee + other_fee
   - Total calculation includes all fees

3. ✅ **SMS Templates**
   - Permanent save to database
   - No more session-only storage

4. ✅ **Monthly Exam Fixes**
   - Cascade delete with students, batches, results

### **Bug Fixes:**
- Fixed timer issues in online exams
- Fixed double submission prevention
- Fixed multiple exam attempts in same session
- Mobile-responsive exam interface
- Bangla font support (Noto Sans Bengali)

---

## 🔐 **Default Login Credentials**

### Super Admin:
- Phone: `01700000000`
- Password: `admin123`

### Teacher:
- Phone: `01800000000`
- Password: `teacher123`

**⚠️ Change these passwords after first login in production!**

---

## 📊 **Database Tables**

All tables automatically created:
- users
- students
- batches
- batch_enrollment
- monthly_exams
- monthly_exam_results
- fees
- attendance
- documents
- sms_logs
- settings
- **online_exams** ⭐ NEW
- **online_questions** ⭐ NEW
- **online_exam_attempts** ⭐ NEW
- **online_student_answers** ⭐ NEW

---

## 🔄 **Service Management Commands**

```bash
# Start service
sudo systemctl start saro_vps

# Stop service
sudo systemctl stop saro_vps

# Restart service
sudo systemctl restart saro_vps

# Check status
sudo systemctl status saro_vps

# View logs
sudo journalctl -u saro_vps -f

# Enable on boot
sudo systemctl enable saro_vps
```

---

## 🌐 **Access Application**

### Local Development:
```
http://localhost:8001
```

### Production VPS:
```
http://your-vps-ip:8001
```

Or if you have domain:
```
http://yourdomain.com:8001
```

---

## 📱 **Testing Online Exams**

### Teacher Side:
1. Login as teacher
2. Click "Online Exam" menu
3. Create new exam
4. Fill 20 questions (auto-generated forms)
5. Save all & publish

### Student Side:
1. Login as student
2. Click "Online Exam" menu
3. See all published exams
4. Click "Start Exam"
5. Answer questions (mobile-optimized)
6. Submit or wait for auto-submit

---

## 🔒 **Security Notes**

1. **SQLite Database**:
   - File permissions: `chmod 644 smartgardenhub_production.db`
   - Owner: `chown root:root smartgardenhub_production.db`

2. **Backup Database**:
   ```bash
   # Daily backup
   cp /root/saroyarsir/smartgardenhub_production.db \
      /root/backups/smartgardenhub_$(date +%Y%m%d).db
   ```

3. **Firewall**:
   ```bash
   sudo ufw allow 8001/tcp
   ```

---

## 🆘 **Troubleshooting**

### Service won't start:
```bash
# Check logs
sudo journalctl -u saro_vps -n 50

# Check if port is in use
sudo lsof -i :8001

# Kill process on port 8001
sudo kill -9 $(sudo lsof -t -i:8001)
```

### Database errors:
```bash
# Check file exists
ls -la /root/saroyarsir/smartgardenhub_production.db

# Check permissions
sudo chmod 644 /root/saroyarsir/smartgardenhub_production.db
```

### Can't access from browser:
```bash
# Check service is running
sudo systemctl status saro_vps

# Check if app is listening
sudo netstat -tulpn | grep 8001

# Check firewall
sudo ufw status
```

---

## 🎯 **Ready for Production!**

Your application is now:
- ✅ Using SQLite database (production-ready)
- ✅ Running on port 8001
- ✅ Configured with systemd service
- ✅ Auto-restart on failure
- ✅ All features included:
  - Student management
  - Batch management
  - Monthly exams
  - **Online exams** ⭐
  - Fee management (14 columns)
  - Attendance
  - SMS
  - Documents
  - AI Questions

---

## 📞 **Support**

If you encounter any issues:
1. Check logs: `sudo journalctl -u saro_vps -f`
2. Verify database: `ls -la *.db`
3. Check service status: `sudo systemctl status saro_vps`

**All code is pushed to GitHub and ready to deploy!** 🚀
