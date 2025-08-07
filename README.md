# Cisco Device Intake Script

An automated expect script for performing initial intake assessments on Cisco network devices via serial console connection.

## Overview

This script connects to select Cisco switches and routers via serial console and automatically executes a comprehensive set of diagnostic and informational commands to document the device's current state. It's designed for lab environments and production intake processes where you need to systematically document multiple devices. This script currently is designed for the initial intake of equipment that has been unboxed and powered up on a bench, not racked and cabled. Therefore, many initial commands for equipment on a network are not included.

## Features

- **Device-specific command sets** - Separate optimized command lists for switches vs routers
- **Automated boot prompt handling** - Handles common Cisco boot dialogs and login scenarios
- **Timestamped output files** - Creates organized log files with device name and timestamp
- **Command-level timestamps** - Each command execution is logged with precise timing
- **Enable password handling** - Supports both environment variables and interactive prompts
- **Robust error handling** - Gracefully handles unsupported commands and timeouts
- **Serial port flexibility** - Supports multiple USB-to-serial adapters
- **Progress feedback** - Real-time status updates during execution

## Requirements

### Tested Devices
- Linux maintenance laptop
- Target Switch or Router:
  - Cisco Catalyst 3560G (limited stack commands)
  - Cisco Catalyst 3750-X (full feature set)
  - Cisco ISR 2921/2951 routers

**Note**: Script may work on other Cisco devices but has only been tested on the above models.

### Software Dependencies
- `expect` - For script automation
- Linux/Unix environment

Install on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install expect 
```

Install on RHEL/CentOS/Fedora:
```bash
# For older versions (RHEL/CentOS 7, Fedora <22)
sudo yum install expect

# For modern Fedora (22+)
sudo dnf upgrade --refresh 
sudo dnf install expect
```

### Hardware Requirements
- USB-to-Serial adapter (USB-to-RJ45 console cable)
- Serial console access to target devices

## Prerequisites

### Serial Port Setup
Ensure your USB-to-serial adapter is recognized:
```bash
# Check if device is detected
dmesg | grep ttyUSB
lsusb | grep -i serial

# Verify permissions
ls -la /dev/ttyUSB0
```

### User Permissions
Add yourself to the dialout group for serial access:
```bash
sudo usermod -a -G dialout $USER
#Log out and back in for changes to take effect

# Alternative: Temporary ownership change (less secure) - Not Tested
sudo chown $USER /dev/ttyUSB0
```

## Installation

1. Download the script:
```bash
# Download from repository (replace with actual URL)
wget https://github.com/RedAnne0not0/cisco-scripts/raw/main/intake.expect
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

### Enable Password Handling

```bash
# Set environment variable for automatic password entry
export ENABLEPW="your_enable_password"
./intake.expect switch1 switch

# Or let the script prompt you (more secure)
./intake.expect switch1 switch
# Script will prompt: "Enable password: "
```

## Commands Executed

### General Setup Commands
- `terminal length 0` - Disable paging
- `terminal width 512` - Prevent line wrapping
- `show clock detail` - RTC/NVRAM check and run-time delta (executed at start and end)

### Switch Command Set
- `show version` - Hardware and software information
- `show boot` - Boot parameters and IOS image
- `show startup-config` - Startup configuration
- `show vlan brief` - Should only return "vlan 1"
- `show running-config | include hostname` - Ensure hostname is default
- `dir flash:` - Flash storage contents
- `show inventory` - Hardware inventory and serial numbers
- `show sdm prefer` - Switching database manager template
- `show env all` - Environmental monitoring
- `show interfaces status` - Confirm all ports are recognised by the ASIC, spot dead SFPs or non-Cisco optics (type -> unknown), verify there are no leftover interface descriptions or VLAN assignments
- `show ip interface brief` - List of all layer 3 interfaces, admin/oper/up status, assigned IPs (should be "unassigned" on a reset box)
- `show post` - Power-on self-test results
- `show processes cpu history` - CPU utilization trends over time (detects spikes and sustained load patterns)
- `show memory statistics` - Memory usage
- `show license udi` - Unique Device Identifier (3750-X, not on 3560G but fails gracefully)
- `show license all` - Licensing information (3750-X, not on 3560G but fails gracefully)
- #For stackable devices (e.g. 3750-X), fails gracefully on non-stackable (e.g. 3560G)
- `show switch detail` - Switch #, Role, MAC, Priority, State, Serial #, Model, HW/FW revision, Uptime, Stack ring info, Config register, etc.
- `show stack-power` - PSU check for stackable devices (works even without stack cables)
- `show switch stack-ring speed` - Confirms ASIC health and StackWisePlus firmware on stackable devices (works even if not stacked)

### Router Command Set
- `show version` - Hardware and software information
- `show bootvar` - Boot variables and IOS image
- `show startup-config` - Startup configuration
- `show running-config | include hostname` - Ensure hostname is default
- `dir bootflash:` - Boot flash storage contents
- `show inventory` - Hardware inventory and serial numbers
- `show platform` - Platform-specific information
- `show ip interface brief` - List of all layer 3 interfaces, admin/oper/up status, assigned IPs (should be "unassigned" on a reset box)
- `show license udi` - Unique Device Identifier
- `show license all` - Licensing information
- `show environment all` - Environmental monitoring
- `show diag` - Hardware diagnostics
- `show processes cpu history` - CPU utilization trends over time (detects spikes and sustained load patterns)
- `show memory statistics` - Memory usage
- `dir usb0:` - USB storage contents (**optional** - may cause 30-second stall if no USB device present)
- `show rom-monitor` - ROMMON information

## Output Files

Files are created with the format: `<device-name>-intake-YYYYMMDD-HHMMSS.txt`

Examples:
- `switch1-intake-20240804-143022.txt`
- `router-core-intake-20240804-150135.txt`

## Logging and Timestamps

Each command execution is timestamped in the output file:

```
2025-08-04 14:30:22  >> show version
Cisco IOS Software, C3750 Software (C3750-IPSERVICESK9-M), Version 15.0(2)SE11
Technical Support: http://www.cisco.com/techsupport
Copyright (c) 1986-2017 by Cisco Systems, Inc.
...

2025-08-04 14:30:25  >> show inventory
NAME: "1", DESCR: "WS-C3750X-24T-L"
PID: WS-C3750X-24T-L, VID: V06, SN: FDO1234ABCD
...
```

This provides clear command separation and timing information for analysis.

## Error Handling

The script includes robust error handling:
- **Command errors**: Invalid commands are logged but don't stop execution
- **Timeout protection**: Commands that hang are automatically skipped
- **Enable password recovery**: Handles password failures gracefully with echo restoration
- **Device compatibility**: Commands not supported on specific models are handled gracefully

Error messages appear both on screen and in the log file with timestamps.

(Note: In the event of issues with the script not getting `privilege exec` mode, there is commented out error reporting in the `enter_enable` procedure)

## Batch Processing
(not tested)

For multiple devices, create a batch script:

```bash
#!/bin/bash
# batch-intake.sh

devices=(
    "switch1:switch:/dev/ttyUSB0"
    "switch2:switch:/dev/ttyUSB1"
    "router1:router:/dev/ttyUSB2"
)

for device in "${devices[@]}"; do
    IFS=':' read -r name type port <<< "$device"
    echo "Processing $name..."
    ./intake.expect "$name" "$type" "$port"
    echo "Completed $name"
    sleep 5  # Brief pause between devices
done

echo "Batch intake completed!"
```

## Troubleshooting

### Common Issues

**Permission denied on serial port:**
```bash
sudo usermod -a -G dialout $USER
# Log out and back in, or use temporary ownership:
sudo chown $USER /dev/ttyUSB0
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
- Increase timeout value in script (search for `set timeout 30`)
- Check if device requires authentication
- Verify device is fully booted

**Enable password issues:**
- Verify password is correct
- Try setting ENABLEPW environment variable
- Check for special characters in password

**USB directory check timeout:**
- The `dir usb0:` command may cause a 30-second stall on routers with no USB device
- This is expected behavior and the script will continue after timeout

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
- Verify no other processes are using the serial port

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

### Quality Checks
```bash
# Check for common issues in intake files
grep -i "startup-config is not present" *.txt  # Verify reset devices
grep -i "hostname.*Switch" *.txt               # Check default hostnames
grep -E "% (Invalid|Ambiguous)" *.txt          # Find command errors
```

## Script Customization

### Adding Commands
Edit the `commands` arrays in the script:
```bash
# For switches, find the switch command set around line 140
# For routers, find the router command set around line 165
```

### Adjusting Timeouts
Modify the timeout value for slower devices:
```bash
set timeout 60  # Increase from default 30 seconds
```

### Serial Port Settings
Default stty settings work for most Cisco devices (9600 8N1). If needed, configure stty vic. line 104
```bash
```

## License

- **Code**: [GPL-3.0-or-later](https://www.gnu.org/licenses/gpl-3.0.en.html)
- **Notes & Documentation**: [CC BY-SA-NC 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)

See [LICENSE](./LICENSE) and [LICENSE_POLICY.md](./LICENSE_POLICY.md) for details.

## Contributing

Feel free to submit improvements, especially for handling additional device types or boot scenarios.

## Version History

- v0.0.1 - Initial code with basic switch/router support - non-functional
- v0.0.2 - Added device type validation and improved error handling
- v0.0.3 - Added enable password handling, improved logging, enhanced error recovery, and command-level timestamps
- v0.0.4 - extensive rewrite to fix various bugs, replace minicom with direct serial connection and an `enter_enable` procedure
- v0.0.4 - debugging of `enter_enable` procedure, making it functional by adding flexibility and debugging messages.
- v0.0.5 - cleanup for release
- v0.1.0 - MVP 1 

## Planned features and fixes 
- Boot sequence logging - current logging misses boot sequence even though the script is actively attempting to get a command prompt and elevate privileges.
- Timeout handling - The script handles timeouts well, but needs a global timeout counter to prevent infinite loops in pathological cases where a device never responds properly.
- Error recovery - The script handles "Invalid input" errors well, but if a device gets stuck in a configuration dialog or similar state, there's no mechanism to break out and retry.
- Cleanup of this README.md 
- Additional testing

