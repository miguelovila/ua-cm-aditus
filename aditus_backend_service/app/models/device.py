from datetime import datetime
from app import db

class Device(db.Model):
    __tablename__ = 'devices'

    id = db.Column(db.Integer, primary_key=True)
    owner_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    name = db.Column(db.String(128), unique=False, nullable=False)
    public_key = db.Column(db.String, unique=True, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.now, nullable=False)
    last_used_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # Relationships
    owner = db.relationship('User', back_populates='devices')
    access_logs = db.relationship('AccessLog', back_populates='device', lazy='dynamic')

    def to_dict(self, include_owner=False):
        """Convert device to dictionary"""
        data = {
            'id': self.id,
            'owner_id': self.owner_id,
            'name': self.name,
            'public_key': self.public_key,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_used_at': self.last_used_at.isoformat() if self.last_used_at else None,
        }

        if include_owner and self.owner:
            data['owner'] = self.owner.to_dict()

        return data

    def __repr__(self):
        return f'<Device {self.name} (owner: {self.owner_id})>'