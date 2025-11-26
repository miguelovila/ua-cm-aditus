from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, Group
from app.utils.decorators import admin_required

bp = Blueprint('groups', __name__)


@bp.route('/', methods=['POST'])
@jwt_required()
@admin_required
def create_group():
    """
    Create a new group (admin only)
    """
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    name = data.get('name')
    description = data.get('description')

    if not name:
        return jsonify({'error': 'Group name is required'}), 400

    # Check if group already exists
    if Group.query.filter_by(name=name).first():
        return jsonify({'error': 'Group with this name already exists'}), 409

    # Create new group
    group = Group(
        name=name,
        description=description
    )

    db.session.add(group)
    db.session.commit()

    return jsonify({
        'message': 'Group created successfully',
        'group': group.to_dict()
    }), 201


@bp.route('/', methods=['GET'])
@jwt_required()
@admin_required
def list_groups():
    """
    List all groups (admin only)
    """
    groups = Group.query.all()

    return jsonify({
        'groups': [group.to_dict() for group in groups]
    }), 200


@bp.route('/my-groups', methods=['GET'])
@jwt_required()
def get_my_groups():
    """
    List current user's groups
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    groups = user.groups.all()

    return jsonify({
        'groups': [group.to_dict() for group in groups]
    }), 200


@bp.route('/<int:group_id>', methods=['GET'])
@jwt_required()
def get_group(group_id):
    """
    Get group details
    Admin or member can access
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    # Check if user is admin or member
    is_member = group in current_user.groups
    if not current_user.is_admin() and not is_member:
        return jsonify({'error': 'Access denied'}), 403

    include_details = current_user.is_admin()

    return jsonify({
        'group': group.to_dict(include_members=include_details, include_doors=include_details)
    }), 200


@bp.route('/<int:group_id>', methods=['PUT'])
@jwt_required()
@admin_required
def update_group(group_id):
    """
    Update group (admin only)
    """
    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    # Update fields
    if 'name' in data:
        # Check if new name is already taken
        existing = Group.query.filter_by(name=data['name']).first()
        if existing and existing.id != group.id:
            return jsonify({'error': 'Group name already in use'}), 409
        group.name = data['name']

    if 'description' in data:
        group.description = data['description']

    db.session.commit()

    return jsonify({
        'message': 'Group updated successfully',
        'group': group.to_dict(include_members=True, include_doors=True)
    }), 200


@bp.route('/<int:group_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def delete_group(group_id):
    """
    Delete group (admin only)
    """
    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    db.session.delete(group)
    db.session.commit()

    return jsonify({'message': 'Group deleted successfully'}), 200


@bp.route('/<int:group_id>/members', methods=['POST'])
@jwt_required()
@admin_required
def add_members(group_id):
    """
    Add members to group (admin only)
    """
    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    user_ids = data.get('user_ids', [])

    if not user_ids:
        return jsonify({'error': 'user_ids array is required'}), 400

    added_users = []
    for user_id in user_ids:
        user = User.query.get(user_id)

        if not user:
            continue

        # Check if user is already a member
        if user not in group.members:
            group.members.append(user)
            added_users.append(user.to_dict())

    db.session.commit()

    return jsonify({
        'message': f'Added {len(added_users)} members to group',
        'added_users': added_users,
        'group': group.to_dict(include_members=True)
    }), 200


@bp.route('/<int:group_id>/members/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def remove_member(group_id, user_id):
    """
    Remove member from group (admin only)
    """
    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if user is a member
    if user in group.members:
        group.members.remove(user)
        db.session.commit()

        return jsonify({
            'message': 'User removed from group successfully',
            'group': group.to_dict(include_members=True)
        }), 200
    else:
        return jsonify({'error': 'User is not a member of this group'}), 404
