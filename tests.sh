#!/bin/bash

# Check if a BASE_URL parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <BASE_URL>"
    exit 1
fi

# Get the URL from the command line argument
base_url="$1"

# Function to check the HTTP status code
check_status() {
    local url="$1"
    local expected_status="$2"

    # Use curl to make an HTTP GET request and store the response code in a variable
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    # Check if the response code matches the expected status code
    if [ "$response_code" -eq "$expected_status" ]; then
        echo "URL: $url - HTTP Status Code $response_code: Success"
    else
        echo "URL: $url - HTTP Status Code $response_code: Failure (Expected: $expected_status)"
        exit 1  # Exit with non-zero status code
    fi
}

# Test case 1: Expecting a 200 status code
check_status $base_url 200

# Test case 2: Expecting a 404 status code
check_status "$base_url/not_found" 404
