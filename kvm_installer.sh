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
    echo -e " [3] Exit"
    echo ""
    read -p "Enter choice [1-3]: " choice

    case $choice in
        1) start_conversion ;;
        2) check_status ;;
        3) exit 0 ;;
        *) echo -e "${RED}Invalid option! Exiting.${NC}"; exit 1 ;;
    esac
}

start_conversion() {
    clear
    show_credits
    echo -e "${GREEN}[+] Starting Configuration Setup...${NC}\n"

    # Inputs from user
    read -p "Enter Host Name: " HOST_NAME
    read -p "Enter RAM Memory in MB (e.g., 2048): " RAM_SIZE
    read -p "Enter Disk Size in GB (e.g., 20): " DISK_SIZE
    read -p "Enter CPU Cores (e.g., 2): " CPU_CORES

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

    echo -e "${GREEN}[2/4] Creating ${DISK_SIZE}GB Virtual Hard Disk...${NC}"
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

    echo -e "${GREEN}[4/4] Starting KVM Virtual Machine in Background (Screen)...${NC}"
    
    # Check if hardware acceleration /dev/kvm is available; fallback to software emulation
    KVM_ACCEL=""
    if [ -c /dev/kvm ]; then
        KVM_ACCEL="-enable-kvm"
        echo -e "${GREEN}[INFO] /dev/kvm detected! Using hardware acceleration.${NC}"
    else
        echo -e "${YELLOW}[WARNING] /dev/kvm not found (Container environment). Falling back to software QEMU emulation.${NC}"
    fi

    # Kill existing session if running
    screen -S kvm_vm -X quit > /dev/null 2>&1

    # Launch QEMU inside a detached screen session so it runs continuously
    screen -dmS kvm_vm qemu-system-x86_64 \
        $KVM_ACCEL \
        -name "$HOST_NAME" \
        -m "${RAM_SIZE}M" \
        -smp "$CPU_CORES" \
        -hda ubuntu_disk.qcow2 \
        -cdrom ubuntu-22.04.iso \
        -boot d \
        -net nic -net user,hostfwd=tcp::2222-:22 \
        -nographic

    echo -e "\n${GREEN}====================================================${NC}"
    echo -e "${GREEN} SUCCESS: Ubuntu 22.04 KVM VM is now running!${NC}"
    echo -e "${YELLOW} Connection Info:${NC}"
    echo -e "   - SSH Forwarded Port : 2222 (Connect using: ssh -p 2222 user@your-vps-ip)"
    echo -e "   - Manage Background Process: 'screen -r kvm_vm'"
    echo -e "${GREEN}====================================================${NC}"
}

check_status() {
    clear
    show_credits
    if screen -list | grep -q "kvm_vm"; then
        echo -e "${GREEN}[STATUS] Your KVM Virtual Machine is currently RUNNING.${NC}"
        echo -e "Type 'screen -r kvm_vm' to attach to the VM terminal."
    else
        echo -e "${RED}[STATUS] No active VM screen session found.${NC}"
    fi
}

# Run Menu
show_menu
