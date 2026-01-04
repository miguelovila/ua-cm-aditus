import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from flask_marshmallow import Marshmallow

db = SQLAlchemy()
jwt = JWTManager()
ma = Marshmallow()


def create_app(config_name=None):
    """Application factory pattern"""

    app = Flask(__name__)

    if config_name is None:
        config_name = os.getenv('FLASK_ENV', 'development')

    from app.config import config
    app.config.from_object(config[config_name])

    db.init_app(app)
    jwt.init_app(app)
    ma.init_app(app)
    CORS(app, origins=app.config['CORS_ORIGINS'])

    from app.routes import auth, users, devices, doors, groups, access_control, access_logs

    app.register_blueprint(auth.bp, url_prefix='/api/auth')
    app.register_blueprint(users.bp, url_prefix='/api/users')
    app.register_blueprint(devices.bp, url_prefix='/api/devices')
    app.register_blueprint(doors.bp, url_prefix='/api/doors')
    app.register_blueprint(groups.bp, url_prefix='/api/groups')
    app.register_blueprint(access_control.bp, url_prefix='/api/doors')  # Nested under /api/doors
    app.register_blueprint(access_logs.bp, url_prefix='/api/access-logs')

    @app.route('/health')
    def health_check():
        return {'status': 'healthy', 'service': 'Aditus Backend'}, 200

    with app.app_context():
        from app.models import User, Device, Door, Group, AccessLog, PairingSession

        db.create_all()

        from app.utils.db_init import create_admin_user
        create_admin_user()

    return app