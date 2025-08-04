# Cisco Device Intake Script

An automated expect script for performing initial intake assessments on Cisco network devices via serial console connection.

## Overview

This script connects to Cisco switches and routers via serial console and automatically executes a comprehensive set of diagnostic and informational commands to document the device's current state. It's designed for lab environments and production intake processes where you need to systematically document multiple devices.

## Features

- **Device-specific command sets** - Separate optimized command lists for switches vs routers
- **Automated boot prompt handling** - Handles common Cisco boot dialogs and login scenarios
- **Timestamped output files** - Creates organized log files with device name and timestamp
- **Error handling** - Gracefully handles unsupported commands and timeouts
- **Serial port flexibility** - Supports multiple USB-to-serial adapters
- **Progress feedback** - Real-time status updates during execution

## Requirements

### Software Dependencies
- `expect` - For script automation
- `minicom` - For serial communication
- Linux/Unix environment

Install on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install expect minicom
```

Install on RHEL/CentOS/Fedora:
```bash
sudo yum install expect minicom
# or
sudo dnf install expect minicom
```

### Hardware Requirements
- USB-to-Serial adapter (USB-to-RJ45 console cable)
- Serial console access to target devices

## Installation

1. Clone or download the script:
```bash
wge[48;42;145;1260;2030tt https://example.com/intake.expect
# or copy the script content to a new file
```

2. Make executable:
```bash
chmod +x intake.expect
```

3. Verify serial device:
```bash
ls -la /dev/ttyUSB*
# Should show your USB-to-serial adapter, typically /dev/ttyUSB0
```

## Usage

### Basic Syntax
```bash
./intake.expect <device-name> <device-type> [serial-port]
```

### Parameters
- **device-name**: Identifier for the device (used in output filename)
- **device-type**: Either `switch` or `router`
- **serial-port**: Optional serial device path (default: `/dev/ttyUSB0`)

### Examples

```bash
# Basic switch intake
./intake.expect switch1 switch

# Router with specific serial port
./intake.expect router-core router /dev/ttyUSB1

# Multiple devices
./intake.expect sw-access-01 switch /dev/ttyUSB0
./intake.expect sw-access-02 switch /dev/ttyUSB1
./intake.expect rtr-wan-01 router /dev/ttyS0
```

## Commands Executed

### Switch Command Set
- `show version` - Hardware and software information
- `show boot` - Boot parameters and IOS image
- `show startup-config` - Startup configuration
- `dir flash:` - Flash storage contents
- `show inventory` - Hardware inventory and serial numbers
- `show sdm prefer` - Switching database manager template
- `show env all` - Environmental monitoring
- `show post` - Power-on self-test results
- `show processes cpu sorted` - CPU utilization
- `show memory statistics` - Memory usage
- `show clock detail` - System time

### Router Command Set
- `show version` - Hardware and software information
- `show bootvar` - Boot variables and IOS image
- `show startup-config` - Startup configuration
- `dir bootflash:` - Boot flash storage contents
- `show inventory` - Hardware inventory and serial numbers
- `show platform` - Platform-specific information
- `show license udi` - Unique Device Identifier
- `show license all` - Licensing information
- `show environment all` - Environmental monitoring
- `show diag` - Hardware diagnostics
- `show processes cpu sorted` - CPU utilization
- `show memory statistics` - Memory usage
- `show clock detail` - System time
- `dir usb0:` - USB storage contents (if present)
- `show rom-monitor` - ROMMON information

## Output Files

Files are created with the format: `<device-name>-intake-YYYYMMDD-HHMMSS.txt`

Examples:
- `switch1-intake-20240804-143022.txt`
- `router-core-intake-20240804-150135.txt`

## Troubleshooting

### Common Issues

**Permission denied on serial port:**
```bash
sudo usermod -a -G dialout $USER
# Log out and back in, or:
sudo chmod 666 /dev/ttyUSB0
```

**Device not responding:**
- Check console cable connection
- Verify correct serial port (`ls /dev/ttyUSB*`)
- Try different baud rate in minicom settings
- Power cycle the target device

**Script hangs at boot:**
- Some devices require manual intervention at boot
- Press Ctrl+C to exit and connect manually first
- Use `minicom -D /dev/ttyUSB0` to verify connectivity

**Commands fail or timeout:**
- Increase timeout value in script (line 20: `set timeout 30`)
- Check if device requires authentication
- Verify device is fully booted

### Boot Prompt Handling

The script automatically handles these common prompts:
- "Would you like to enter the initial configuration dialog? [yes/no]:"
- "Would you like to terminate autoinstall? [yes]:"
- "Press RETURN to get started!"
- Username/Password prompts (tries blank credentials)

### Manual Override

If automated handling fails, you can:
1. Connect manually with minicom first
2. Handle boot prompts manually
3. Exit minicom
4. Run the intake script

## Best Practices

### Device Preparation
- Ensure devices are powered and fully booted
- Reset devices to factory defaults if needed (`write erase` + `reload`)
- Have console access ready before running script

### Workflow Recommendations
```bash
# Create intake directory
mkdir -p ~/device-intake/$(date +%Y%m%d)
cd ~/device-intake/$(date +%Y%m%d)

# Run intake for multiple devices
./intake.expect switch1 switch
./intake.expect switch2 switch  
./intake.expect router1 router

# Review results
ls -la *.txt
grep -i "error\|fail" *.txt
```

### File Management
```bash
# Archive completed intakes
tar -czf intake-batch-$(date +%Y%m%d).tar.gz *.txt

# Quick device summary
for file in *.txt; do
    echo "=== $file ==="
    grep -E "(cisco|version|serial|uptime)" "$file" | head -5
done
```

## Script Customization

### Adding Commands
Edit the `commands` arrays in the script:
```bash
# For switches, add to switch command set around line 80
# For routers, add to router command set around line 95
```

### Adjusting Timeouts
Modify the timeout value for slower devices:
```bash
set timeout 60  # Increase from default 30 seconds
```

### Serial Port Settings
Default minicom settings should work for most Cisco devices (9600 8N1). If needed, configure minicom:
```bash
sudo minicom -s  # Configure and save settings
```

## License

This script is provided as-is for educational and professional use. Modify as needed for your environment.

## Contributing

Feel free to submit improvements, especially for handling additional device types or boot scenarios.

## Version History

- v1.0 - Initial release with basic switch/router support
- v1.1 - Added device type validation and improved error handling
