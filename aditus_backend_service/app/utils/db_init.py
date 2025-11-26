import os
from app import db
from app.models import User


def create_admin_user():
    """
    Create a default admin user if none exists
    Credentials are loaded from environment variables
    """
    # Check if any admin user exists
    admin_exists = User.query.filter_by(role='admin').first()

    if not admin_exists:
        # Get admin credentials from environment
        admin_email = os.getenv('ADMIN_EMAIL', 'admin@aditus.local')
        admin_password = os.getenv('ADMIN_PASSWORD', 'admin123')
        admin_first_name = os.getenv('ADMIN_FIRST_NAME', 'Admin')
        admin_last_name = os.getenv('ADMIN_LAST_NAME', 'User')

        # Create admin user
        admin = User(
            email=admin_email,
            full_name=f"{admin_first_name} {admin_last_name}",
            role='admin'
        )
        admin.set_password(admin_password)

        db.session.add(admin)
        db.session.commit()

        print(f"✓ Admin user created: {admin_email}")
        print(f"  Password: {admin_password}")
        print("  IMPORTANT: Change this password in production!")
    else:
        print(f"✓ Admin user already exists: {admin_exists.email}")