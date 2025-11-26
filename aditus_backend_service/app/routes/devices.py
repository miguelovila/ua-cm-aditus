from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, Device
from app.utils.decorators import admin_required, esp32_auth_required

bp = Blueprint('devices', __name__)


@bp.route('/', methods=['POST'])
@jwt_required()
def register_device():
    """
    Register a new device (smartphone) with public key
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    name = data.get('name')
    public_key = data.get('public_key')

    if not name or not public_key:
        return jsonify({'error': 'Device name and public key are required'}), 400

    # Check if public key already exists
    if Device.query.filter_by(public_key=public_key).first():
        return jsonify({'error': 'Device with this public key already registered'}), 409

    # Create new device
    device = Device(
        owner_id=user.id,
        name=name,
        public_key=public_key
    )

    db.session.add(device)
    db.session.commit()

    return jsonify({
        'message': 'Device registered successfully',
        'device': device.to_dict()
    }), 201


@bp.route('/my-devices', methods=['GET'])
@jwt_required()
def get_my_devices():
    """
    List current user's devices
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    devices = user.devices.all()

    return jsonify({
        'devices': [device.to_dict() for device in devices]
    }), 200


@bp.route('/<int:device_id>', methods=['GET'])
@jwt_required()
def get_device(device_id):
    """
    Get device details
    Admin or owner only
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    device = Device.query.get(device_id)

    if not device:
        return jsonify({'error': 'Device not found'}), 404

    # Check permissions
    if not current_user.is_admin() and device.owner_id != current_user.id:
        return jsonify({'error': 'Access denied'}), 403

    return jsonify({
        'device': device.to_dict(include_owner=True)
    }), 200


@bp.route('/<int:device_id>', methods=['PUT'])
@jwt_required()
def update_device(device_id):
    """
    Update device (name only)
    Owner or admin only
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    device = Device.query.get(device_id)

    if not device:
        return jsonify({'error': 'Device not found'}), 404

    # Check permissions
    if not current_user.is_admin() and device.owner_id != current_user.id:
        return jsonify({'error': 'Access denied'}), 403

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    # Update device name
    if 'name' in data:
        device.name = data['name']

    db.session.commit()

    return jsonify({
        'message': 'Device updated successfully',
        'device': device.to_dict()
    }), 200


@bp.route('/<int:device_id>', methods=['DELETE'])
@jwt_required()
def delete_device(device_id):
    """
    Delete/revoke device
    Owner or admin only
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    device = Device.query.get(device_id)

    if not device:
        return jsonify({'error': 'Device not found'}), 404

    # Check permissions
    if not current_user.is_admin() and device.owner_id != current_user.id:
        return jsonify({'error': 'Access denied'}), 403

    db.session.delete(device)
    db.session.commit()

    return jsonify({'message': 'Device deleted successfully'}), 200


# ESP32 Endpoints

@bp.route('/<int:device_id>/public-key', methods=['POST'])
@esp32_auth_required
def get_device_public_key(device_id):
    """
    Get device public key for ESP32 verification
    ESP32 only (API key required)
    """
    device = Device.query.get(device_id)

    if not device:
        return jsonify({'error': 'Device not found'}), 404

    return jsonify({
        'device_id': device.id,
        'user_id': device.owner_id,
        'public_key': device.public_key,
        'is_active': True  # Could add is_active field to Device model later
    }), 200
