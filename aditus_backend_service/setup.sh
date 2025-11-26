#!/bin/bash

# Aditus Backend Service Setup Script

echo "========================================="
echo "  Aditus Backend Service Setup"
echo "========================================="
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"
echo ""

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

echo "✓ Virtual environment activated"
echo ""

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "✓ Dependencies installed"
echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env file created"
    echo ""
    echo "IMPORTANT: Please edit .env and set your configuration:"
    echo "  - SECRET_KEY"
    echo "  - JWT_SECRET_KEY"
    echo "  - ADMIN_EMAIL and ADMIN_PASSWORD"
    echo ""
else
    echo "✓ .env file already exists"
    echo ""
fi

echo "========================================="
echo "  Setup Complete!"
echo "========================================="