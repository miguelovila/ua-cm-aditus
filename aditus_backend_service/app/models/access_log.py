from datetime import datetime
from app import db


class AccessLog(db.Model):
    __tablename__ = 'access_logs'

    id = db.Column(db.Integer, primary_key=True)

    # Who accessed
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)

    # Which door
    door_id = db.Column(db.Integer, db.ForeignKey('doors.id'), nullable=False, index=True)

    # Which device (smartphone) was used
    device_id = db.Column(db.Integer, db.ForeignKey('devices.id'), nullable=True, index=True)

    # Access status
    action = db.Column(db.String(50), nullable=False)  # 'unlock', 'lock', 'attempt_denied', etc.
    success = db.Column(db.Boolean, nullable=False)
    failure_reason = db.Column(db.String(200))  # e.g., 'out_of_range', 'no_permission', etc.

    # Location data when access was attempted
    user_latitude = db.Column(db.Float)
    user_longitude = db.Column(db.Float)
    distance_from_door = db.Column(db.Float)  # Distance in meters

    # Additional metadata
    device_info = db.Column(db.Text)  # Could store device model, app version, etc.
    ip_address = db.Column(db.String(45))  # IPv4 or IPv6

    # Timestamp
    timestamp = db.Column(db.DateTime, default=datetime.now, nullable=False, index=True)

    # Relationships
    user = db.relationship('User', back_populates='access_logs')
    door = db.relationship('Door', back_populates='access_logs')
    device = db.relationship('Device', back_populates='access_logs')

    def to_dict(self, include_user_info=True, include_door_info=True, include_device_info=True):
        """Convert access log to dictionary"""
        data = {
            'id': self.id,
            'action': self.action,
            'success': self.success,
            'failure_reason': self.failure_reason,
            'user_latitude': self.user_latitude,
            'user_longitude': self.user_longitude,
            'distance_from_door': self.distance_from_door,
            'device_info': self.device_info,
            'ip_address': self.ip_address,
            'timestamp': self.timestamp.isoformat() if self.timestamp else None,
        }

        if include_user_info and self.user:
            data['user'] = {
                'id': self.user.id,
                'email': self.user.email,
                'full_name': self.user.full_name or self.user.email
            }

        if include_door_info and self.door:
            data['door'] = {
                'id': self.door.id,
                'name': self.door.name,
                'location': self.door.location
            }

        if include_device_info and self.device:
            data['device'] = {
                'id': self.device.id,
                'name': self.device.name,
                'owner_id': self.device.owner_id
            }

        return data

    @staticmethod
    def log_access(user_id, door_id, action, success, device_id=None, failure_reason=None,
                   user_lat=None, user_lon=None, distance=None,
                   device_info=None, ip_address=None):
        """
        Static method to create an access log entry
        """
        log = AccessLog(
            user_id=user_id,
            door_id=door_id,
            device_id=device_id,
            action=action,
            success=success,
            failure_reason=failure_reason,
            user_latitude=user_lat,
            user_longitude=user_lon,
            distance_from_door=distance,
            device_info=device_info,
            ip_address=ip_address
        )
        db.session.add(log)
        return log

    def __repr__(self):
        return f'<AccessLog user={self.user_id} door={self.door_id} device={self.device_id} action={self.action} success={self.success}>'
