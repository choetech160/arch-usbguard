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
#
#
#
allow_device() {
  local devices=$(sudo usbguard list-devices | grep "^[0-9]*: block")
  if [ -z "$devices" ]; then
    echo "No blocked devices found."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local options=()
  while IFS= read -r line; do
    if [[ $line =~ ^([0-9]+):.*id\ ([0-9a-f]{4}:[0-9a-f]{4}).*name\ \"([^\"]*)\" ]]; then
      local id="${BASH_REMATCH[1]}"
      local vendor_product="${BASH_REMATCH[2]}"
      local name="${BASH_REMATCH[3]}"
      name="${name:-"----"}" # Use ---- if name is empty
      options+=("$id" "$name" "$vendor_product" "[ ]")
    fi
  done <<<"$devices"

  if [ ${#options[@]} -eq 0 ]; then
    echo "No devices processed."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local selected=()
  local current=0

  tput civis # Hide cursor

  while true; do
    clear
    echo "Select devices to allow:"
    echo "(Use ↑↓ to navigate, SPACE to select/deselect, ENTER to confirm, 'q' to cancel)"
    echo

    for ((i = 0; i < ${#options[@]}; i += 4)); do
      if [ $i -eq $current ]; then
        echo -e ">\033[7m ${options[i + 3]} ${options[i + 1]} | ${options[i + 2]} \033[0m"
      else
        echo "  ${options[i + 3]} ${options[i + 1]} | ${options[i + 2]}"
      fi
    done

    IFS= read -r -s -n1 key

    case $key in
    $'\x1b')
      read -r -s -n2 key
      case $key in
      '[A') ((current > 0)) && ((current -= 4)) ;;
      '[B') ((current < ${#options[@]} - 4)) && ((current += 4)) ;;
      esac
      ;;
    ' ')
      if [[ "${options[current + 3]}" == "[ ]" ]]; then
        options[current + 3]="[●]"
        selected+=("${options[current]}")
      else
        options[current + 3]="[ ]"
        selected=("${selected[@]/${options[current]}/}")
      fi
      ;;
    $'\x0a')
      break
      ;;
    'q')
      tput cnorm
      echo "Operation cancelled."
      read -n 1 -s -r -p "Press any key to continue..."
      return
      ;;
    esac
  done

  tput cnorm # Show cursor

  if [ ${#selected[@]} -eq 0 ]; then
    echo "No devices selected."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local summary=""
  for device in "${selected[@]}"; do
    sudo usbguard allow-device "$device"
    summary+="Device $device allowed.\n"

    read -p "Do you want to create a permanent rule for device $device? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rule=$(sudo usbguard generate-policy | grep "^allow id.*hash \"$(sudo usbguard list-devices | grep "^$device:" | grep -o 'hash "[^"]*"')")
      echo "$rule" | sudo tee -a /etc/usbguard/rules.conf >/dev/null
      summary+="Permanent rule added for device $device.\n"
    fi
  done

  echo -e "$summary"
  read -n 1 -s -r -p "Press any key to continue..."
}
#
#
#
block_device() {
  local devices=$(sudo usbguard list-devices | grep "^[0-9]*: allow")
  if [ -z "$devices" ]; then
    echo "No allowed devices found."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local options=()
  while IFS= read -r line; do
    if [[ $line =~ ^([0-9]+):.*id\ ([0-9a-f]{4}:[0-9a-f]{4}).*name\ \"([^\"]*)\" ]]; then
      local id="${BASH_REMATCH[1]}"
      local vendor_product="${BASH_REMATCH[2]}"
      local name="${BASH_REMATCH[3]}"
      name="${name:-"----"}" # Use ---- if name is empty
      options+=("$id" "$name" "$vendor_product" "[ ]")
    fi
  done <<<"$devices"

  if [ ${#options[@]} -eq 0 ]; then
    echo "No devices processed."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local selected=()
  local current=0

  tput civis # Hide cursor

  while true; do
    clear
    echo "Select devices to block:"
    echo "(Use ↑↓ to navigate, SPACE to select/deselect, ENTER to confirm, 'q' to cancel)"
    echo

    for ((i = 0; i < ${#options[@]}; i += 4)); do
      if [ $i -eq $current ]; then
        echo -e ">\033[7m ${options[i + 3]} ${options[i + 1]} | ${options[i + 2]} \033[0m"
      else
        echo "  ${options[i + 3]} ${options[i + 1]} | ${options[i + 2]}"
      fi
    done

    IFS= read -r -s -n1 key

    case $key in
    $'\x1b')
      read -r -s -n2 key
      case $key in
      '[A') ((current > 0)) && ((current -= 4)) ;;
      '[B') ((current < ${#options[@]} - 4)) && ((current += 4)) ;;
      esac
      ;;
    ' ')
      if [[ "${options[current + 3]}" == "[ ]" ]]; then
        options[current + 3]="[●]"
        selected+=("${options[current]}")
      else
        options[current + 3]="[ ]"
        selected=("${selected[@]/${options[current]}/}")
      fi
      ;;
    $'\x0a')
      break
      ;;
    'q')
      tput cnorm
      echo "Operation cancelled."
      read -n 1 -s -r -p "Press any key to continue..."
      return
      ;;
    esac
  done

  tput cnorm # Show cursor

  if [ ${#selected[@]} -eq 0 ]; then
    echo "No devices selected."
    read -n 1 -s -r -p "Press any key to continue..."
    return
  fi

  local summary=""
  for device in "${selected[@]}"; do
    sudo usbguard block-device "$device"
    summary+="Device $device blocked.\n"

    read -p "Do you want to create a permanent rule to block device $device? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rule=$(sudo usbguard generate-policy | grep "^block id.*hash \"$(sudo usbguard list-devices | grep "^$device:" | grep -o 'hash "[^"]*"')")
      echo "$rule" | sudo tee -a /etc/usbguard/rules.conf >/dev/null
      summary+="Permanent block rule added for device $device.\n"
    fi
  done

  echo -e "$summary"
  read -n 1 -s -r -p "Press any key to continue..."
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
