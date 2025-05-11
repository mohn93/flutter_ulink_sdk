#!/bin/bash

echo "Setting up ULink SDK environment configuration..."

# Check if the destination directory exists
DIR="lib/src/config"
if [ ! -d "$DIR" ]; then
    echo "Error: Directory $DIR does not exist."
    exit 1
fi

# Check if env.example.dart exists
if [ ! -f "$DIR/env.example.dart" ]; then
    echo "Error: Example environment file $DIR/env.example.dart not found."
    exit 1
fi

# Check if env.dart already exists
if [ -f "$DIR/env.dart" ]; then
    read -p "env.dart already exists. Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup canceled."
        exit 0
    fi
fi

# Copy the example file
cp "$DIR/env.example.dart" "$DIR/env.dart"
echo "Created env.dart from example template."

# Prompt for API key
read -p "Enter your ULink API key: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "Warning: Using default API key from template."
else
    # Replace API key in the file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/your_api_key_here/$API_KEY/g" "$DIR/env.dart"
    else
        # Linux and others
        sed -i "s/your_api_key_here/$API_KEY/g" "$DIR/env.dart"
    fi
    echo "API key updated."
fi

# Prompt for base URL
read -p "Enter base URL (press enter for default https://api.ulink.ly): " BASE_URL
if [ -n "$BASE_URL" ]; then
    # Replace base URL in the file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|https://api.ulink.ly|$BASE_URL|g" "$DIR/env.dart"
    else
        # Linux and others
        sed -i "s|https://api.ulink.ly|$BASE_URL|g" "$DIR/env.dart"
    fi
    echo "Base URL updated."
fi

echo "Environment configuration complete!"
echo "Note: lib/src/config/env.dart is in .gitignore and should not be committed to version control." 