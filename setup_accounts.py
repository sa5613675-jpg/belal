#!/usr/bin/env python3
"""
Setup accounts for Chemistry and ICT Care by Belal Sir
- Teacher: 01734285995 (password: sir@123@)
- Admin: 01818291546 (password: sir@123@)
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from models import User, UserRole, db
from werkzeug.security import generate_password_hash

def setup_accounts():
    app = create_app()
    with app.app_context():
        try:
            # Add Teacher Account - Belal Sir
            teacher_phone = '01734285995'
            existing_teacher = User.query.filter_by(phoneNumber=teacher_phone).first()
            
            if existing_teacher:
                print(f"📝 Updating existing teacher: {teacher_phone}")
                existing_teacher.password_hash = generate_password_hash('sir@123@')
                existing_teacher.first_name = 'Belal'
                existing_teacher.last_name = 'Sir'
                existing_teacher.email = 'mbhossain430@gmail.com'
                existing_teacher.role = UserRole.TEACHER
                existing_teacher.is_active = True
                if existing_teacher.sms_count is None or existing_teacher.sms_count < 100:
                    existing_teacher.sms_count = 100
                print(f"✅ Teacher account updated: {teacher_phone}")
            else:
                teacher = User(
                    phoneNumber=teacher_phone,
                    first_name='Belal',
                    last_name='Sir',
                    email='mbhossain430@gmail.com',
                    password_hash=generate_password_hash('sir@123@'),
                    role=UserRole.TEACHER,
                    is_active=True,
                    sms_count=100
                )
                db.session.add(teacher)
                print(f"✅ Teacher account created: {teacher_phone}")
            
            # Add Admin Account
            admin_phone = '01818291546'
            existing_admin = User.query.filter_by(phoneNumber=admin_phone).first()
            
            if existing_admin:
                print(f"📝 Updating existing admin: {admin_phone}")
                existing_admin.password_hash = generate_password_hash('sir@123@')
                existing_admin.first_name = 'Admin'
                existing_admin.last_name = 'User'
                existing_admin.email = 'admin@chemict.com'
                existing_admin.role = UserRole.TEACHER
                existing_admin.is_active = True
                if existing_admin.sms_count is None or existing_admin.sms_count < 200:
                    existing_admin.sms_count = 200
                print(f"✅ Admin account updated: {admin_phone}")
            else:
                admin = User(
                    phoneNumber=admin_phone,
                    first_name='Admin',
                    last_name='User',
                    email='admin@chemict.com',
                    password_hash=generate_password_hash('sir@123@'),
                    role=UserRole.TEACHER,
                    is_active=True,
                    sms_count=200
                )
                db.session.add(admin)
                print(f"✅ Admin account created: {admin_phone}")
            
            db.session.commit()
            
            print("\n" + "="*60)
            print("✅ ALL ACCOUNTS SETUP COMPLETE!")
            print("="*60)
            print("\n📱 TEACHER ACCOUNT (Belal Sir):")
            print(f"   Phone: {teacher_phone}")
            print(f"   Password: sir@123@")
            print(f"   Email: mbhossain430@gmail.com")
            print(f"   Role: Teacher")
            
            print("\n🔐 ADMIN ACCOUNT:")
            print(f"   Phone: {admin_phone}")
            print(f"   Password: sir@123@")
            print(f"   Email: admin@chemict.com")
            print(f"   Role: Teacher (Admin)")
            
            print("\n🌐 VPS DEPLOYMENT INFO:")
            print(f"   Domain: https://chemict.com")
            print(f"   Port: 8006")
            print(f"   Database: SQLite")
            print("="*60)
            
            return True
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Error setting up accounts: {e}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == "__main__":
    print("Setting up accounts for Chemistry and ICT Care...")
    print("="*60)
    setup_accounts()
