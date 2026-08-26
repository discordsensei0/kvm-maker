#!/usr/bin/env bash

# Clear screen and define colors
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_credits() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "${YELLOW}       Start Making Non Kvm TO KVM! ( Ptero Supported )${NC}"
    echo -e "${GREEN}       CREDITS : MrTechEshan Yt Channel${NC}"
    echo -e "${BLUE}====================================================${NC}"
    echo ""
}

show_menu() {
    show_credits
    echo -e "Select an option:"
    echo -e " [1] Convert / Start Ubuntu 22.04 KVM Virtual Machine"
    echo -e " [2] Check Running VM Status"
    echo -e " [3] Stop Active Virtual Machine"
    echo -e " [4] Exit"
    echo ""
    read -p "Enter choice [1-4]: " choice < /dev/tty

    case $choice in
        1) start_conversion ;;
        2) check_status ;;
        3) stop_vm ;;
        4) exit 0 ;;
        *) echo -e "${RED}Invalid option! Exiting.${NC}"; exit 1 ;;
    esac
}

start_conversion() {
    clear
    show_credits
    echo -e "${GREEN}[+] Starting Configuration Setup...${NC}\n"

    # Inputs from user directly from TTY
    read -p "Enter Host Name [default: ubuntu-kvm]: " HOST_NAME < /dev/tty
    read -p "Enter RAM Memory in MB [default: 2048]: " RAM_SIZE < /dev/tty
    read -p "Enter Disk Size in GB [default: 20]: " DISK_SIZE < /dev/tty
    read -p "Enter CPU Cores [default: 2]: " CPU_CORES < /dev/tty

    # Set defaults if empty
    HOST_NAME=${HOST_NAME:-ubuntu-kvm}
    RAM_SIZE=${RAM_SIZE:-2048}
    DISK_SIZE=${DISK_SIZE:-20}
    CPU_CORES=${CPU_CORES:-2}

    echo -e "\n${YELLOW}=== Machine Specs Summary ===${NC}"
    echo -e "Hostname  : $HOST_NAME"
    echo -e "RAM       : ${RAM_SIZE}MB"
    echo -e "Disk      : ${DISK_SIZE}GB"
    echo -e "CPU Cores : $CPU_CORES"
    echo -e "OS        : Ubuntu 22.04 LTS"
    echo -e "=============================\n"

    echo -e "${GREEN}[1/4] Installing Required Dependencies (QEMU & Screen)...${NC}"
    sudo apt-get update -y && sudo apt-get install -y qemu-system-x86 qemu-utils wget screen -y > /dev/null 2>&1

    WORKDIR="$HOME/kvm_vm"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR" || exit

    echo -e "${GREEN}[2/4] Preparing Virtual Hard Disk...${NC}"
    if [ ! -f "ubuntu_disk.qcow2" ]; then
        qemu-img create -f qcow2 ubuntu_disk.qcow2 "${DISK_SIZE}G"
    else
        echo -e "${YELLOW}Disk already exists. Skipping creation.${NC}"
    fi

    echo -e "${GREEN}[3/4] Downloading Ubuntu 22.04 LTS ISO...${NC}"
    ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
    if [ ! -f "ubuntu-22.04.iso" ]; then
        wget -O ubuntu-22.04.iso "$ISO_URL"
    fi

    echo -e "${GREEN}[4/4] Starting KVM Virtual Machine...${NC}"
    
    # Check if hardware acceleration /dev/kvm is available
    KVM_ACCEL=""
    if [ -c /dev/kvm ]; then
        KVM_ACCEL="-enable-kvm"
        echo -e "${GREEN}[INFO] /dev/kvm detected! Hardware acceleration enabled.${NC}"
    else
        echo -e "${YELLOW}[WARNING] /dev/kvm not available. Falling back to container software emulation.${NC}"
    fi

    # Kill existing session if running
    screen -S kvm_vm -X quit > /dev/null 2>&1

    # Launch QEMU inside a detached screen session with working TTY serial console
    screen -dmS kvm_vm qemu-system-x86_64 \
        $KVM_ACCEL \
        -cpu qemu64 \
        -name "$HOST_NAME" \
        -m "${RAM_SIZE}M" \
        -smp "$CPU_CORES" \
        -hda ubuntu_disk.qcow2 \
        -cdrom ubuntu-22.04.iso \
        -boot d \
        -net nic -net user,hostfwd=tcp::2222-:22 \
        -nographic \
        -serial mon:stdio \
        -append "console=ttyS0 quiet"

    sleep 2

    # Check if process survived launch
    if screen -list | grep -q "kvm_vm"; then
        echo -e "\n${GREEN}====================================================${NC}"
        echo -e "${GREEN} SUCCESS: Ubuntu 22.04 KVM VM is running!${NC}"
        echo -e "${YELLOW} Connection Info:${NC}"
        echo -e "   - Open VM Installer : 'screen -r kvm_vm'"
        echo -e "   - Detach from Console: Press 'Ctrl + A' then 'D'"
        echo -e "   - SSH Forwarded Port : 2222 (after setup finishes)"
        echo -e "${GREEN}====================================================${NC}"
    else
        echo -e "\n${RED}[ERROR] VM failed to start inside container background.${NC}"
    fi
}

check_status() {
    clear
    show_credits
    if screen -list | grep -q "kvm_vm"; then
        echo -e "${GREEN}[STATUS] Virtual Machine is currently RUNNING.${NC}"
        echo -e "Attach to console using: 'screen -r kvm_vm'"
    else
        echo -e "${RED}[STATUS] No active VM session detected.${NC}"
    fi
}

stop_vm() {
    clear
    show_credits
    if screen -list | grep -q "kvm_vm"; then
        screen -S kvm_vm -X quit
        echo -e "${YELLOW}[+] Virtual Machine screen session stopped.${NC}"
    else
        echo -e "${RED}[STATUS] No active VM session found to stop.${NC}"
    fi
}

# Run Menu
show_menu
