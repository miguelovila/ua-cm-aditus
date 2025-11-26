from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app import db
from app.models import User, Door, Group
from app.utils.decorators import admin_required

bp = Blueprint('access_control', __name__)


@bp.route('/<int:door_id>/access', methods=['GET'])
@jwt_required()
@admin_required
def get_access_rules(door_id):
    """
    Get all access rules for a door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    return jsonify({
        'door_id': door.id,
        'door_name': door.name,
        'allowed_groups': [{'id': g.id, 'name': g.name} for g in door.groups],
        'allowed_users': [{'id': u.id, 'email': u.email} for u in door.direct_users],
        'exception_groups': [{'id': g.id, 'name': g.name} for g in door.exception_groups],
        'exception_users': [{'id': u.id, 'email': u.email} for u in door.exception_users]
    }), 200


# Grant Access - Users

@bp.route('/<int:door_id>/access/users', methods=['POST'])
@jwt_required()
@admin_required
def grant_user_access(door_id):
    """
    Grant direct user access to door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if already has access
    if user in door.direct_users:
        return jsonify({'error': 'User already has direct access to this door'}), 409

    # Add access
    door.direct_users.append(user)
    db.session.commit()

    return jsonify({
        'message': 'User access granted successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


@bp.route('/<int:door_id>/access/users/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def revoke_user_access(door_id, user_id):
    """
    Revoke direct user access from door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if user has access
    if user not in door.direct_users:
        return jsonify({'error': 'User does not have direct access to this door'}), 404

    # Remove access
    door.direct_users.remove(user)
    db.session.commit()

    return jsonify({
        'message': 'User access revoked successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


# Grant Access - Groups

@bp.route('/<int:door_id>/access/groups', methods=['POST'])
@jwt_required()
@admin_required
def grant_group_access(door_id):
    """
    Grant group access to door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    group_id = data.get('group_id')

    if not group_id:
        return jsonify({'error': 'group_id is required'}), 400

    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    # Check if already has access
    if group in door.groups:
        return jsonify({'error': 'Group already has access to this door'}), 409

    # Add access
    door.groups.append(group)
    db.session.commit()

    return jsonify({
        'message': 'Group access granted successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


@bp.route('/<int:door_id>/access/groups/<int:group_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def revoke_group_access(door_id, group_id):
    """
    Revoke group access from door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    # Check if group has access
    if group not in door.groups:
        return jsonify({'error': 'Group does not have access to this door'}), 404

    # Remove access
    door.groups.remove(group)
    db.session.commit()

    return jsonify({
        'message': 'Group access revoked successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


# Exceptions - Users

@bp.route('/<int:door_id>/access/exceptions/users', methods=['POST'])
@jwt_required()
@admin_required
def add_user_exception(door_id):
    """
    Blacklist user from door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    user_id = data.get('user_id')

    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if already in exceptions
    if user in door.exception_users:
        return jsonify({'error': 'User is already blacklisted from this door'}), 409

    # Add exception
    door.exception_users.append(user)
    db.session.commit()

    return jsonify({
        'message': 'User blacklisted successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


@bp.route('/<int:door_id>/access/exceptions/users/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def remove_user_exception(door_id, user_id):
    """
    Remove user from blacklist (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if user is in exceptions
    if user not in door.exception_users:
        return jsonify({'error': 'User is not blacklisted from this door'}), 404

    # Remove exception
    door.exception_users.remove(user)
    db.session.commit()

    return jsonify({
        'message': 'User removed from blacklist successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


# Exceptions - Groups

@bp.route('/<int:door_id>/access/exceptions/groups', methods=['POST'])
@jwt_required()
@admin_required
def add_group_exception(door_id):
    """
    Blacklist group from door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    group_id = data.get('group_id')

    if not group_id:
        return jsonify({'error': 'group_id is required'}), 400

    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    # Check if already in exceptions
    if group in door.exception_groups:
        return jsonify({'error': 'Group is already blacklisted from this door'}), 409

    # Add exception
    door.exception_groups.append(group)
    db.session.commit()

    return jsonify({
        'message': 'Group blacklisted successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


@bp.route('/<int:door_id>/access/exceptions/groups/<int:group_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def remove_group_exception(door_id, group_id):
    """
    Remove group from blacklist (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    group = Group.query.get(group_id)

    if not group:
        return jsonify({'error': 'Group not found'}), 404

    # Check if group is in exceptions
    if group not in door.exception_groups:
        return jsonify({'error': 'Group is not blacklisted from this door'}), 404

    # Remove exception
    door.exception_groups.remove(group)
    db.session.commit()

    return jsonify({
        'message': 'Group removed from blacklist successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200
