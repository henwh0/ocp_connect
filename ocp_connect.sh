#!/bin/sh

usage() {
    echo "Usage: ocp_connect.sh"
    echo "  Script will connect to the first serial device that matches '/dev/tty.usbserial-*' if connected via USB."
    echo "  If device is connected via Bluetooth, it will be '/dev/tty.RNBT-*'"
    echo "  Script prompts user to select a baud rate from a menu."
    echo "  Script will then start a screen session with the serial device and baud rate. Useful for minimum configurations."
    echo "  You can exit the script before the screen session starts by pressing 'Ctrl + C'."
    echo
    echo "How to use:"
    echo "  Connect the debug card to your computer via USB or Bluetooth."
    echo "  Open iTerm2 (download if not installed) and navigate to the directory where the script is located."
    echo "  Run './ocp_connect.sh'. If permission denied, run 'chmod +x ocp_connect.sh' first."
    echo
    echo "Tips:"
    echo "  From the info I was able to find, the most common baud rates are: 9600, 57600, and 115200. Those are your options."
    echo "  If you have trouble, try switching between those baud rates."
    echo "  I suggest creating an alias for this script in your .bashrc or .zshrc file. (I use 'ocp')"
    echo "  If you do not end the screen session as instructed, you may need to execute 'screen -ls' then 'kill' <screen session id>"
    echo
    echo "Troubleshooting:"
    echo "  Ensure that the debug card is connected."
    echo "  Run 'ls /dev/tty.usbserial-*' or 'ls /dev/tty.RNBT-*' to check for the device presence."
    echo "  Unplug and re-plug the debug card and USB cable."
    echo "  If 'screen' is not found, install via homebrew: 'brew install screen'"
    echo "  If issues persist, try running the script with sudo. If that doesn't work, feel free to ping Henry McGinnis on workchat."
    echo
    echo "Options:"
    echo "  -h, --help   Show this help screen and exits."
}

# Show help if -h or --help is passed
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    else
        echo "'$1' is not a valid option."
        exit 1
    fi
fi

# Trap if 'Ctrl + C' is pressed
ctrl_c() {
    echo -e "\nUser exited script with 'Ctrl + C'..."
    exit 1
}
trap ctrl_c INT

# Check if "screen" is installed
if ! command -v screen &> /dev/null; then
    echo "Screen is not installed. Please install it and try again."
    exit 1
fi

echo "Execute script with '-h' or '--help' for more information."

# Assign device variable and check that the device exists
assign_device() {
    DEVICE=$(ls /dev/tty.usbserial-* 2>/dev/null | head -n 1)
    if [[ -z "$DEVICE" ]]; then
        DEVICE=$(ls /dev/tty.RNBT-* 2>/dev/null | head -n 1)
    fi
    if [[ -z "$DEVICE" ]]; then
        echo "Serial device not found. Please ensure that the debug card is connected via USB or Bluetooth."
        exit 1
    fi
}
# Baud rate selection
assign_baud_rate() {
    BAUD_RATE_OPTIONS=(9600 57600 115200)
    while true; do
        echo "Connected to device: $DEVICE"
        echo "Select a baud rate from the menu below:"
        echo "  1) 9600"
        echo "  2) 57600 (most common)"
        echo "  3) 115200"
        echo -n "Enter choice [1-3]: "
        read -n 1 choice
        echo ""
        case "$choice" in
            1) BAUD_RATE=${BAUD_RATE_OPTIONS[0]}; break ;;
            2) BAUD_RATE=${BAUD_RATE_OPTIONS[1]}; break ;;
            3) BAUD_RATE=${BAUD_RATE_OPTIONS[2]}; break ;;
            *)
                echo "Invalid selection. Choose from options in menu."
                ;;
        esac
    done
}

# Prepare to start screen session
prepare_screen_session() {
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
}

# Starting the screen session
start_screen_session() {
    screen "$DEVICE" "$BAUD_RATE" || echo "An error occurred when starting the screen session: $?"
}

main () {
    assign_device
    assign_baud_rate
    prepare_screen_session
    start_screen_session
}
main
# Henry McGinnis (FRC)
# If you do not end the screen session as instructed, you may need to execute "Screen -ls" then "kill" whatever the screen number is.
