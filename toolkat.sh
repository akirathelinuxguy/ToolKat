#!/bin/bash
set -euo pipefail
normal=$(printf '\033[0m')
yellow=$(printf '\033[33m')
green=$(printf '\033[32m')
red=$(printf '\033[31m')
blue=$(printf '\033[34m')

logCheck(){
    if [ -f "/var/log/toolkat.log" ];then
        :
    else
        echo > /var/log/toolkat.log
        echo "Logfile Has been created"
    fi
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Error: must run as root"
    exit 1
  fi
}

LinDistro(){
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      echo "$PRETTY_NAME"
    else
      uname -s
    fi
}

detect_package_manager(){
    if command -v xbps-install &> /dev/null; then
        echo "xbps"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt &> /dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

base_Info(){
    local user=$(id -un)
    local up=$(uptime -p | cut -c4-)
    local disk=$(df -h / | awk 'NR==2 {print "Storage: " $3 "/" $2 " ("$5")"}')
    local term_em=$(echo $TERM)
    local sh=$(basename "$SHELL")
    local krnl=$(uname -r)
    cat << EOF
Hello $user
Distro: $(LinDistro)
Kernel: $krnl
Terminal: $term_em
Shell: $sh
$disk
Up for: $up
EOF
}

log_Analyzer(){
    grep -RniI -E "error|failed|exception|fatal" /var/log/
}

# NEW: Performance Monitoring
performance_Monitor(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    
    case "${NAME:-overview}" in
        overview|"")
            echo "${blue}=== SYSTEM PERFORMANCE OVERVIEW ===${normal}"
            echo
            
            # CPU Info
            echo "${yellow}[CPU Information]${normal}"
            echo "Model: $(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2 | xargs)"
            echo "Cores: $(nproc)"
            echo "Load Average: $(uptime | awk -F'load average:' '{print $2}' | xargs)"
            echo
            
            # Memory Usage
            echo "${yellow}[Memory Usage]${normal}"
            free -h | awk 'NR==1 {print $0} NR==2 {printf "Used: %s/%s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
            echo
            
            # Top 5 Processes by CPU
            echo "${yellow}[Top 5 Processes by CPU]${normal}"
            ps aux --sort=-%cpu | awk 'NR==1 {print $0} NR>1 && NR<=6 {print $0}' | column -t
            echo
            
            # Top 5 Processes by Memory
            echo "${yellow}[Top 5 Processes by Memory]${normal}"
            ps aux --sort=-%mem | awk 'NR==1 {print $0} NR>1 && NR<=6 {print $0}' | column -t
            echo
            
            # Disk I/O (if iostat available)
            if command -v iostat &> /dev/null; then
                echo "${yellow}[Disk I/O Statistics]${normal}"
                iostat -dx 1 1 | tail -n +4
                echo
            fi
            
            echo "$dateStamp | INFO: Performance overview requested" >> /var/log/toolkat.log
        ;;
        
        cpu)
            echo "${blue}=== CPU DETAILS ===${normal}"
            echo
            echo "${yellow}[CPU Information]${normal}"
            lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket|MHz"
            echo
            echo "${yellow}[CPU Usage per Core]${normal}"
            mpstat -P ALL 1 1 2>/dev/null || echo "mpstat not available (install sysstat package)"
            echo
            echo "$dateStamp | INFO: CPU details requested" >> /var/log/toolkat.log
        ;;
        
        memory|mem)
            echo "${blue}=== MEMORY DETAILS ===${normal}"
            echo
            echo "${yellow}[Memory Usage]${normal}"
            free -h
            echo
            echo "${yellow}[Memory Info]${normal}"
            cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree"
            echo
            echo "$dateStamp | INFO: Memory details requested" >> /var/log/toolkat.log
        ;;
        
        disk)
            echo "${blue}=== DISK DETAILS ===${normal}"
            echo
            echo "${yellow}[Disk Usage]${normal}"
            df -h | grep -E "Filesystem|^/dev/"
            echo
            echo "${yellow}[Disk I/O]${normal}"
            if command -v iostat &> /dev/null; then
                iostat -x 1 2
            else
                echo "iostat not available (install sysstat package)"
            fi
            echo
            echo "$dateStamp | INFO: Disk details requested" >> /var/log/toolkat.log
        ;;
        
        processes|proc)
            echo "${blue}=== PROCESS DETAILS ===${normal}"
            echo
            echo "${yellow}[Top 10 Processes by CPU]${normal}"
            ps aux --sort=-%cpu | head -n 11 | column -t
            echo
            echo "${yellow}[Top 10 Processes by Memory]${normal}"
            ps aux --sort=-%mem | head -n 11 | column -t
            echo
            echo "${yellow}[Process Count]${normal}"
            echo "Running: $(ps aux | wc -l)"
            echo "Zombie: $(ps aux | awk '$8=="Z" {print $0}' | wc -l)"
            echo
            echo "$dateStamp | INFO: Process details requested" >> /var/log/toolkat.log
        ;;
        
        temp)
            echo "${blue}=== TEMPERATURE SENSORS ===${normal}"
            echo
            if command -v sensors &> /dev/null; then
                sensors
            else
                echo "lm-sensors not installed"
                echo "Install with: sudo apt install lm-sensors (Debian/Ubuntu)"
                echo "            : sudo pacman -S lm_sensors (Arch)"
                echo "            : sudo xbps-install -S lm_sensors (Void)"
            fi
            echo
            echo "$dateStamp | INFO: Temperature check requested" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown performance option: $NAME"
            echo "Available: overview, cpu, memory, disk, processes, temp"
            echo "Usage: --perf [option]"
        ;;
    esac
}

# NEW: Package Management
package_Manager(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    local pkg_mgr=$(detect_package_manager)
    
    if [[ "$pkg_mgr" == "unknown" ]]; then
        echo "${red}Error: No supported package manager found (xbps, pacman, or apt)${normal}"
        exit 1
    fi
    
    echo "${green}Detected package manager: $pkg_mgr${normal}"
    echo
    
    case "$NAME" in
        update)
            require_root
            echo "${blue}=== UPDATING PACKAGE DATABASE ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-install -S
                    echo "${green}Package database updated${normal}"
                ;;
                pacman)
                    pacman -Sy
                    echo "${green}Package database updated${normal}"
                ;;
                apt)
                    apt update
                    echo "${green}Package database updated${normal}"
                ;;
            esac
            echo "$dateStamp | INFO: Package database updated ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        upgrade)
            require_root
            echo "${blue}=== UPGRADING PACKAGES ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-install -Su
                ;;
                pacman)
                    pacman -Syu
                ;;
                apt)
                    apt upgrade
                ;;
            esac
            echo "$dateStamp | INFO: Packages upgraded ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        install)
            require_root
            if [ -z "$Extra" ]; then
                echo "${red}Error: You must provide a package name.${normal}"
                exit 1
            fi
            echo "${blue}=== INSTALLING PACKAGE: $Extra ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-install -S "$Extra"
                ;;
                pacman)
                    pacman -S "$Extra"
                ;;
                apt)
                    apt install "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Package $Extra installed ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        remove)
            require_root
            if [ -z "$Extra" ]; then
                echo "${red}Error: You must provide a package name.${normal}"
                exit 1
            fi
            echo "${blue}=== REMOVING PACKAGE: $Extra ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-remove "$Extra"
                ;;
                pacman)
                    pacman -R "$Extra"
                ;;
                apt)
                    apt remove "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Package $Extra removed ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        search)
            if [ -z "$Extra" ]; then
                echo "${red}Error: You must provide a search term.${normal}"
                exit 1
            fi
            echo "${blue}=== SEARCHING FOR: $Extra ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-query -Rs "$Extra"
                ;;
                pacman)
                    pacman -Ss "$Extra"
                ;;
                apt)
                    apt search "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Searched for package $Extra ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        info)
            if [ -z "$Extra" ]; then
                echo "${red}Error: You must provide a package name.${normal}"
                exit 1
            fi
            echo "${blue}=== PACKAGE INFO: $Extra ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-query -R "$Extra"
                ;;
                pacman)
                    pacman -Si "$Extra"
                ;;
                apt)
                    apt show "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Package info requested for $Extra ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        list)
            echo "${blue}=== INSTALLED PACKAGES ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    if [ -z "$Extra" ]; then
                        xbps-query -l | wc -l
                        echo "packages installed. Use --pkg list <name> to filter"
                    else
                        xbps-query -l | grep -i "$Extra"
                    fi
                ;;
                pacman)
                    if [ -z "$Extra" ]; then
                        pacman -Q | wc -l
                        echo "packages installed. Use --pkg list <name> to filter"
                    else
                        pacman -Q | grep -i "$Extra"
                    fi
                ;;
                apt)
                    if [ -z "$Extra" ]; then
                        dpkg -l | grep "^ii" | wc -l
                        echo "packages installed. Use --pkg list <name> to filter"
                    else
                        dpkg -l | grep "^ii" | grep -i "$Extra"
                    fi
                ;;
            esac
            echo "$dateStamp | INFO: Package list requested ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        clean)
            require_root
            echo "${blue}=== CLEANING PACKAGE CACHE ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-remove -O
                    xbps-remove -o
                    echo "${green}Cache cleaned${normal}"
                ;;
                pacman)
                    pacman -Sc
                    echo "${green}Cache cleaned${normal}"
                ;;
                apt)
                    apt autoclean
                    apt autoremove
                    echo "${green}Cache cleaned${normal}"
                ;;
            esac
            echo "$dateStamp | INFO: Package cache cleaned ($pkg_mgr)" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "${red}Unknown package option: $NAME${normal}"
            cat << EOF
${yellow}Available commands:${normal}
  update     - Update package database
  upgrade    - Upgrade all packages
  install    - Install a package
  remove     - Remove a package
  search     - Search for packages
  info       - Show package information
  list       - List installed packages
  clean      - Clean package cache

${yellow}Usage:${normal}
  --pkg update
  --pkg upgrade
  --pkg install <package>
  --pkg remove <package>
  --pkg search <term>
  --pkg info <package>
  --pkg list [filter]
  --pkg clean
EOF
        ;;
    esac
}

User_Management_Helper(){
logCheck
local dateStamp=$(date +%F"|"%r)
case "$NAME" in
    create)
        require_root
            if [ -z "$Extra" ]; then
              echo "Error: You must provide a name."
              exit 1
            else
                if grep -q "^${Extra}:" "/etc/passwd"; then
                    echo "User Already Exists"
                    echo "$dateStamp | ERROR: while trying to create user $Extra User already exist" >> /var/log/toolkat.log
                    exit 1
                else
                    useradd -m "$Extra"
                    passwd "$Extra"
                    echo "user $Extra has been created"
                    echo "$dateStamp | INFO: user $Extra has been created" >> /var/log/toolkat.log
            fi
        fi
    ;;
    delete)
        user=$(id -un)
        require_root
            if [ -z "$Extra" ]; then
              echo "Error: You must provide a name."
              exit 1
            elif [[ $Extra == "root" || $Extra == $user  ]]; then
                echo "You cannot delete Root or own user"
                echo "$dateStamp | WARNING: Attempt to delete user or root " >> /var/log/toolkat.log
                exit 1
            else
                if grep -q "^${Extra}:" "/etc/passwd"; then
                    userdel -r "$Extra"
                    echo "User $Extra has been deleted"
                    echo "$dateStamp | INFO: user $Extra has been deleted. " >> /var/log/toolkat.log
                else
                    echo "$Extra isnt an existing user."
                    echo "$dateStamp | ERROR: tried deleting unexisting user called $Extra." >> /var/log/toolkat.log
            fi
        fi
    ;;
    lock)
        require_root
            if [ -z "$Extra" ]; then
              echo "Error: You must provide a name."
              exit 1
            else
                if grep -q "^${Extra}:" "/etc/passwd"; then
                    if grep -q "^${Extra}:!" /etc/shadow; then
                        echo "User $Extra is already locked"
                        echo "$dateStamp | ERROR: tried locking $Extra but was already locked. " >> /var/log/toolkat.log
                    else
                        usermod -L "$Extra"
                        echo "User $Extra has been locked"
                        echo "$dateStamp | INFO: user $Extra has been locked. " >> /var/log/toolkat.log
                    fi
                else
                    echo "$Extra isnt an existing user."
                    echo "$dateStamp | ERROR: tried locking unexisting user called $Extra." >> /var/log/toolkat.log
        fi
        fi
    ;;
    unlock)
        require_root
            if [ -z "$Extra" ]; then
              echo "Error: You must provide a name."
              exit 1
            else
                if grep -q "^${Extra}:" "/etc/passwd"; then
                    if grep -q "^${Extra}:!" /etc/shadow; then
                        usermod -U "$Extra"
                        echo "User $Extra has been unlocked"
                        echo "$dateStamp | INFO: user $Extra has been unlocked. " >> /var/log/toolkat.log
                    else
                        echo "User $Extra is already unlocked"
                        echo "$dateStamp | ERROR: tried unlocking $Extra while already being unlocked. " >> /var/log/toolkat.log
                   fi

                else
                    echo "$Extra isnt an existing user."
                    echo "$dateStamp | ERROR: tried unlocking unexisting user called $Extra." >> /var/log/toolkat.log
        fi
    fi
    ;;
    list)
        if [ -z "$Extra" ]; then
          echo "User|UID|HomeDir|Shell"
          echo
          awk -F':' '{ print $1"|" $3"|" $6"|"$7}' /etc/passwd | column -t -s '|'
          echo "$dateStamp | INFO: List of users has been asked" >> /var/log/toolkat.log
        else
            echo "User|UID|HomeDir|Shell"
            echo
            awk -F':' '{ print $1"|" $3"|" $6"|"$7}' /etc/passwd | column -t -s '|' | grep $Extra
            echo "$dateStamp | INFO: the user $Extra has been located." >> /var/log/toolkat.log
        fi
    ;;

    *)
       echo "--help for commands"
esac
}

Info(){
cat << EOF
${yellow}
    ^~^  ,
   ('Y') )
   /   \/
  (\|||/) ${normal}
--Commands--

${green}Basic:${normal}
--b       Base info
--la      Log analyzer

${green}User Management (requires root):${normal}
--umh     User management helper
  create <user>     Create a user
  delete <user>     Delete a user
  lock <user>       Lock a user
  unlock <user>     Unlock a user
  list [user]       List all users or search for specific user

${green}Performance Monitoring:${normal}
--perf    Performance monitoring
  overview          System performance overview (default)
  cpu               Detailed CPU information
  memory            Detailed memory information
  disk              Detailed disk I/O statistics
  processes         Detailed process information
  temp              Temperature sensors

${green}Package Management (requires root for most):${normal}
--pkg     Package manager (auto-detects xbps/pacman/apt)
  update            Update package database
  upgrade           Upgrade all packages
  install <pkg>     Install a package
  remove <pkg>      Remove a package
  search <term>     Search for packages
  info <pkg>        Show package information
  list [filter]     List installed packages
  clean             Clean package cache

--help    Show this help interface

${yellow}Examples:${normal}
  sudo toolkat.sh --umh create john
  toolkat.sh --perf cpu
  sudo toolkat.sh --pkg install htop
  toolkat.sh --pkg search firefox
EOF
}

case "${1:-}" in
    --b)
       base_Info
    ;;
    --la)
       log_Analyzer
    ;;
    --umh)
      NAME="${2:-}"
      Extra="${3:-}"
      User_Management_Helper
    ;;
    --perf)
      NAME="${2:-}"
      Extra="${3:-}"
      performance_Monitor
    ;;
    --pkg)
      NAME="${2:-}"
      Extra="${3:-}"
      package_Manager
    ;;
    --help|"")
      Info
    ;;
    *)
       echo "Unknown command: $1"
       echo "Use --help for available commands"
       exit 1
esac
