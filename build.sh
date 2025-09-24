#!/bin/bash

ln -sf /usr/share/zoneinfo/Asia/Manila /etc/localtime
echo "Asia/Manila" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

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
    
    # Register token and install service
    sudo cloudflared service install "$cloudflared_token"
    echo "Cloudflared service installed with provided token."
}


echo Entrypoint script is Running...
echo

create_user_and_cloudflared "$@"

echo -e "This script is ended\n"

echo -e "starting xrdp services...\n"

trap "stop_xrdp_services" SIGKILL SIGTERM SIGHUP SIGINT EXIT
start_xrdp_services