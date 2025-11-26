# Aditus Backend Service

A Flask-based REST API backend for the Aditus smart door access control system. This service manages users, devices, doors, groups, and access permissions with asymmetric cryptography-based authentication.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [System Flows](#system-flows)
  - [Authentication Flow](#authentication-flow)
  - [Device Registration Flow](#device-registration-flow)
  - [Door Unlock Flow](#door-unlock-flow)
- [API Documentation](#api-documentation)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)

---

## Architecture Overview

### Components

1. **Mobile App (User Device)**:
   - Android application (Flutter)
   - Communicates with backend via HTTP/REST (JWT authentication)
   - Communicates with ESP32 doors via BLE
   - Stores private key locally, sends public key to backend

2. **ESP32 Door Controller**:
   - Embedded device on physical doors
   - Advertises via BLE for discovery
   - Communicates with backend via HTTP (API key authentication)
   - Performs cryptographic challenge-response verification

3. **Backend Service** (this repository):
   - Flask REST API
   - SQLite database
   - Manages users, devices, doors, groups, permissions
   - Stores device public keys for verification

### Security Model

- **Mobile App Authentication**: JWT tokens (access + refresh)
- **ESP32 Authentication**: Simple API key in request body
- **Door Access Verification**: Asymmetric cryptography (RSA-2048)
  - **Private key**: Stored securely on mobile device (never transmitted)
  - **Public key**: Stored in backend, fetched by ESP32 for signature verification

---

## Technology Stack

- **Framework**: Flask 3.1.2
- **Database**: SQLAlchemy (SQLite/PostgreSQL)
- **Authentication**: Flask-JWT-Extended
- **Password Hashing**: Werkzeug Security
- **CORS**: Flask-CORS
- **Communication Protocols**:
  - HTTP/REST (Mobile ↔ Backend, ESP32 ↔ Backend)
  - BLE (Mobile ↔ ESP32)

---

## System Flows

### Authentication Flow

```
┌─────────────┐                                    ┌─────────────┐
│ Mobile App  │                                    │   Backend   │
└──────┬──────┘                                    └──────┬──────┘
       │                                                  │
       │  POST /api/auth/login                            │
       │  { email, password }                             │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │  { access_token, refresh_token, user }           │
       │<─────────────────────────────────────────────────┤
       │                                                  │
       │  Store tokens locally                            │
       │                                                  │
       │  (Token expires after 3 days)                    │
       │                                                  │
       │  POST /api/auth/refresh                          │
       │  Header: Bearer <refresh_token>                  │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │  { access_token }                                │
       │<─────────────────────────────────────────────────┤
       │                                                  │
```

**Technologies**: HTTP/REST, JWT, Werkzeug password hashing

---

### Device Registration Flow

**Triggered on**: First login from a new smartphone

```
┌─────────────┐                                    ┌─────────────┐
│ Mobile App  │                                    │   Backend   │
└──────┬──────┘                                    └──────┬──────┘
       │                                                  │
       │  1. User logs in successfully                    │
       │  2. App checks: "Do I have a device registered?" │
       │                                                  │
       │  3. Generate RSA-2048 keypair                    │
       │     - Private key → Keychain (iOS) / KeyStore    │
       │     - Public key → Send to backend               │
       │                                                  │
       │  POST /api/devices                               │
       │  Header: Bearer <access_token>                   │
       │  {                                               │
       │    "name": "Miguel's iPhone 15",                 │
       │    "public_key": "-----BEGIN PUBLIC KEY-----..." │
       │  }                                               │
       ├─────────────────────────────────────────────────>│
       │                                                  │
       │                                       Store public key
       │                                       in database
       │                                                  │
       │  { device_id, message }                          │
       │<─────────────────────────────────────────────────┤
       │                                                  │
       │  4. Store device_id locally                      │
       │                                                  │
```

**Technologies**: RSA-2048 asymmetric encryption, Keychain/KeyStore, HTTP/REST

**Key Point**: Private key NEVER leaves the mobile device.

---

### Door Unlock Flow

**Full end-to-end process**:

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Mobile App  │         │ ESP32 Door  │         │   Backend   │
└──────┬──────┘         └──────┬──────┘         └───────┬─────┘
       │                       │                        │
       │ 1. GET /api/doors     │                        │
       │   (Fetch all doors)   │                        │
       ├───────────────────────────────────────────────>│
       │                       │                        │
       │ { doors: [{id, name, device_id (BLE MAC), ...}]}
       │<───────────────────────────────────────────────┤
       │                       │                        │
       │ 2. BLE Scan           │                        │
       ├──────────────────────>│                        │
       │                       │                        │
       │ BLE Advertisements    │                        │
       │<──────────────────────┤                        │
       │                       │                        │
       │ 3. Filter BLE devices │                        │
       │    against door list  │                        │
       │    Sort by RSSI       │                        │
       │                       │                        │
       │ 4. User taps door     │                        │
       │    Calculate GPS      │                        │
       │    distance           │                        │
       │                       │                        │
       │ 5. BLE: Unlock Request│                        │
       │    {user_id, device_id, distance}              │
       ├──────────────────────>│                        │
       │                       │                        │
       │                       │ 6. POST /api/doors/check-access
       │                       │    {user_id, door_id, distance, api_key}
       │                       ├───────────────────────>│
       │                       │                        │
       │                       │          Check:        │
       │                       │          - User permissions
       │                       │          - Distance ≤ max
       │                       │          - Door active │
       │                       │                        │
       │                       │ { allowed: true/false, reason }
       │                       │<───────────────────────┤
       │                       │                        │
       │                       │ 7. If denied: stop     │
       │                       │    If allowed: continue│
       │                       │                        │
       │                       │ 8. Generate random     │
       │                       │    challenge (bytes)   │
       │                       │                        │
       │ BLE: Challenge        │                        │
       │<──────────────────────┤                        │
       │                       │                        │
       │ 9. Sign challenge     │                        │
       │    with PRIVATE KEY   │                        │
       │                       │                        │
       │ BLE: Signed Challenge │                        │
       ├──────────────────────>│                        │
       │                       │                        │
       │                       │ 10. POST /api/devices/{id}/public-key
       │                       │     { api_key }        │
       │                       ├───────────────────────>│
       │                       │                        │
       │                       │ { public_key }         │
       │                       │<───────────────────────┤
       │                       │                        │
       │                       │ 11. Verify signature   │
       │                       │     with PUBLIC KEY    │
       │                       │                        │
       │                       │ 12. If valid: UNLOCK   │
       │                       │     If invalid: DENY   │
       │                       │                        │
       │ BLE: Success/Failure  │                        │
       │<──────────────────────┤                        │
       │                       │                        │
       │                       │ 13. POST /api/access-logs
       │                       │     { user_id, door_id, device_id,
       │                       │       action, success, distance,
       │                       │       failure_reason, api_key }
       │                       ├───────────────────────>│
       │                       │                        │
       │                       │                   Store log
       │                       │                        │
       │                       │ { message }            │
       │                       │<───────────────────────┤
       │                       │                        │
```

**Technologies**:
- **HTTP/REST**: Mobile ↔ Backend, ESP32 ↔ Backend
- **BLE**: Mobile ↔ ESP32 (device discovery, challenge-response)
- **GPS**: Mobile calculates distance to door
- **RSA Signature Verification**: ESP32 verifies user identity

**Access Control Priority**:
1. **Exceptions** (highest) - If user or user's group is blacklisted → DENY
2. **Direct Access** - If user has explicit access → ALLOW
3. **Group Access** - If user's group has access (and not blacklisted) → ALLOW
4. **Default** - DENY

---

## API Documentation

### Legend

| Symbol | Meaning |
|--------|---------|
| 🔓 | Public (no auth) |
| 🔑 | JWT Required |
| 👑 | Admin Only |
| 🔧 | ESP32 API Key Required |

---

### Authentication (`/api/auth`)

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/login` | 🔓 | Login and receive JWT tokens | `{ email, password }` |
| POST | `/refresh` | 🔑 (refresh token) | Refresh access token | - |
| POST | `/logout` | 🔑 | Logout (client deletes token) | - |

**Response Example** (`/login`):
```json
{
  "message": "Login successful",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "user",
    "created_at": "2025-01-26T10:00:00"
  }
}
```

---

### Users (`/api/users`)

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/` | 🔑👑 | Create user (admin creates accounts) | `{ email, password, full_name?, role? }` |
| GET | `/` | 🔑👑 | List all users | - |
| GET | `/me` | 🔑 | Get current user (with sensitive info) | - |
| GET | `/:id` | 🔑 | Get user by ID (admin or self) | - |
| PUT | `/me` | 🔑 | Update own profile | `{ full_name?, email? }` |
| PUT | `/:id` | 🔑👑 | Update user | `{ full_name?, email?, role? }` |
| DELETE | `/:id` | 🔑👑 | Delete user | - |
| PUT | `/me/password` | 🔑 | Change own password | `{ current_password, new_password }` |

**Note**: User registration is admin-only. Regular users cannot self-register.

**Sensitive User Info** (`GET /me`):
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe",
    "role": "user",
    "groups": [{ "id": 1, "name": "Students" }],
    "devices": [{ "id": 1, "name": "iPhone 15", "public_key": "..." }],
    "direct_door_access": [{ "id": 1, "name": "Lab A", "location": "..." }],
    "group_door_access": [{ "id": 2, "name": "Main Entrance", "location": "..." }],
    "door_exceptions": [{ "id": 3, "name": "Server Room", "location": "..." }],
    "group_door_exceptions": [],
    "device_count": 2,
    "group_count": 1,
    "total_door_access_count": 5
  }
}
```

---

### Devices (`/api/devices`)

#### Mobile App Endpoints

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/` | 🔑 | Register device with public key | `{ name, public_key }` |
| GET | `/my-devices` | 🔑 | List current user's devices | - |
| GET | `/:id` | 🔑 | Get device details (admin or owner) | - |
| PUT | `/:id` | 🔑 | Update device name (admin or owner) | `{ name }` |
| DELETE | `/:id` | 🔑 | Delete/revoke device (admin or owner) | - |

#### ESP32 Endpoints

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/:id/public-key` | 🔧 | Get device public key for verification | `{ api_key }` |

**Device Registration Example**:
```json
{
  "name": "Miguel's iPhone 15",
  "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA..."
}
```

**Public Key Response** (ESP32):
```json
{
  "device_id": 123,
  "user_id": 456,
  "public_key": "-----BEGIN PUBLIC KEY-----\nMIIBIjAN...",
  "is_active": true
}
```

---

### Doors (`/api/doors`)

#### Mobile App Endpoints

| Method | Endpoint | Auth | Description | Query Params |
|--------|----------|------|-------------|--------------|
| GET | `/` | 🔑 | List all doors with user access status | - |
| GET | `/accessible` | 🔑 | List only doors user can access | - |
| GET | `/:id` | 🔑 | Get door details | - |

#### Admin Endpoints

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/` | 🔑👑 | Create door | `{ name, latitude, longitude, description?, location?, device_id?, is_active? }` |
| PUT | `/:id` | 🔑👑 | Update door | `{ name?, latitude?, longitude?, description?, location?, device_id?, is_active? }` |
| DELETE | `/:id` | 🔑👑 | Delete door | - |

#### ESP32 Endpoints

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/check-access` | 🔧 | Check if user can access door | `{ user_id, door_id, distance, api_key }` |

**Door List Response** (Mobile):
```json
{
  "doors": [
    {
      "id": 1,
      "name": "Main Lab Entrance",
      "location": "Building A, Floor 2",
      "latitude": 40.631467,
      "longitude": -8.659510,
      "device_id": "AA:BB:CC:DD:EE:FF",
      "is_active": true,
      "user_has_access": true,
      "access_type": "group_access"
    }
  ]
}
```

**Check Access Response** (ESP32):
```json
{
  "allowed": true,
  "reason": "group_access",
  "max_distance": 50,
  "door_latitude": 40.631467,
  "door_longitude": -8.659510
}
```

**Failure reasons**:
- `user_not_found`
- `door_not_found`
- `door_inactive`
- `no_permission`
- `too_far`

---

### Groups (`/api/groups`)

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/` | 🔑👑 | Create group | `{ name, description? }` |
| GET | `/` | 🔑👑 | List all groups | - |
| GET | `/my-groups` | 🔑 | List current user's groups | - |
| GET | `/:id` | 🔑 | Get group details (admin or member) | - |
| PUT | `/:id` | 🔑👑 | Update group | `{ name?, description? }` |
| DELETE | `/:id` | 🔑👑 | Delete group | - |
| POST | `/:id/members` | 🔑👑 | Add members to group | `{ user_ids: [1, 2, 3] }` |
| DELETE | `/:id/members/:user_id` | 🔑👑 | Remove member from group | - |

---

### Access Control (`/api/doors/:door_id/access`)

**All endpoints are admin-only (🔑👑)**

#### Get Access Rules

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Get all access rules for door |

#### Grant Access

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/users` | Grant direct user access | `{ user_id }` |
| POST | `/groups` | Grant group access | `{ group_id }` |

#### Revoke Access

| Method | Endpoint | Description |
|--------|----------|-------------|
| DELETE | `/users/:user_id` | Revoke direct user access |
| DELETE | `/groups/:group_id` | Revoke group access |

#### Exceptions (Blacklist)

| Method | Endpoint | Description | Request Body |
|--------|----------|-------------|--------------|
| POST | `/exceptions/users` | Blacklist user from door | `{ user_id }` |
| DELETE | `/exceptions/users/:user_id` | Remove user from blacklist | - |
| POST | `/exceptions/groups` | Blacklist group from door | `{ group_id }` |
| DELETE | `/exceptions/groups/:group_id` | Remove group from blacklist | - |

**Access Rules Response**:
```json
{
  "door_id": 1,
  "door_name": "Main Lab",
  "allowed_groups": [{ "id": 1, "name": "Students" }],
  "allowed_users": [{ "id": 5, "email": "guest@example.com" }],
  "exception_groups": [],
  "exception_users": [{ "id": 10, "email": "banned@example.com" }]
}
```

---

### Access Logs (`/api/access-logs`)

#### User Endpoints

| Method | Endpoint | Auth | Description | Query Params |
|--------|----------|------|-------------|--------------|
| GET | `/my-logs` | 🔑 | Get current user's access logs | `limit?, offset?` |

#### Admin Endpoints

| Method | Endpoint | Auth | Description | Query Params |
|--------|----------|------|-------------|--------------|
| GET | `/` | 🔑👑 | List all logs (paginated, filterable) | `limit?, offset?, success?, user_id?, door_id?, device_id?, from?, to?` |
| GET | `/doors/:door_id` | 🔑👑 | Logs for specific door | `limit?, offset?` |
| GET | `/users/:user_id` | 🔑 | Logs for specific user (admin or self) | `limit?, offset?` |
| GET | `/devices/:device_id` | 🔑 | Logs for specific device (admin or owner) | `limit?, offset?` |

#### ESP32 Endpoints

| Method | Endpoint | Auth | Description | Request Body |
|--------|----------|------|-------------|--------------|
| POST | `/` | 🔧 | Create access log entry | `{ user_id, door_id, device_id?, action, success, failure_reason?, distance_from_door?, user_latitude?, user_longitude?, device_info?, ip_address?, api_key }` |

**Access Log Example**:
```json
{
  "id": 1,
  "action": "unlock",
  "success": true,
  "failure_reason": null,
  "user_latitude": 40.631467,
  "user_longitude": -8.659510,
  "distance_from_door": 2.5,
  "timestamp": "2025-01-26T14:30:00",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe"
  },
  "door": {
    "id": 1,
    "name": "Main Lab",
    "location": "Building A"
  },
  "device": {
    "id": 1,
    "name": "iPhone 15",
    "owner_id": 1
  }
}
```

**Query Filtering Example**:
```
GET /api/access-logs?success=false&from=2025-01-01&to=2025-01-31&limit=100
```

---

## Setup Instructions

### Prerequisites

- Python 3.9+
- pip
- Virtual environment (recommended)

### Installation

1. **Clone the repository**:
   ```bash
   cd aditus_backend_service
   ```

2. **Create virtual environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Create `.env` file**:
   ```bash
   cp .env.example .env  # Or create manually
   ```

5. **Configure environment variables** (see [Configuration](#configuration))

6. **Run the application**:
   ```bash
   python run.py
   ```

The API will be available at `http://localhost:5000`

### Database Initialization

On first run, the application will:
- Create all database tables
- Create a default admin user (credentials from `.env` or defaults)

**Default Admin Credentials**:
- Email: `admin@aditus.local`
- Password: `admin123`

---

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Flask Configuration
FLASK_ENV=development  # development | production | testing
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
SECRET_KEY=your-secret-key-change-in-production

# Database
DATABASE_URL=sqlite:///aditus.db  # Or PostgreSQL: postgresql://user:pass@host/db

# JWT Configuration
JWT_SECRET_KEY=your-jwt-secret-key-change-in-production
# JWT_ACCESS_TOKEN_EXPIRES=259200  # 3 days (default)
# JWT_REFRESH_TOKEN_EXPIRES=2592000  # 30 days (default)

# CORS
CORS_ORIGINS=*  # Comma-separated list: http://localhost:3000,https://app.example.com

# ESP32 API Key
ESP32_API_KEY=your-esp32-api-key-change-in-production

# Admin User (created on first run)
ADMIN_EMAIL=admin@aditus.local
ADMIN_PASSWORD=admin123
ADMIN_FIRST_NAME=Admin
ADMIN_LAST_NAME=User
```

### Production Deployment

For production:

1. Set `FLASK_ENV=production`
2. Use PostgreSQL instead of SQLite
3. Set strong `SECRET_KEY` and `JWT_SECRET_KEY`
4. Set secure `ESP32_API_KEY`
5. Configure proper `CORS_ORIGINS`
6. Change default admin password
7. Use a production WSGI server (Gunicorn, uWSGI)
8. Enable HTTPS
9. Consider adding rate limiting

**Example with Gunicorn**:
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 "app:create_app()"
```

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error message description"
}
```

**Common HTTP Status Codes**:
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Missing or invalid JWT/API key
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `500 Internal Server Error` - Server error

---

## Health Check

```
GET /health
```

Returns:
```json
{
  "status": "healthy",
  "service": "Aditus Backend"
}
```
