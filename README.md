# USBGuard interface
[official repo here](https://usbguard.github.io/)

I DID NOT created USBGuard, I created a CLI interface for it. It does not go
into all the daemon configuration options either.

## What is USBGuard and how can it help protect my device

USBGuard significantly bolsters your system's defenses against USB-based threats through various mechanisms:

### 1. Device Whitelisting/Blacklisting
- Create rules to explicitly allow or block USB devices based on attributes like:
  - Vendor ID
  - Product ID
  - Serial number
- Prevent unauthorized or potentially malicious USB devices from accessing your system

### 2. Protection Against Rogue USB Devices
- Defend against attacks like BadUSB
  - Prevents innocent-looking USB devices from masquerading as trusted devices (e.g., keyboards)
  - Mitigates risks from maliciously reprogrammed USB devices

### 3. Data Exfiltration Prevention
- Block unauthorized USB storage devices
- Prevent sensitive data from being copied to external drives without permission

### 4. Dynamic Device Control
- Manage USB devices in real-time
- Allow or block devices on-the-fly as they are connected or disconnected

### 5. Policy-Driven Security
- Implement comprehensive USB device usage policies
- Crucial for high-security environments

### 6. System Integration
- Integrates with the Linux kernel's USB subsystem
- Provides low-level control over USB device authorization

### 8. Granular Control
- Create rules based on various device attributes
- Allow for very specific and granular control over permitted devices

# Run the script
```bash
./configure.sh
```
Follow the on-screen prompts to manage your USB devices.

## Menu Options

1. **Check USBGuard Installation**: Verifies if USBGuard is installed on your system.
2. **Setup USBGuard**: Generates a basic policy and enables the USBGuard service.
3. **List USB Devices**: Displays all connected USB devices and their current status (allowed/blocked).
4. **Allow a Device**: Allows you to select and authorize blocked USB devices.
5. **Block a Device**: Allows you to select and block currently allowed USB devices.
6. **Exit**: Quits the script.

## Notes

- This script shoud NOT be run with sudo privileges to interact with USBGuard. When sudo is needed, it will tell you
- Always be cautious when allowing USB devices, especially in security-sensitive environments.
- Regularly update your USBGuard policies to maintain security.

