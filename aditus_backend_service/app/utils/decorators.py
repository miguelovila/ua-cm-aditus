from functools import wraps
from flask import jsonify, request, current_app
from flask_jwt_extended import get_jwt_identity
from app.models import User


def admin_required(fn):
    """
    Decorator to require admin role for a route
    Must be used after @jwt_required()
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        current_user_id = get_jwt_identity()
        user = User.query.get(int(current_user_id))

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if not user.is_admin():
            return jsonify({'error': 'Admin access required'}), 403

        return fn(*args, **kwargs)

    return wrapper


def esp32_auth_required(fn):
    """
    Decorator to authenticate ESP32 requests using simple API key
    API key should be in request body
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        data = request.get_json()

        if not data:
            return jsonify({'error': 'Missing request body'}), 400

        api_key = data.get('api_key')

        if not api_key:
            return jsonify({'error': 'Missing api_key in request body'}), 401

        if api_key != current_app.config['ESP32_API_KEY']:
            return jsonify({'error': 'Invalid API key'}), 403

        return fn(*args, **kwargs)

    return wrapper