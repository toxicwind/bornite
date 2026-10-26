#!/bin/sh
# This script uninstalls bornite on Linux.
# It removes the binary, systemd service, config.yaml (optional), and bornite user and group.

set -eu

red="$( (/usr/bin/tput bold || :; /usr/bin/tput setaf 1 || :) 2>&-)"
plain="$( (/usr/bin/tput sgr0 || :) 2>&-)"

status() { echo ">>> $*" >&2; }
error() { echo "${red}ERROR:${plain} $*"; exit 1; }
warning() { echo "${red}WARNING:${plain} $*"; }

available() { command -v $1 >/dev/null; }

SUDO=
if [ "$(id -u)" -ne 0 ]; then
    if ! available sudo; then
        error "This script requires superuser permissions. Please re-run as root."
    fi

    SUDO="sudo"
fi

configure_systemd() {
    status "Stopping bornite service..."
    $SUDO systemctl stop bornite

    status "Disabling bornite service..."
    $SUDO systemctl disable bornite
}
if available systemctl; then
    configure_systemd
fi

if available bornite; then
    status "Removing bornite binary..."
    $SUDO rm $(which bornite)
fi

if [ -f "/usr/share/bornite/config.yaml" ]; then
    while true; do
        printf "Delete config.yaml (/usr/share/bornite/config.yaml)? [y/N] " >&2
        read answer
        case "$answer" in
            [Yy]* ) 
                $SUDO rm -r /usr/share/bornite
                break
                ;;
            [Nn]* | "" ) 
                break
                ;;
            * ) 
                echo "Invalid input. Please enter y or n."
                ;;
        esac
    done
fi

if id bornite >/dev/null 2>&1; then
    status "Removing bornite user..."
    $SUDO userdel bornite
fi

if getent group bornite >/dev/null 2>&1; then
    status "Removing bornite group..."
    $SUDO groupdel bornite
fi
