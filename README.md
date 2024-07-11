# USBGuard interface
[official repo here](https://usbguard.github.io/)

I DID NOT created USBGuard, I created a CLI interface for it. It does not go
into all the daemon configuration options either.

## What is USBGuard and how can it help protect my device

USBGuard can significantly enhance your system's security against USB-based threats in several ways:
Device Whitelisting/Blacklisting:
USBGuard allows you to create rules that explicitly allow (whitelist) or block (blacklist) USB devices based on various attributes like vendor ID, product ID, serial number, etc.
This prevents unauthorized or potentially malicious USB devices from accessing your system.
Protection Against Rogue USB Devices:
It helps defend against attacks like BadUSB, where seemingly innocent USB devices can masquerade as keyboards or other trusted devices to inject malicious commands.
By strictly controlling which devices are allowed, USBGuard mitigates risks from maliciously reprogrammed USB devices.
Data Exfiltration Prevention:
You can block unauthorized USB storage devices, preventing sensitive data from being copied onto external drives without permission.
Dynamic Device Control:
USBGuard allows real-time management of USB devices. You can allow or block devices on-the-fly as they are connected or disconnected.
Policy-Driven Security:
It enables the implementation of comprehensive USB device usage policies, which can be crucial in high-security environments.
System Integration:
USBGuard integrates with the Linux kernel's USB subsystem, providing low-level control over USB device authorization.
Auditing and Logging:
It can log USB device events, allowing for security audits and forensic analysis of USB device usage.
Granular Control:
Rules can be based on various device attributes, allowing for very specific and granular control over which devices are allowed.
Protection Against Accidental Data Loss:
By controlling which USB storage devices are allowed, it can help prevent accidental data transfers to unauthorized devices.
Compliance Support:
For organizations with strict security requirements, USBGuard can help maintain compliance with policies that restrict USB device usage.


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

