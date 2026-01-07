#!/bin/bash

# verison 1.1

# ANSI color codes
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
NC=$'\e[0m' # No Color/Default

usage() {
    echo "Usage: ocp_connect.sh [option]"
    echo
    echo "How to use:"
    echo "  Execute script from local console."
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
    echo "  Unplug and re-plug the debug card and USB cable."
    echo "  Run 'ls /dev/tty.usbserial-*' or 'ls /dev/tty.RNBT-*' to check for the device presence."
    echo "  If issues persist, try running the script with sudo."
    echo
    echo "Options:"
    echo "  -h, --help   Show this help screen and exits."
}

if [[ $# -gt 0 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    else
        echo "${RED}'$1' is not a valid option.${NC}"
        exit 1
    fi
fi

ctrl_c() {
    echo -e "${RED}\nUser exited script with 'Ctrl+C'...${NC}"
    exit 1
}
trap ctrl_c SIGINT
# Check if screen is installed, try to install if not
check_screen_command () {
    if ! command -v screen &> /dev/null; then
        echo "${YELLOW}Screen is not installed. Attempting to install with Homebrew...${NC}"
        if ! command -v brew &> /dev/null; then
            echo "${RED}Homebrew is not installed. Please install Homebrew first:${NC} https://brew.sh/"
            exit 1
        else
            echo "${GREEN}Homebrew is installed.${NC}"
        fi

        echo "${YELLOW}Running 'brew update' to ensure Homebrew is up to date...${NC}"
        if ! brew update; then
            echo "${RED}Failed to update Homebrew. Please check your Homebrew installation.${NC}"
            exit 1
        else
            echo "${GREEN}Homebrew updated successfully.${NC}"
        fi

        if ! brew install screen; then
            echo "${RED}Failed to install 'screen' with 'brew install screen'. Please install it manually and try again.${NC}"
            exit 1
        fi

        sleep 3
        if ! command -v screen &> /dev/null; then
            echo "${RED}Failed to install 'screen'. Please install it manually and try again.${NC}"
            exit 1
        else
            echo "${GREEN}'screen' installed successfully.${NC}"
        fi
    else
        echo "${GREEN}'Screen' already installed.${NC}"
    fi
}
# Assign device variable and check that the device exists
assign_device() {
    DEVICE=$(ls /dev/tty.usbserial-* 2>/dev/null | head -n 1)
    if [[ -z "$DEVICE" ]]; then
        DEVICE=$(ls /dev/tty.RNBT-* 2>/dev/null | head -n 1)
    fi
    if [[ -z "$DEVICE" ]]; then
        echo "${RED}Serial device not found. Please ensure that the debug card is connected via USB or Bluetooth.${NC}"
        exit 1
    else
        echo "${GREEN}Device found:${NC} $DEVICE"
    fi
}

assign_baud_rate() {
    BAUD_RATE_OPTIONS=(9600 57600 115200)
    while true; do
        echo "${BLUE}Select a baud rate from the menu below:${NC}"
        echo "  1) 9600"
        echo "  2) 57600 (most common)"
        echo "  3) 115200"
        echo "  4) Custom baud rate if needed"
        echo -n "${BLUE}Enter choice [1-4]:${NC}"
        read -n 1 choice
        echo ""
        case "$choice" in
            1) BAUD_RATE=${BAUD_RATE_OPTIONS[0]}; break ;;
            2) BAUD_RATE=${BAUD_RATE_OPTIONS[1]}; break ;;
            3) BAUD_RATE=${BAUD_RATE_OPTIONS[2]}; break ;;
            4) read -p "${BLUE}Enter custom baud rate:${NC}" BAUD_RATE
                if [[ $BAUD_RATE =~ ^[0-9]+$ ]]; then
                    break
                else
                    echo "${YELLOW}Invalid baud rate. Custom baud rate must be a positive integer.${NC}"
                fi
                ;;
            *)
                echo "${RED}Invalid selection. Choose from options in menu.${NC}"
                ;;
        esac
    done
}

prepare_screen_session() {
    echo "${BLUE}Ensure that you have selected the correct host."
    echo "To end the screen session, press 'Ctrl+A' then enter ':quit'"
    read -r -p "Press 'enter' to start the screen session..${NC}"
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

start_screen_session() {
    screen "$DEVICE" "$BAUD_RATE" || echo "${RED}An error occurred when starting the screen session:${NC} $?"
}

main () {
    check_screen_command
    assign_device
    assign_baud_rate
    prepare_screen_session
    start_screen_session
}

main
