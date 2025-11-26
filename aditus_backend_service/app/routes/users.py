from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User
from app.utils.decorators import admin_required

bp = Blueprint('users', __name__)


@bp.route('/', methods=['POST'])
@jwt_required()
@admin_required
def create_user():
    """
    Create a new user (admin only)
    """
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    role = data.get('role', 'user')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    # Check if user already exists
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'User with this email already exists'}), 409

    # Create new user
    user = User(
        email=email,
        full_name=full_name,
        role=role
    )
    user.set_password(password)

    db.session.add(user)
    db.session.commit()

    return jsonify({
        'message': 'User created successfully',
        'user': user.to_dict()
    }), 201


@bp.route('/', methods=['GET'])
@jwt_required()
@admin_required
def list_users():
    """
    List all users (admin only)
    """
    users = User.query.all()
    return jsonify({
        'users': [user.to_dict() for user in users]
    }), 200


@bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """
    Get current user's information
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify({
        'user': user.to_dict(include_sensitive=True)
    }), 200


@bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    """
    Get user by ID
    Admin can see any user, regular users can only see themselves
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check permissions
    if not current_user.is_admin() and user.id != current_user.id:
        return jsonify({'error': 'Access denied'}), 403

    include_sensitive = current_user.is_admin() or user.id == current_user.id

    return jsonify({
        'user': user.to_dict(include_sensitive=include_sensitive)
    }), 200


@bp.route('/me', methods=['PUT'])
@jwt_required()
def update_current_user():
    """
    Update current user's profile
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    # Update allowed fields
    if 'full_name' in data:
        user.full_name = data['full_name']
    if 'email' in data:
        # Check if email is already taken
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user and existing_user.id != user.id:
            return jsonify({'error': 'Email already in use'}), 409
        user.email = data['email']

    db.session.commit()

    return jsonify({
        'message': 'Profile updated successfully',
        'user': user.to_dict(include_sensitive=True)
    }), 200


@bp.route('/<int:user_id>', methods=['PUT'])
@jwt_required()
@admin_required
def update_user(user_id):
    """
    Update user (admin only)
    """
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    # Update fields
    if 'full_name' in data:
        user.full_name = data['full_name']
    if 'email' in data:
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user and existing_user.id != user.id:
            return jsonify({'error': 'Email already in use'}), 409
        user.email = data['email']
    if 'role' in data:
        user.role = data['role']

    db.session.commit()

    return jsonify({
        'message': 'User updated successfully',
        'user': user.to_dict(include_sensitive=True)
    }), 200


@bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def delete_user(user_id):
    """
    Delete user (admin only)
    """
    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    db.session.delete(user)
    db.session.commit()

    return jsonify({'message': 'User deleted successfully'}), 200


@bp.route('/me/password', methods=['PUT'])
@jwt_required()
def change_password():
    """
    Change current user's password
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    current_password = data.get('current_password')
    new_password = data.get('new_password')

    if not current_password or not new_password:
        return jsonify({'error': 'Current password and new password are required'}), 400

    # Verify current password
    if not user.check_password(current_password):
        return jsonify({'error': 'Current password is incorrect'}), 401

    # Set new password
    user.set_password(new_password)
    db.session.commit()

    return jsonify({'message': 'Password changed successfully'}), 200
