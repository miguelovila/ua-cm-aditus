from datetime import datetime, timedelta
from app import db


class PairingSession(db.Model):
    __tablename__ = 'pairing_sessions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    code = db.Column(db.String(6), unique=True, nullable=False, index=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    expires_at = db.Column(db.DateTime, nullable=False)
    is_used = db.Column(db.Boolean, default=False, nullable=False)

    user = db.relationship('User', backref='pairing_sessions')

    def __init__(self, user_id, code, expiry_minutes=5):
        self.user_id = user_id
        self.code = code
        self.expires_at = datetime.utcnow() + timedelta(minutes=expiry_minutes)

    def is_valid(self):
        """Check if pairing session is still valid"""
        return not self.is_used and datetime.utcnow() < self.expires_at

    def mark_as_used(self):
        """Mark pairing session as used"""
        self.is_used = True

    def to_dict(self):
        return {
            'id': self.id,
            'code': self.code,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'is_used': self.is_used,
        }
