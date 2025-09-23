#!/bin/bash

# Default values
DEFAULT_PORT=3390

# Function to print usage
usage() {
    echo "Usage: $0 <image_name> [--port <port>] [--username <username>] [--password <password>] [--sp <sudo_cap>] [--cft <cloudflared_token>]"
    exit 1
}

# Check if docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if first argument exists (image)
if [[ $# -lt 1 ]]; then
    echo "Error: image name is required"
    usage
fi

# First argument is the image
IMAGE="$1"
shift

# Parse remaining arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port) PORT="$2"; shift 2 ;;
        --username) USERNAME="$2"; shift 2 ;;
        --password) PASSWORD="$2"; shift 2 ;;
        --sp) SUDO_CAP="$2"; shift 2 ;;
        --cft) CLOUD_FLARED="$2"; shift 2 ;;
        *) echo "Unknown option $1"; usage ;;
    esac
done

# Set port to default if not provided
if [[ -z "$PORT" ]]; then
    PORT=$DEFAULT_PORT
    # Increment port until available
    while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
        PORT=$((PORT + 1))
    done
fi

echo "Running on rdp://localhost:$PORT"


# Run docker container with sudo
sudo docker run -it \
-v "$HOME/$IMAGE:/home" \
--runtime=nvidia \
--gpus all \
-p "$PORT":3389 \
"$IMAGE" \
"${USERNAME:-}" "${PASSWORD:-}" "${SUDO_CAP:-}" "${CLOUD_FLARED:-}"

