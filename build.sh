#!/bin/bash

install_firefox() {
    if command -v firefox &> /dev/null; then
        echo "Firefox is already installed. Skipping..."
        return
    fi
    
    echo "Installing Firefox..."
    mkdir -p /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list
    echo -e "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000" > /etc/apt/preferences.d/mozilla
    
    apt-get update && apt-get install -y firefox
    echo "Firefox installed."
}

start_xrdp_services() {
    # Preventing xrdp startup failure
    rm -rf /var/run/xrdp-sesman.pid
    rm -rf /var/run/xrdp.pid
    rm -rf /var/run/xrdp/xrdp-sesman.pid
    rm -rf /var/run/xrdp/xrdp.pid
    
    # Use exec ... to forward SIGNAL to child processes
    xrdp-sesman && exec xrdp -n
}

stop_xrdp_services() {
    xrdp --kill
    xrdp-sesman --kill
    exit 0
}

create_user_and_cloudflared() {
    if [[ $# -ne 4 ]]; then
        echo "Usage: $0 <username> <password> <sudo(yes/no)> <cloudflared_token>"
        exit 1
    fi
    
    local username=$1
    local password=$2
    local sudo_flag=$3
    local cloudflared_token=$4
    
    # Create user and group
    addgroup "$username"
    useradd -m -s /bin/bash -g "$username" "$username"
    echo "$username:$password" | chpasswd
    
    # Add sudo if requested
    if [[ "$sudo_flag" == "yes" ]]; then
        usermod -aG sudo "$username"
    fi
    echo "User '$username' created. Sudo: $sudo_flag"
    
    # Install cloudflared if not installed
    if command -v cloudflared &> /dev/null; then
        echo "Cloudflared is already installed. Skipping..."
    else
        echo "Installing Cloudflared..."
        sudo mkdir -p --mode=0755 /usr/share/keyrings
        curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
        
        sudo apt-get update && sudo apt-get install -y cloudflared
        echo "Cloudflared installed."
        
        # Register token and install service
        sudo cloudflared service install "$cloudflared_token"
        echo "Cloudflared service installed with provided token."
    fi
}


echo Entrypoint script is Running...
echo


install_firefox
create_user_and_cloudflared "$@"

echo -e "This script is ended\n"

echo -e "starting xrdp services...\n"

trap "stop_xrdp_services" SIGKILL SIGTERM SIGHUP SIGINT EXIT
start_xrdp_services