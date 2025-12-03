from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, Door
from app.utils.decorators import admin_required, esp32_auth_required

bp = Blueprint('doors', __name__)


@bp.route('/', methods=['POST'])
@jwt_required()
@admin_required
def create_door():
    """
    Create a new door (admin only)
    """
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    name = data.get('name')
    description = data.get('description')
    location = data.get('location')
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    device_id = data.get('device_id')  # BLE MAC address
    is_active = data.get('is_active', True)

    if not name or latitude is None or longitude is None:
        return jsonify({'error': 'Name, latitude, and longitude are required'}), 400

    # Check if device_id (BLE MAC) already exists
    if device_id and Door.query.filter_by(device_id=device_id).first():
        return jsonify({'error': 'Door with this device ID already exists'}), 409

    # Create new door
    door = Door(
        name=name,
        description=description,
        location=location,
        latitude=latitude,
        longitude=longitude,
        device_id=device_id,
        is_active=is_active
    )

    db.session.add(door)
    db.session.commit()

    return jsonify({
        'message': 'Door created successfully',
        'door': door.to_dict()
    }), 201


@bp.route('/', methods=['GET'])
@jwt_required()
def list_doors():
    """
    List all doors with access status for current user
    Query params:
    - include_inactive: 'true' to include inactive doors (admin only)
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check if user is admin and wants all doors (including inactive)
    include_inactive = request.args.get('include_inactive', 'false').lower() == 'true'

    if include_inactive and user.role == 'admin':
        doors = Door.query.all()  # Return ALL doors for admins
    else:
        doors = Door.query.filter_by(is_active=True).all()  # Only active for regular users

    doors_data = []
    for door in doors:
        door_dict = door.to_dict()

        # Check if user has access
        has_access = user.has_access_to_door(door)
        door_dict['user_has_access'] = has_access

        # Determine access type
        if has_access:
            if door in user.direct_door_access:
                door_dict['access_type'] = 'direct_access'
            else:
                door_dict['access_type'] = 'group_access'
        else:
            door_dict['access_type'] = 'no_access'

        doors_data.append(door_dict)

    return jsonify({
        'doors': doors_data
    }), 200


@bp.route('/accessible', methods=['GET'])
@jwt_required()
def list_accessible_doors():
    """
    List only doors user can access
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    all_doors = Door.query.filter_by(is_active=True).all()
    accessible_doors = [door for door in all_doors if user.has_access_to_door(door)]

    doors_data = []
    for door in accessible_doors:
        door_dict = door.to_dict()

        if door in user.direct_door_access:
            door_dict['access_type'] = 'direct_access'
        else:
            door_dict['access_type'] = 'group_access'

        doors_data.append(door_dict)

    return jsonify({
        'doors': doors_data
    }), 200


@bp.route('/<int:door_id>', methods=['GET'])
@jwt_required()
def get_door(door_id):
    """
    Get door details
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    door_dict = door.to_dict(include_access_info=user.is_admin())

    # Add user access info
    has_access = user.has_access_to_door(door)
    door_dict['user_has_access'] = has_access

    if has_access:
        if door in user.direct_door_access:
            door_dict['access_type'] = 'direct_access'
        else:
            door_dict['access_type'] = 'group_access'
    else:
        door_dict['access_type'] = 'no_access'

    return jsonify({
        'door': door_dict
    }), 200


@bp.route('/<int:door_id>', methods=['PUT'])
@jwt_required()
@admin_required
def update_door(door_id):
    """
    Update door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    data = request.get_json()

    if not data:
        return jsonify({'error': 'Missing request body'}), 400

    # Update fields
    if 'name' in data:
        door.name = data['name']
    if 'description' in data:
        door.description = data['description']
    if 'location' in data:
        door.location = data['location']
    if 'latitude' in data:
        door.latitude = data['latitude']
    if 'longitude' in data:
        door.longitude = data['longitude']
    if 'device_id' in data:
        # Check if new device_id is already taken
        existing = Door.query.filter_by(device_id=data['device_id']).first()
        if existing and existing.id != door.id:
            return jsonify({'error': 'Device ID already in use'}), 409
        door.device_id = data['device_id']
    if 'is_active' in data:
        door.is_active = data['is_active']

    db.session.commit()

    return jsonify({
        'message': 'Door updated successfully',
        'door': door.to_dict(include_access_info=True)
    }), 200


@bp.route('/<int:door_id>', methods=['DELETE'])
@jwt_required()
@admin_required
def delete_door(door_id):
    """
    Delete door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    db.session.delete(door)
    db.session.commit()

    return jsonify({'message': 'Door deleted successfully'}), 200


# ESP32 Endpoints

@bp.route('/check-access', methods=['POST'])
@esp32_auth_required
def check_access():
    """
    Check if user can access door (ESP32 endpoint)
    Validates permissions and distance
    """
    data = request.get_json()

    user_id = data.get('user_id')
    door_id = data.get('door_id')
    distance = data.get('distance')

    if not user_id or not door_id or distance is None:
        return jsonify({'error': 'user_id, door_id, and distance are required'}), 400

    user = User.query.get(user_id)
    door = Door.query.get(door_id)

    if not user:
        return jsonify({
            'allowed': False,
            'reason': 'user_not_found'
        }), 404

    if not door:
        return jsonify({
            'allowed': False,
            'reason': 'door_not_found'
        }), 404

    if not door.is_active:
        return jsonify({
            'allowed': False,
            'reason': 'door_inactive'
        }), 200

    # Check if user has access permission
    has_permission = user.has_access_to_door(door)

    if not has_permission:
        return jsonify({
            'allowed': False,
            'reason': 'no_permission',
            'max_distance': 50,  # Could be door-specific
            'door_latitude': door.latitude,
            'door_longitude': door.longitude
        }), 200

    # Check distance (could add max_distance_meters to Door model)
    max_distance = 50  # meters, hardcoded for now

    if distance > max_distance:
        return jsonify({
            'allowed': False,
            'reason': 'too_far',
            'distance': distance,
            'max_distance': max_distance,
            'door_latitude': door.latitude,
            'door_longitude': door.longitude
        }), 200

    # Access granted
    # Determine access reason
    if door in user.direct_door_access:
        access_reason = 'direct_access'
    else:
        access_reason = 'group_access'

    return jsonify({
        'allowed': True,
        'reason': access_reason,
        'max_distance': max_distance,
        'door_latitude': door.latitude,
        'door_longitude': door.longitude
    }), 200
