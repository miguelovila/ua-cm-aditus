# Aditus - Secure Access Control System

![Video Demo](screenshots/smartwatch_unlock_flow-ezgif.com-optimize.gif)

Aditus is an access control system designed to manage and authenticate access to rooms using smartphones and smartwatches. The system has a multi-component architecture, including a backend service, a mobile client application, a smartwatch client application, and a door controller based on the ESP32 microcontroller.

## Table of Contents

- [Aditus - Secure Access Control System](#aditus---secure-access-control-system)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Technologies Used](#technologies-used)
  - [System Architecture and Flow](#system-architecture-and-flow)
  - [Getting Started](#getting-started)
    - [Backend Service](#backend-service)
    - [Smartphone/Smartwatch Apps](#smartphonesmartwatch-apps)
    - [ESP32 Door Controller](#esp32-door-controller)
  - [Screenshots](#screenshots)
    - [Authentication](#authentication)
    - [Device Registration](#device-registration)
    - [Door Discovery, Access and Management](#door-discovery-access-and-management)
    - [Account \& Settings](#account--settings)
    - [Admin Features](#admin-features)
    - [Smartwatch App](#smartwatch-app)

## Overview

The project provides a modern solution for access control, replacing traditional keys and access cards with personal mobile devices. The system is built with security as a primary focus, utilizing cryptographic signatures to verify user identity and authorize access.

The project consists of four main components:

1.  **Backend Service (`aditus_backend_service`)**: A central server application that manages users, devices, doors, access permissions, and logs all access attempts.
2.  **Smartphone Client (`smartphone_client_app`)**: A Flutter-based mobile application that allows users to register, manage their accounts, and unlock doors.
3.  **Smartwatch Client (`smartwatch_client_app`)**: A companion Flutter application for smartwatches, offering the convenience of unlocking doors from the wrist.
4.  **Door Controller (`esp32_door_controller`)**: An ESP32-based device attached to a door lock, which communicates with the client apps via Bluetooth Low Energy (BLE) and the backend via Wi-Fi.

## Features

- **Secure Cryptographic Authentication**: Access is granted based on a challenge-response mechanism using public-key cryptography (RSA signatures).
- **Centralized Access Management**: Administrators can manage users, groups, doors, and access rules through the backend service.
- **Mobile and Wearable Access**: Users can unlock doors using either their smartphone or smartwatch.
- **Real-time Access Logging**: All access attempts (successful or failed) are logged in the backend for auditing and security monitoring.
- **BLE Communication**: Low-power and secure communication between the user's device and the door controller.

## Technologies Used

- **Backend**:
  - Python 3
  - Flask
  - Flask-SQLAlchemy (for database interaction)
  - Flask-JWT-Extended (for user authentication)
  - Flask-CORS, Flask-Marshmallow

- **Smartphone and Smartwatch Clients**:
  - Dart
  - Flutter
  - `flutter_bloc` for state management
  - `http` for communication with the backend
  - `flutter_blue_plus` for BLE communication
  - `flutter_secure_storage` for securely storing sensitive data
  - `crypto` and `pointycastle` for cryptographic operations

- **ESP32 Door Controller**:
  - C++/Arduino
  - Libraries for Wi-Fi, BLE, and mbedtls for cryptography.

## System Architecture and Flow

The Aditus system operates through an interaction between the client devices, the door controller, and the backend.

1.  **Registration**:
    - A user logins, thus registering their device to their account using the smartphone app.
    - The app generates a public/private key pair for the device. The public key is sent to the backend and associated with the user's device.
    - An administrator registers a new ESP32 door controller in the backend, linking its MAC address to a specific door.
    - An administrator assigns access permissions to users or groups for specific doors (allow and deny rules just like a firewall hehe).

2.  **Unlocking a Door**:
    - The user opens the smartphone or smartwatch app and selects a nearby door (discovered via BLE).
    - The app sends the user's ID and the device ID to the ESP32 door controller.
    - The ESP32 controller connects to the backend via Wi-Fi to verify if the user is authorized to access the door.
    - If authorized, the backend sends the user's public key to the ESP32.
    - The ESP32 generates a unique, random challenge and sends it to the app.
    - The app signs the challenge with the device's private key and sends the resulting signature back to the ESP32.
    - The ESP32 verifies the signature using the public key received from the backend.
    - If the signature is valid, the ESP32 activates the door lock mechanism, granting access.
    - The entire transaction (successful or not) is logged in the backend.

## Getting Started

### Backend Service

1.  Navigate to the `aditus_backend_service` directory.
2.  Create and activate a Python virtual environment:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
3.  Install the required dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  Configure the environment variables by creating a `.env` file (you can use `.env.example` as a template).
5.  Run the setup script to initialize the database:
    ```bash
    ./setup.sh
    ```
6.  Start the Flask development server:
    ```bash
    python run.py
    ```

### Smartphone/Smartwatch Apps

1.  Ensure you have the Flutter SDK installed.
2.  Navigate to the `smartphone_client_app` or `smartwatch_client_app` directory.
3.  Install the project dependencies:
    ```bash
    flutter pub get
    ```
4.  Connect a device or emulator and run the app:
    ```bash
    flutter run
    ```

### ESP32 Door Controller

1.  Set up your environment for ESP32 development (personally recommend Arduino IDE).
2.  Open the `esp32_door_controller/esp32_door_controller.ino` file.
3.  Install the required libraries (e.g., `ArduinoJson`, `HTTPClient`, `BLEDevice`).
4.  Update the Wi-Fi credentials (`WIFI_SSID` and `WIFI_PASSWD`) and the backend API URL (`API_BASE_URL`) in the `.ino` file.
5.  Flash the firmware to your ESP32 device.

## Screenshots

### Authentication
<table>
  <tr>
    <td><img src="screenshots/login_screen.png" width="250"/><br/><b>Login Screen</b></td>
    <td><img src="screenshots/pin_setup_screen.png" width="250"/><br/><b>PIN Setup</b></td>
  </tr>
</table>

### Device Registration
<table>
  <tr>
    <td><img src="screenshots/device_registration_screen.png" width="250"/><br/><b>Device Registration</b></td>
    <td><img src="screenshots/device_management.png" width="250"/><br/><b>Device Management</b></td>
  </tr>
</table>

### Door Discovery, Access and Management
<table>
  <tr>
    <td><img src="screenshots/nearby_door_list.png" width="250"/><br/><b>Nearby Doors</b></td>
    <td><img src="screenshots/dor_unlocking_1.png" width="250"/><br/><b>Door Unlocking (1)</b></td>
    <td><img src="screenshots/door_unlocking_2.png" width="250"/><br/><b>Door Unlocking (2)</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/door_details.png" width="250"/><br/><b>Door Details</b></td>
    <td><img src="screenshots/access_histry_screen.png" width="250"/><br/><b>Access History</b></td>
  </tr>
</table>

### Account & Settings
<table>
  <tr>
    <td><img src="screenshots/account_screen.png" width="250"/><br/><b>Account Screen</b></td>
    <td><img src="screenshots/password_change.png" width="250"/><br/><b>Password Change</b></td>
    <td><img src="screenshots/pin_hacnge.png" width="250"/><br/><b>PIN Change</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/theme_and_color_screen.png" width="250"/><br/><b>Theme & Color Settings</b></td>
  </tr>
</table>

### Admin Features
<table>
  <tr>
    <td><img src="screenshots/admin_screen.png" width="250"/><br/><b>Admin Dashboard</b></td>
    <td><img src="screenshots/admin_door_list.png" width="250"/><br/><b>Door List (Admin)</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/user_list_screen.png" width="250"/><br/><b>User List</b></td>
    <td><img src="screenshots/user_details.png" width="250"/><br/><b>User Details</b></td>
    <td><img src="screenshots/user_edit_form.png" width="250"/><br/><b>Edit User</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/group_list.png" width="250"/><br/><b>Group List</b></td>
    <td><img src="screenshots/group_details_screen.png" width="250"/><br/><b>Group Details</b></td>
    <td><img src="screenshots/manage_group_members.png" width="250"/><br/><b>Manage Group Members</b></td>
  </tr>
</table>

### Smartwatch App
<table>
  <tr>
    <td><img src="screenshots/watch_pair_tutorial.png" width="200"/><br/><b>Pairing Tutorial</b></td>
    <td><img src="screenshots/watch_pair_code_input.png" width="200"/><br/><b>Pairing Code Input</b></td>
    <td><img src="screenshots/smartwatch_registration.png" width="250"/><br/><b>Smartwatch Registration</b></td>
  </tr>
  <tr>
    <td><img src="screenshots/watch_closest _door.png" width="200"/><br/><b>Closest Door</b></td>
    <td><img src="screenshots/watch_settings.png" width="200"/><br/><b>Watch Settings</b></td>
  </tr>
</table>

