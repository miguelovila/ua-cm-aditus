from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app import db
from app.models import User, Door, Device, AccessLog
from app.utils.decorators import admin_required, esp32_auth_required

bp = Blueprint('access_logs', __name__)


@bp.route('/', methods=['GET'])
@jwt_required()
@admin_required
def list_access_logs():
    """
    List all access logs with pagination and filtering (admin only)
    Query params:
    - limit: number of results (default 50, max 500)
    - offset: offset for pagination (default 0)
    - success: filter by success status (true/false)
    - user_id: filter by user
    - door_id: filter by door
    - device_id: filter by device
    - from: filter by start date (ISO format)
    - to: filter by end date (ISO format)
    """
    # Parse query parameters
    limit = min(int(request.args.get('limit', 50)), 500)
    offset = int(request.args.get('offset', 0))
    success_filter = request.args.get('success')
    user_id = request.args.get('user_id')
    door_id = request.args.get('door_id')
    device_id = request.args.get('device_id')
    from_date = request.args.get('from')
    to_date = request.args.get('to')

    # Build query
    query = AccessLog.query

    if success_filter is not None:
        success_bool = success_filter.lower() == 'true'
        query = query.filter_by(success=success_bool)

    if user_id:
        query = query.filter_by(user_id=int(user_id))

    if door_id:
        query = query.filter_by(door_id=int(door_id))

    if device_id:
        query = query.filter_by(device_id=int(device_id))

    if from_date:
        from datetime import datetime
        from_dt = datetime.fromisoformat(from_date.replace('Z', '+00:00'))
        query = query.filter(AccessLog.timestamp >= from_dt)

    if to_date:
        from datetime import datetime
        to_dt = datetime.fromisoformat(to_date.replace('Z', '+00:00'))
        query = query.filter(AccessLog.timestamp <= to_dt)

    # Order by timestamp descending (most recent first)
    query = query.order_by(AccessLog.timestamp.desc())

    # Get total count
    total = query.count()

    # Apply pagination
    logs = query.limit(limit).offset(offset).all()

    return jsonify({
        'logs': [log.to_dict() for log in logs],
        'total': total,
        'limit': limit,
        'offset': offset
    }), 200


@bp.route('/my-logs', methods=['GET'])
@jwt_required()
def get_my_logs():
    """
    Get current user's access logs
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(int(current_user_id))

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Parse pagination
    limit = min(int(request.args.get('limit', 50)), 500)
    offset = int(request.args.get('offset', 0))

    # Get user's logs
    query = AccessLog.query.filter_by(user_id=user.id).order_by(AccessLog.timestamp.desc())

    total = query.count()
    logs = query.limit(limit).offset(offset).all()

    return jsonify({
        'logs': [log.to_dict() for log in logs],
        'total': total,
        'limit': limit,
        'offset': offset
    }), 200


@bp.route('/doors/<int:door_id>', methods=['GET'])
@jwt_required()
@admin_required
def get_door_logs(door_id):
    """
    Get access logs for specific door (admin only)
    """
    door = Door.query.get(door_id)

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    # Parse pagination
    limit = min(int(request.args.get('limit', 50)), 500)
    offset = int(request.args.get('offset', 0))

    query = AccessLog.query.filter_by(door_id=door_id).order_by(AccessLog.timestamp.desc())

    total = query.count()
    logs = query.limit(limit).offset(offset).all()

    return jsonify({
        'door': door.to_dict(),
        'logs': [log.to_dict() for log in logs],
        'total': total,
        'limit': limit,
        'offset': offset
    }), 200


@bp.route('/users/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user_logs(user_id):
    """
    Get access logs for specific user
    Admin or self only
    """
    current_user_id = get_jwt_identity()
    current_user = User.query.get(int(current_user_id))

    user = User.query.get(user_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    # Check permissions
    if not current_user.is_admin() and user.id != current_user.id:
        return jsonify({'error': 'Access denied'}), 403

    # Parse pagination
    limit = min(int(request.args.get('limit', 50)), 500)
    offset = int(request.args.get('offset', 0))

    query = AccessLog.query.filter_by(user_id=user_id).order_by(AccessLog.timestamp.desc())

    total = query.count()
    logs = query.limit(limit).offset(offset).all()

    return jsonify({
        'user': user.to_dict(),
        'logs': [log.to_dict() for log in logs],
        'total': total,
        'limit': limit,
        'offset': offset
    }), 200


@bp.route('/devices/<int:device_id>', methods=['GET'])
@jwt_required()
def get_device_logs(device_id):
    """
    Get access logs for specific device
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

    # Parse pagination
    limit = min(int(request.args.get('limit', 50)), 500)
    offset = int(request.args.get('offset', 0))

    query = AccessLog.query.filter_by(device_id=device_id).order_by(AccessLog.timestamp.desc())

    total = query.count()
    logs = query.limit(limit).offset(offset).all()

    return jsonify({
        'device': device.to_dict(),
        'logs': [log.to_dict() for log in logs],
        'total': total,
        'limit': limit,
        'offset': offset
    }), 200


# ESP32 Endpoint

@bp.route('/', methods=['POST'])
@esp32_auth_required
def create_access_log():
    """
    Create access log entry (ESP32 endpoint)
    """
    data = request.get_json()

    user_id = data.get('user_id')
    door_id = data.get('door_id')
    device_id = data.get('device_id')
    action = data.get('action', 'unlock')
    success = data.get('success')
    failure_reason = data.get('failure_reason')
    device_info = data.get('device_info')
    ip_address = data.get('ip_address')

    if user_id is None or door_id is None or success is None:
        return jsonify({'error': 'user_id, door_id, and success are required'}), 400

    # Validate that referenced entities exist
    user = User.query.get(user_id)
    door = Door.query.get(door_id)

    if not user:
        return jsonify({'error': 'User not found'}), 404

    if not door:
        return jsonify({'error': 'Door not found'}), 404

    if device_id:
        device = Device.query.get(device_id)
        if not device:
            return jsonify({'error': 'Device not found'}), 404

    # Create access log
    log = AccessLog.log_access(
        user_id=user_id,
        door_id=door_id,
        device_id=device_id,
        action=action,
        success=success,
        failure_reason=failure_reason,
        device_info=device_info,
        ip_address=ip_address
    )

    db.session.commit()

    return jsonify({
        'message': 'Access log created successfully',
        'log': log.to_dict()
    }), 201
