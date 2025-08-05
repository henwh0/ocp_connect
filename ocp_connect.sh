#!/bin/bash
usage() {
    echo
    echo "Usage: ocp_connect.sh [BAUD_RATE]"
    echo "  Script will connect to the first serial device that matches '/dev/tty.usbserial-*' if connected via USB."
    echo "  If device is connected via Bluetooth, it will be /dev/tty.RNBT-*"
    echo "  You can use a custom baud rate by passing it as an argument, (9600-115200), or use the default baud rate of 57600"
    echo "  Script will then start a screen session with the serial device and baud rate. Useful for minimum configurations."
    echo
    echo "Tips:"
    echo "  Suggest creating an alias for this script in your .bashrc or .zshrc file. (I use 'ocp')"
    echo "  If you do not end the screen session as instructed, you may need to execute 'screen -ls' then 'kill' <screen session id>"
    echo "  Script will only accept one argument: [-h / --help] or [BAUD_RATE]"
    echo
    echo "Options:"
    echo "  BAUD_RATE    Optional. Baud rate for the serial connection. (Default is 57600)"
    echo "  -h, --help   Show this help message and exit."
    echo
    echo "Example:"
    echo "  bash ocp_connect.sh 115200 / ocp 115200"
}
# Show help if -h or --help is passed
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# Exit script if more than one argument is passed
if [[ $# -gt 1 ]]; then
    echo
    echo "ERROR: Too many arguments. Only one argument is allowed."
    exit 1
fi

# Trap if 'Ctrl + C' is pressed
ctrl_c() {
    echo -e "\nUser exited script..."
    exit 1
}
trap ctrl_c INT

# Assign variables and check that the device exists
DEVICE=$(ls /dev/tty.usbserial-* 2>/dev/null | head -n 1)
if [[ -z "$DEVICE" ]]; then
    DEVICE=$(ls /dev/tty.RNBT-* 2>/dev/null | head -n 1)
fi
if [[ -z "$DEVICE" ]]; then
    echo "Serial device not found. Please ensure that the debug card is connected via USB or Bluetooth."
    exit 1
fi
BAUD_RATE=57600

# Check if custom baud rate was entered
if [[ $# == 1 ]]; then
    BAUD_RATE=$1
fi
# Check that custom baud rate is a number within range
if ! [[ $BAUD_RATE =~ ^[0-9]+$ ]] || (($BAUD_RATE < 9600 || $BAUD_RATE > 115200)); then
    echo "Baud rate must be a number between 9600 and 115200. Default value is 57600."
    exit 1
fi
# Prepare to start screen session
echo "Ensure that you have selected the correct host."
echo "To end the screen session, press 'Ctrl + A' then enter ':quit'"
read -r -p "Press 'Enter' to start the screen session.."
echo ""
# Print the box / 40 characters in between pipes.
echo "+----------------------------------------+"
echo "|------------ SCREEN SESSION ------------|"
echo "+----------------------------------------+"
printf "| User: %-32s |\n" "$USER"
printf "| Device: %-30s |\n" "$DEVICE"
printf "| Baud Rate: %-27s |\n" "$BAUD_RATE"
echo "+----------------------------------------+"
echo ""
sleep 1.5
# Starting the screen session
screen "$DEVICE" "$BAUD_RATE" || echo "An error occurred when starting the screen session: $?"

# Henry McGinnis (FRC)
# If you do not end the screen session as instructed, you may need to execute "Screen -ls" then "kill" whatever the screen number is.
