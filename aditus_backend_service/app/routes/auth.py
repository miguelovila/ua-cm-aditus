from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
    get_jwt
)
from app import db
from app.models import User

bp = Blueprint('auth', __name__)


@bp.route('/login', methods=['POST'])
def login():
    """
    Login endpoint
    Returns JWT access and refresh tokens
    """
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    # Find user by email
    user = User.query.filter_by(email=email).first()

    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid email or password'}), 401

    # Create tokens
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        'message': 'Login successful',
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.to_dict()
    }), 200


@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """
    Refresh access token using refresh token
    """
    current_user_id = get_jwt_identity()
    new_access_token = create_access_token(identity=current_user_id)

    return jsonify({
        'access_token': new_access_token
    }), 200


@bp.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    """
    Logout endpoint
    In a production app, you'd want to blacklist the token
    For now, client should just delete the token
    """
    return jsonify({'message': 'Logout successful'}), 200
