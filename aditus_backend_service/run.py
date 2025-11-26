#!/usr/bin/env python3
"""
Aditus Backend Service
Entry point for the Flask application
"""
import os
from app import create_app

app = create_app()

if __name__ == '__main__':
    # Get configuration from environment
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', 5000))
    debug = os.getenv('FLASK_ENV', 'development') == 'development'

    print(f"\n{'='*60}")
    print(f"  Aditus Backend Service")
    print(f"{'='*60}")
    print(f"  Environment: {os.getenv('FLASK_ENV', 'development')}")
    print(f"  Running on: http://{host}:{port}")
    print(f"  Debug mode: {debug}")
    print(f"{'='*60}\n")

    app.run(host=host, port=port, debug=debug)