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
    read -p "Enter RAM Memory in MB [default: 1024]: " RAM_SIZE < /dev/tty
    read -p "Enter Disk Size in GB [default: 10]: " DISK_SIZE < /dev/tty
    read -p "Enter CPU Cores [default: 1]: " CPU_CORES < /dev/tty

    # Set conservative defaults to prevent memory limits in containers
    HOST_NAME=${HOST_NAME:-ubuntu-kvm}
    RAM_SIZE=${RAM_SIZE:-1024}
    DISK_SIZE=${DISK_SIZE:-10}
    CPU_CORES=${CPU_CORES:-1}

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

    echo -e "${GREEN}[4/4] Starting Virtual Machine Engine...${NC}"
    
    # Configure acceleration mode
    ACCEL_ARGS="-machine type=pc,accel=tcg -cpu qemu64"
    if [ -c /dev/kvm ]; then
        ACCEL_ARGS="-enable-kvm -cpu host"
        echo -e "${GREEN}[INFO] /dev/kvm detected! Using KVM Hardware Acceleration.${NC}"
    else
        echo -e "${YELLOW}[WARNING] /dev/kvm not found. Using TCG Software Emulation Mode.${NC}"
    fi

    # Kill existing session if running
    screen -S kvm_vm -X quit > /dev/null 2>&1

    # Launch QEMU with guaranteed container compatibility
    screen -dmS kvm_vm qemu-system-x86_64 \
        $ACCEL_ARGS \
        -name "$HOST_NAME" \
        -m "${RAM_SIZE}M" \
        -smp "$CPU_CORES" \
        -hda ubuntu_disk.qcow2 \
        -cdrom ubuntu-22.04.iso \
        -boot d \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -nographic \
        -serial mon:stdio

    sleep 3

    # Verify container process status
    if screen -list | grep -q "kvm_vm"; then
        echo -e "\n${GREEN}====================================================${NC}"
        echo -e "${GREEN} SUCCESS: Ubuntu 22.04 VM is now active!${NC}"
        echo -e "${YELLOW} Connection & Control:${NC}"
        echo -e "   - Connect to Installer Console : screen -r kvm_vm"
        echo -e "   - Exit Console without Stopping: Press 'Ctrl + A' then 'D'"
        echo -e "   - SSH Access Port             : 2222 (Post-Installation)"
        echo -e "${GREEN}====================================================${NC}"
    else
        echo -e "\n${RED}[ERROR] VM failed to launch inside screen session.${NC}"
        echo -e "${YELLOW}Run standard direct output to debug container limits:${NC}"
        echo -e "cd ~/kvm_vm && qemu-system-x86_64 -machine type=pc,accel=tcg -m 1024 -hda ubuntu_disk.qcow2 -cdrom ubuntu-22.04.iso -nographic"
    fi
}

check_status() {
    clear
    show_credits
    if screen -list | grep -q "kvm_vm"; then
        echo -e "${GREEN}[STATUS] Virtual Machine is currently RUNNING.${NC}"
        echo -e "Attach to interactive console using: 'screen -r kvm_vm'"
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
