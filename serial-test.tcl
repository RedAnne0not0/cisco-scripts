#!/usr/bin/expect -f
# SPDX-License-Identifier: GPL-3.0-or-later


# Serial port connectivity test spike
# Usage: ./check-serial.expect /dev/ttyUSB0 --verbose
# for stand alone use and initial testing, include: echo $? # returns exit code

# check-serial.expect -- verify basic physical layer on serial port

set timeout 2
set verbose 0
set port ""

# Parse args
foreach arg $argv {
    if {$arg eq "--verbose"} {
        set verbose 1
    } elseif {[string match "/dev/*" $arg]} {
        set port $arg
    }
}

if {$port eq ""} {
    puts stderr "Usage: $argv0 /dev/ttyUSB0 [--verbose]"
    exit 1
}

if {$verbose} {
    puts "[timestamp -format %T] Checking serial port $port"
    puts "[timestamp -format %T] Running dd pre-check..."
}

# Run dd-based probe (bypasses expect)
set dd_result [exec sh -c "dd if=$port bs=1 count=10 iflag=nonblock 2>/dev/null | wc -c"]
if {$dd_result > 0} {
    if {$verbose} {
        puts "[timestamp -format %T] dd saw $dd_result bytes — device likely powered"
    }
    exit 0
}

if {$verbose} {
    puts "[timestamp -format %T] No raw bytes via dd; opening port via expect"
}

# Open and configure port
if {[catch {spawn -open [open $port r+]} err]} {
    puts stderr "ERROR: Cannot open $port — $err"
    exit 2
}

fconfigure $spawn_id -mode 9600,n,8,1 -blocking 0 -buffering none -translation binary

if {$verbose} {
    puts "[timestamp -format %T] Port configured; sending probe"
}

send "\r\n"

# Response check
proc check_serial_response {} {
    expect {
        -timeout 1
        -re "." {
            return 1
        }
        timeout {
            return 0
        }
    }
}

if {[check_serial_response]} {
    if {$verbose} {
        puts "[timestamp -format %T] Response received"
    }
    exit 0
} else {
    puts stderr "No response — check cable or power"
    exit 3
}

