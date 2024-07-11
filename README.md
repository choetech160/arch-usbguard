# USBGUARD
what is the purpose of dis

## Install & configure
```bash
sudo pacman -S usbguard
sudo usbguard generate-policy > /etc/usbguard/rules.conf
```

Start and enable usbguard
```bash
sudo systemctl enable --now usbguard
```

Configure
```bash
sudo nvim /etc/usbguard/usbguard-daemon.conf
```
- `PresentDevicePolicy`: Set to apply-policy to apply rules to already connected devices
- PresentControllerPolicy: Set to keep to maintain the state of USB controllers
- InsertedDevicePolicy: Set to apply-policy to apply rules to newly inserted devices

Customize the rules
```bash
sudo nvim /etc/usbguard/rules.conf
```
Allow a specific device: allow id 1234:5678 serial "0000:00:00.0"
Block all devices by default: block

Restart USBGuard
```bsah
sudo systemctl restart usbguard
```

Use the CLI to manage devices
```bash
sudo usbguard list-devices
sudo usbguard allow device <device-id>
sudo usbguard block-device <device-id>
```
