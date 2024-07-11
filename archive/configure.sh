#!/bin/bash
# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display messages and wait for user input
display_message() {
    clear
    echo -e "${YELLOW}===== Operation Summary =====${NC}"
    echo -e "$1"
    echo -e "${YELLOW}=============================${NC}"
    echo -e "\nPress Enter to return to the main menu..."
    read -n 1 -s -r
}

# Check if USBGuard is installed
check_usbguard() {
    if ! command -v usbguard &>/dev/null; then
        display_message "${RED}USBGuard is not installed.${NC}\n\nPlease install USBGuard and run this script again."
    else
        display_message "${GREEN}USBGuard is installed.${NC}"
    fi
}

# Setup USBGuard
setup_usbguard() {
  echo -e "${YELLOW}Setting up USBGuard...${NC}"
  check_usbguard
  sudo sh -c 'usbguard generate-policy > /etc/usbguard/rules.conf'
  sudo systemctl enable --now usbguard
  echo -e "${GREEN}USBGuard setup complete.${NC}"
}

# List all USB devices
list_devices() {
    echo -e "${YELLOW}Listing connected USB devices:${NC}"
    echo -e "${CYAN}==============================${NC}"
    
    sudo usbguard list-devices | while read -r line; do
        if [[ $line =~ ^([0-9]+):\ (allow|block)\ id\ ([0-9a-f]{4}:[0-9a-f]{4})\ serial\ \"(.*)\"\ name\ \"(.*)\"\ hash\ \"([^\"]+)\"\ parent-hash\ \"([^\"]+)\"\ via-port\ \"([^\"]+)\"\ with-interface\ (.*)\ with-connect-type\ \"(.*)\"$ ]]; then
            device_num="${BASH_REMATCH[1]}"
            status="${BASH_REMATCH[2]}"
            vendor_product="${BASH_REMATCH[3]}"
            serial="${BASH_REMATCH[4]}"
            name="${BASH_REMATCH[5]}"
            hash="${BASH_REMATCH[6]}"
            parent_hash="${BASH_REMATCH[7]}"
            port="${BASH_REMATCH[8]}"
            interface="${BASH_REMATCH[9]}"
            connect_type="${BASH_REMATCH[10]}"
            
            # Color coding for status
            if [ "$status" == "allow" ]; then
                status_color="${GREEN}"
            else
                status_color="${RED}"
            fi
            
            echo -e "${YELLOW}Device ${device_num}:${NC}"
            echo -e "  ${CYAN}Name:${NC}          ${name:-"---"}"
            echo -e "  ${CYAN}Status:${NC}        ${status_color}${status^}${NC}"
            echo -e "  ${CYAN}ID:${NC}            ${vendor_product}"
            echo -e "  ${CYAN}Port:${NC}          ${port}"
            if [ -n "$serial" ]; then
                echo -e "  ${CYAN}Serial:${NC}        ${serial}"
            fi
            echo -e "  ${CYAN}Interface:${NC}     ${interface}"
            echo -e "  ${CYAN}Connect Type:${NC}  ${connect_type}"
            echo -e "  ${CYAN}Hash:${NC}          ${hash}"
            echo -e "  ${CYAN}Parent Hash:${NC}   ${parent_hash}"
            echo -e "${CYAN}------------------------------${NC}"
        fi
    done
    
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}
# Function to allow devices
allow_device() {
    local devices=$(sudo usbguard list-devices | grep "^[0-9]*: block")
    if [ -z "$devices" ]; then
        display_message "${YELLOW}No blocked devices found.${NC}"
        return
    fi

    local options=()
    while IFS= read -r line; do
        if [[ $line =~ ^([0-9]+):\ block\ id\ ([0-9a-f]{4}:[0-9a-f]{4})\ serial\ \"(.*)\"\ name\ \"(.*)\" ]]; then
            local id="${BASH_REMATCH[1]}"
            local vendor_product="${BASH_REMATCH[2]}"
            local serial="${BASH_REMATCH[3]}"
            local name="${BASH_REMATCH[4]}"
            options+=("$id" "$name - $vendor_product${serial:+ ($serial)}" "OFF")
        fi
    done <<< "$devices"

    if [ ${#options[@]} -eq 0 ]; then
        display_message "${YELLOW}No blocked devices found.${NC}"
        return
    fi

    local chosen
    chosen=$(whiptail --title "Allow USB Devices" --checklist \
        "Select devices to allow:" 20 78 10 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        display_message "${YELLOW}No devices selected.${NC}"
        return
    fi

    local summary=""
    for device in $chosen; do
        device=$(echo $device | tr -d '"')
        sudo usbguard allow-device "$device"
        summary+="${GREEN}Device $device allowed.${NC}\n"
        
        if whiptail --title "Create Permanent Rule" --yesno "Do you want to create a permanent rule for device $device?" 10 60; then
            rule=$(sudo usbguard generate-policy | grep "^allow id.*hash \"$(sudo usbguard list-devices | grep "^$device:" | grep -o 'hash "[^"]*"')")
            echo "$rule" | sudo tee -a /etc/usbguard/rules.conf > /dev/null
            summary+="${GREEN}Permanent rule added for device $device.${NC}\n"
        fi
    done
    
    display_message "$summary"
}

# Function to block devices
block_device() {
    local devices=$(sudo usbguard list-devices | grep "^[0-9]*: allow")
    if [ -z "$devices" ]; then
        display_message "${YELLOW}No allowed devices found.${NC}"
        return
    fi

    local options=()
    while IFS= read -r line; do
        if [[ $line =~ ^([0-9]+):\ allow\ id\ ([0-9a-f]{4}:[0-9a-f]{4})\ serial\ \"(.*)\"\ name\ \"(.*)\" ]]; then
            local id="${BASH_REMATCH[1]}"
            local vendor_product="${BASH_REMATCH[2]}"
            local serial="${BASH_REMATCH[3]}"
            local name="${BASH_REMATCH[4]}"
            options+=("$id" "$name - $vendor_product${serial:+ ($serial)}" "OFF")
        fi
    done <<< "$devices"

    if [ ${#options[@]} -eq 0 ]; then
        display_message "${YELLOW}No allowed devices found.${NC}"
        return
    fi

    local chosen
    chosen=$(whiptail --title "Block USB Devices" --checklist \
        "Select devices to block:" 20 78 10 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)

    if [ $? -ne 0 ]; then
        display_message "${YELLOW}No devices selected.${NC}"
        return
    fi

    local summary=""
    for device in $chosen; do
        device=$(echo $device | tr -d '"')
        sudo usbguard block-device "$device"
        summary+="${RED}Device $device blocked.${NC}\n"
    done
    
    display_message "$summary"
}

main_menu() {
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${RED}This script should not be run as root or with sudo. \nPlease run it as a regular user.${NC}"
        exit 1
    fi
    while true; do
        clear
        echo -e "${YELLOW}===== USBGuard Configuration Menu =====${NC}"
        echo "1. Check USBGuard Installation"
        echo "2. Setup USBGuard"
        echo "3. List USB Devices"
        echo "4. Allow a Device"
        echo "5. Block a Device"
        echo "6. Exit"
        read -p "Enter your choice (1-6): " choice

        case $choice in
        1) check_usbguard ;;
        2) setup_usbguard ;;
        3) list_devices ;;
        4) allow_device ;;
        5) block_device ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *) display_message "${RED}Invalid choice. Please try again.${NC}" ;;
        esac
    done
}

main_menu
