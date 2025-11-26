from datetime import datetime
from app import db
from app.models.user import user_door_access, user_door_exceptions
from app.models.group import group_door_access, group_door_exceptions


class Door(db.Model):
    __tablename__ = 'doors'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text)
    location = db.Column(db.String(200))

    # GPS coordinates for location-based access control
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)

    # Door status
    is_active = db.Column(db.Boolean, default=True, nullable=False)

    # Bluetooth/IoT identifier (for future use with door_app)
    device_id = db.Column(db.String(100), unique=True)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.now, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # Relationships
    groups = db.relationship(
        'Group',
        secondary=group_door_access,
        back_populates='doors',
        lazy='dynamic'
    )
    exception_groups = db.relationship(
        'Group',
        secondary=group_door_exceptions,
        back_populates='exception_doors',
        lazy='dynamic'
    )
    direct_users = db.relationship(
        'User',
        secondary=user_door_access,
        primaryjoin='Door.id == user_door_access.c.door_id',
        secondaryjoin='User.id == user_door_access.c.user_id',
        back_populates='direct_door_access',
        lazy='dynamic'
    )
    exception_users = db.relationship(
        'User',
        secondary=user_door_exceptions,
        primaryjoin='Door.id == user_door_exceptions.c.door_id',
        secondaryjoin='User.id == user_door_exceptions.c.user_id',
        back_populates='door_exceptions',
        lazy='dynamic'
    )
    access_logs = db.relationship('AccessLog', back_populates='door', lazy='dynamic')

    def to_dict(self, include_access_info=False):
        """Convert door to dictionary"""
        data = {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'location': self.location,
            'latitude': self.latitude,
            'longitude': self.longitude,
            'is_active': self.is_active,
            'device_id': self.device_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

        if include_access_info:
            data['groups'] = [{'id': g.id, 'name': g.name} for g in self.groups]
            data['exception_groups'] = [{'id': g.id, 'name': g.name} for g in self.exception_groups]
            data['direct_users_count'] = self.direct_users.count()
            data['exception_users_count'] = self.exception_users.count()

        return data

    def __repr__(self):
        return f'<Door {self.name}>'
