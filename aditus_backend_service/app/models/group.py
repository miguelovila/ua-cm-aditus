from datetime import datetime
from app import db
from app.models.user import user_groups

# Association table for group-door access
group_door_access = db.Table('group_door_access',
    db.Column('group_id', db.Integer, db.ForeignKey('groups.id'), primary_key=True),
    db.Column('door_id', db.Integer, db.ForeignKey('doors.id'), primary_key=True),
    db.Column('granted_at', db.DateTime, default=datetime.now, nullable=False)
)

# Association table for group-door exceptions (deny access)
group_door_exceptions = db.Table('group_door_exceptions',
    db.Column('group_id', db.Integer, db.ForeignKey('groups.id'), primary_key=True),
    db.Column('door_id', db.Integer, db.ForeignKey('doors.id'), primary_key=True),
    db.Column('denied_at', db.DateTime, default=datetime.now, nullable=False)
)

class Group(db.Model):
    __tablename__ = 'groups'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), unique=True, nullable=False)
    description = db.Column(db.String(512))
    created_at = db.Column(db.DateTime, default=datetime.now, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.now, onupdate=datetime.now, nullable=False)

    # Relationships
    members = db.relationship('User', secondary=user_groups, back_populates='groups', lazy='dynamic')
    doors = db.relationship(
        'Door',
        secondary=group_door_access,
        back_populates='groups',
        lazy='dynamic'
    )
    exception_doors = db.relationship(
        'Door',
        secondary=group_door_exceptions,
        back_populates='exception_groups',
        lazy='dynamic'
    )

    def to_dict(self, include_members=False, include_doors=False):
        """Convert group to dictionary"""
        data = {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'member_count': self.members.count(),
            'door_count': self.doors.count()
        }

        if include_members:
            data['members'] = [member.to_dict() for member in self.members]

        if include_doors:
            data['doors'] = [
                {'id': d.id, 'name': d.name, 'location': d.location}
                for d in self.doors
            ]

        return data
    
    def __repr__(self):
        return f'<group {self.name}>'