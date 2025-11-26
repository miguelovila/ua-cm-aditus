from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from app import db

user_groups = db.Table('user_groups',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('group_id', db.Integer, db.ForeignKey('groups.id'), primary_key=True),
    db.Column('joined_at', db.DateTime, default=datetime.now, nullable=False)
)

# Association table for user-door direct access (bypassing groups)
user_door_access = db.Table('user_door_access',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('door_id', db.Integer, db.ForeignKey('doors.id'), primary_key=True),
    db.Column('granted_at', db.DateTime, default=datetime.now, nullable=False),
    db.Column('granted_by', db.Integer, db.ForeignKey('users.id'))
)

# Association table for user-door exceptions (deny access even if group allows)
user_door_exceptions = db.Table('user_door_exceptions',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('door_id', db.Integer, db.ForeignKey('doors.id'), primary_key=True),
    db.Column('denied_at', db.DateTime, default=datetime.now, nullable=False),
    db.Column('denied_by', db.Integer, db.ForeignKey('users.id'))
)

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    full_name = db.Column(db.String(255))
    role = db.Column(db.String(50), default='user', nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.now, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # Relationships
    devices = db.relationship('Device', back_populates='owner', lazy='dynamic', cascade='all, delete-orphan')
    groups = db.relationship('Group', secondary=user_groups, back_populates='members', lazy='dynamic')
    direct_door_access = db.relationship(
        'Door',
        secondary=user_door_access,
        primaryjoin='User.id == user_door_access.c.user_id',
        secondaryjoin='Door.id == user_door_access.c.door_id',
        back_populates='direct_users',
        lazy='dynamic'
    )
    door_exceptions = db.relationship(
        'Door',
        secondary=user_door_exceptions,
        primaryjoin='User.id == user_door_exceptions.c.user_id',
        secondaryjoin='Door.id == user_door_exceptions.c.door_id',
        back_populates='exception_users',
        lazy='dynamic'
    )
    access_logs = db.relationship('AccessLog', back_populates='user', lazy='dynamic')

    def set_password(self, password):
        """Hash and set the user's password"""
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        """Verify the user's password"""
        return check_password_hash(self.password_hash, password)

    def is_admin(self):
        """Check if user is an admin"""
        return self.role == 'admin'

    def has_access_to_door(self, door):
        """
        Check if user has access to a specific door
        Priority: Exceptions > Direct Access > Group Access
        """
        # First check exceptions (highest priority - deny)
        if door in self.door_exceptions:
            return False

        # Check direct access
        if door in self.direct_door_access:
            return True

        # Check group access
        for group in self.groups:
            if door in group.doors and group not in door.exception_groups:
                return True

        return False

    def to_dict(self, include_sensitive=False):
        """Convert user to dictionary"""
        data = {
            'id': self.id,
            'email': self.email,
            'full_name': self.full_name,
            'role': self.role,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.created_at.isoformat() if self.created_at else None,
        }

        if include_sensitive:
            # Groups the user belongs to
            data['groups'] = [
                {'id': g.id, 'name': g.name}
                for g in self.groups
            ]

            # Devices owned by the user
            data['devices'] = [
                {'id': d.id, 'name': d.name, 'public_key': d.public_key}
                for d in self.devices
            ]

            # Doors with direct access
            data['direct_door_access'] = [
                {'id': d.id, 'name': d.name, 'location': d.location}
                for d in self.direct_door_access
            ]

            # Doors the user is explicitly denied access to
            data['door_exceptions'] = [
                {'id': d.id, 'name': d.name, 'location': d.location}
                for d in self.door_exceptions
            ]

            # Doors accessible via group membership
            group_doors = set()
            for group in self.groups:
                for door in group.doors:
                    # Only include if the group is not in the door's exception list
                    if group not in door.exception_groups:
                        group_doors.add(door)

            data['group_door_access'] = [
                {'id': d.id, 'name': d.name, 'location': d.location}
                for d in group_doors
            ]

            # Doors that user's groups are denied access to
            group_exception_doors = set()
            for group in self.groups:
                for door in group.exception_doors:
                    group_exception_doors.add(door)

            data['group_door_exceptions'] = [
                {'id': d.id, 'name': d.name, 'location': d.location}
                for d in group_exception_doors
            ]

            # Total counts
            data['device_count'] = self.devices.count()
            data['group_count'] = self.groups.count()
            data['total_door_access_count'] = (
                self.direct_door_access.count() + len(group_doors)
            )

        return data
    
    def __repr__(self):
        return f'<user {self.email}>'