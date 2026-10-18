#!/bin/bash

# ANSI color codes
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
NC=$'\e[0m' # No Color/Default

usage() {
    printf '%b\n' \
"Usage: ocp_connect.sh [option]

How to use:
${YELLOW}  ***Execute script from local console***${NC}
  Connect the debug card to your computer via USB or Bluetooth.
  Open iTerm2 (download if not installed) and navigate to the directory where the script is located.
  Run './ocp_connect.sh'. If permission denied, run 'chmod +x ocp_connect.sh' first.

Tips:
  From the info I was able to find, the most common baud rates are: 9600, 57600, and 115200. Those are your options.
  If you have trouble, try switching between those baud rates.
  I suggest creating an alias for this script in your .bashrc or .zshrc file. (I use 'ocp')
  If you do not end the screen session as instructed, you may need to execute 'screen -ls' then 'kill' <screen session id>
  USB connection is more reliable than Bluetooth.

Troubleshooting:
  Ensure that the debug card is connected.
  Unplug and re-plug the debug card and USB cable.
  Run 'ls /dev/tty.usbserial-*' or 'ls /dev/tty.RNBT-*' to check for the device presence.
  If issues persist, try running the script with sudo.

Options:
  -h, --help   Show this help screen and exits.
"
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
    printf '\n%b\n' "${RED}User exited script with 'Ctrl+C'...${NC}"
    exit 1
}
trap ctrl_c SIGINT

# Check if 'screen' command is installed, try to install if not
check_for_screen_command() {
    if ! command -v screen &> /dev/null; then
        printf '%b\n' "${YELLOW}Screen is not installed. Attempting to install with Homebrew...${NC}"
        if ! command -v brew &> /dev/null; then
            printf '%b\n' "${RED}Homebrew is not installed. Please install Homebrew first:${NC} https://brew.sh/"
            exit 1
        else
            printf '%b\n' "${GREEN}Homebrew is installed.${NC}"
        fi

        printf '%b\n' "${YELLOW}Running 'brew update' to ensure Homebrew is up to date...${NC}"
        if ! brew update; then
            printf '%b\n' "${RED}Failed to update Homebrew. Please check your Homebrew installation.${NC}"
            exit 1
        else
            printf '%b\n' "${GREEN}Homebrew updated successfully.${NC}"
        fi

        if ! brew install screen; then
            printf '%b\n' "${RED}Failed to install 'screen' with 'brew install screen'. Please install it manually and try again.${NC}"
            exit 1
        fi

        sleep 3
        if ! command -v screen &> /dev/null; then
            printf '%b\n' "${RED}Failed to install 'screen'. Please install it manually and try again.${NC}"
            exit 1
        else
            printf '%b\n' "${GREEN}'screen' command installed successfully.${NC}"
        fi
    else
        printf '%b\n' "${GREEN}'Screen' command already installed.${NC}"
    fi
}
# Assign device variable and check that the device exists
assign_device() {
    DEVICE=$(ls /dev/tty.usbserial-* 2>/dev/null | head -n 1)
    if [[ -z "$DEVICE" ]]; then
        DEVICE=$(ls /dev/tty.RNBT-* 2>/dev/null | head -n 1)
    fi
    if [[ -z "$DEVICE" ]]; then
        printf '%b\n' "${RED}Serial device not found. Please ensure that the debug card is connected via USB or Bluetooth.${NC}"
        exit 1
    else
        printf '%b\n' "${GREEN}Device found:${NC} $DEVICE"
    fi
}

assign_baud_rate() {
    local -a BAUD_RATE_OPTIONS=(9600 57600 115200)
    while true; do
        printf '%b\n' "${BLUE}Select a baud rate from the menu below:${NC}"
        printf '%s\n' "  1) 9600"
        printf '%s\n' "  2) 57600 (most common)"
        printf '%s\n' "  3) 115200"
        printf '%s\n' "  4) Custom baud rate if needed"
        printf '%b' "${BLUE}Enter choice [1-4]:${NC}"
        read -n 1 choice
        echo ""
        case "$choice" in
            1) BAUD_RATE=${BAUD_RATE_OPTIONS[0]}; break ;;
            2) BAUD_RATE=${BAUD_RATE_OPTIONS[1]}; break ;;
            3) BAUD_RATE=${BAUD_RATE_OPTIONS[2]}; break ;;
            4) read -r -p "${BLUE}Enter custom baud rate:${NC}" BAUD_RATE
                if [[ $BAUD_RATE =~ ^[0-9]+$ ]]; then
                    if (($BAUD_RATE > 0)); then
                        if (($BAUD_RATE <= 115200)); then
                            break
                        else
                            printf '%b\n' "${YELLOW}c'mon mane be fr ${NC}"
                        fi
                    else
                        printf '%b\n' "${YELLOW}baud rate must be greater than zero${NC}"
                    fi
                else
                    printf '%b\n' "${YELLOW}Invalid baud rate. Custom baud rate must be a positive integer.${NC}"
                fi
                ;;
            *)
                printf '%b\n' "${RED}Invalid selection. Choose from options in menu.${NC}"
                ;;
        esac
    done
}

prepare_screen_session() {
    local USERNAME="$USER"
    if [ ${#USERNAME} -gt 32 ]; then
        USERNAME="${USERNAME:0:30}.."
    fi
    printf '%b\n' "${YELLOW}Ensure that you have selected the correct host with the debug card.${NC}"
    printf '%b\n' "${YELLOW}To end the screen session, press 'Ctrl+A' then enter ':quit'${NC}"
    read -r -p "Press 'enter' to start the screen session.."
    printf '\n'
    # Print the box / 40 characters in between pipes.
    printf '%s\n' "+----------------------------------------+"
    printf '%s\n' "|------------ SCREEN SESSION ------------|"
    printf '%s\n' "+----------------------------------------+"
    printf "| User: %-32s |\n" "$USERNAME"
    printf "| Device: %-30s |\n" "$DEVICE"
    printf "| Baud Rate: %-27s |\n" "$BAUD_RATE"
    printf '%s\n\n' "+----------------------------------------+"
    sleep 1.5
}

start_screen_session() {
    screen "$DEVICE" "$BAUD_RATE"
    local return_code=$?
    if [[ $return_code -ne 0 ]]; then
        printf '%b\n' "${RED}Screen session exited with error code: ${return_code}${NC}"
    fi
}

main() {
    check_for_screen_command
    assign_device
    assign_baud_rate
    prepare_screen_session
    start_screen_session
}

main