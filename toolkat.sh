#!/bin/bash
set -euo pipefail

# ToolKat info
TOOLKAT_VERSION="1.0.0"
TOOLKAT_DATE="2026-01-30"

normal=$(printf '\033[0m')
yellow=$(printf '\033[33m')
green=$(printf '\033[32m')
red=$(printf '\033[31m')
blue=$(printf '\033[34m')
cyan=$(printf '\033[36m')
magenta=$(printf '\033[35m')

# Color toggle support
USE_COLOR=true

disable_colors() {
    normal=""
    yellow=""
    green=""
    red=""
    blue=""
    cyan=""
    magenta=""
    USE_COLOR=false
}

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
            free -h | awk 'NR==2 {printf "Total: %s | Used: %s (%.0f%%) | Free: %s | Available: %s\n", $2, $3, ($3/$2)*100, $4, $7}'
            echo
            
            # Top 5 Processes by CPU
            echo "${yellow}[Top 5 Processes by CPU]${normal}"
            printf "%-10s %6s %6s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
            ps aux --sort=-%cpu | awk 'NR>1 && NR<=6 {
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                # Shorten command if too long
                if(length(cmd) > 60) cmd = substr(cmd, 1, 57) "...";
                printf "%-10s %6s %6s %s\n", $1, $3, $4, cmd
            }'
            echo
            
            # Top 5 Processes by Memory
            echo "${yellow}[Top 5 Processes by Memory]${normal}"
            printf "%-10s %6s %6s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
            ps aux --sort=-%mem | awk 'NR>1 && NR<=6 {
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                # Shorten command if too long
                if(length(cmd) > 60) cmd = substr(cmd, 1, 57) "...";
                printf "%-10s %6s %6s %s\n", $1, $3, $4, cmd
            }'
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
            printf "%-10s %6s %6s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
            ps aux --sort=-%cpu | awk 'NR>1 && NR<=11 {
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                if(length(cmd) > 60) cmd = substr(cmd, 1, 57) "...";
                printf "%-10s %6s %6s %s\n", $1, $3, $4, cmd
            }'
            echo
            echo "${yellow}[Top 10 Processes by Memory]${normal}"
            printf "%-10s %6s %6s %s\n" "USER" "%CPU" "%MEM" "COMMAND"
            ps aux --sort=-%mem | awk 'NR>1 && NR<=11 {
                cmd = $11;
                for(i=12; i<=NF; i++) cmd = cmd " " $i;
                if(length(cmd) > 60) cmd = substr(cmd, 1, 57) "...";
                printf "%-10s %6s %6s %s\n", $1, $3, $4, cmd
            }'
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
                ;;
                pacman)
                    pacman -Sy
                ;;
                apt)
                    apt update
                ;;
            esac
            echo "$dateStamp | INFO: Package database updated" >> /var/log/toolkat.log
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
                    apt upgrade -y
                ;;
            esac
            echo "$dateStamp | INFO: System upgraded" >> /var/log/toolkat.log
        ;;
        
        install)
            require_root
            if [ -z "$Extra" ]; then
                echo "Error: You must provide a package name."
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
                    apt install -y "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Package $Extra installed" >> /var/log/toolkat.log
        ;;
        
        remove)
            require_root
            if [ -z "$Extra" ]; then
                echo "Error: You must provide a package name."
                exit 1
            fi
            echo "${blue}=== REMOVING PACKAGE: $Extra ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-remove -R "$Extra"
                ;;
                pacman)
                    pacman -R "$Extra"
                ;;
                apt)
                    apt remove -y "$Extra"
                ;;
            esac
            echo "$dateStamp | INFO: Package $Extra removed" >> /var/log/toolkat.log
        ;;
        
        search)
            if [ -z "$Extra" ]; then
                echo "Error: You must provide a search term."
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
        ;;
        
        info)
            if [ -z "$Extra" ]; then
                echo "Error: You must provide a package name."
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
        ;;
        
        list)
            echo "${blue}=== INSTALLED PACKAGES ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    if [ -z "$Extra" ]; then
                        xbps-query -l
                    else
                        xbps-query -l | grep "$Extra"
                    fi
                ;;
                pacman)
                    if [ -z "$Extra" ]; then
                        pacman -Q
                    else
                        pacman -Q | grep "$Extra"
                    fi
                ;;
                apt)
                    if [ -z "$Extra" ]; then
                        dpkg -l
                    else
                        dpkg -l | grep "$Extra"
                    fi
                ;;
            esac
        ;;
        
        clean)
            require_root
            echo "${blue}=== CLEANING PACKAGE CACHE ===${normal}"
            case "$pkg_mgr" in
                xbps)
                    xbps-remove -O
                ;;
                pacman)
                    pacman -Sc --noconfirm
                ;;
                apt)
                    apt clean && apt autoclean && apt autoremove -y
                ;;
            esac
            echo "$dateStamp | INFO: Package cache cleaned" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown package command: $NAME"
            echo "Available: update, upgrade, install, remove, search, info, list, clean"
            echo "Usage: --pkg [command] [package_name]"
        ;;
    esac
}

# ENHANCED: Network Diagnostics with Advanced Features
network_Diagnostics(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    
    case "${NAME:-overview}" in
        overview|"")
            echo "${blue}=== NETWORK OVERVIEW ===${normal}"
            echo
            
            # Basic network information
            echo "${yellow}[Network Interfaces]${normal}"
            ip -br addr show
            echo
            
            # Default gateway
            echo "${yellow}[Default Gateway]${normal}"
            ip route | grep default
            echo
            
            # DNS servers
            echo "${yellow}[DNS Servers]${normal}"
            if [ -f /etc/resolv.conf ]; then
                grep nameserver /etc/resolv.conf
            else
                echo "No /etc/resolv.conf found"
            fi
            echo
            
            # Active connections count
            echo "${yellow}[Connection Summary]${normal}"
            echo "Established: $(ss -tan | grep ESTAB | wc -l)"
            echo "Listening: $(ss -tln | grep LISTEN | wc -l)"
            echo "Total connections: $(ss -tan | wc -l)"
            echo
            
            echo "$dateStamp | INFO: Network overview requested" >> /var/log/toolkat.log
        ;;
        
        interfaces|if)
            echo "${blue}=== NETWORK INTERFACES DETAILS ===${normal}"
            echo
            
            # Detailed interface information
            echo "${yellow}[Interface Configuration]${normal}"
            ip addr show
            echo
            
            # Interface statistics
            echo "${yellow}[Interface Statistics]${normal}"
            ip -s link
            echo
            
            # Routing table
            echo "${yellow}[Routing Table]${normal}"
            ip route show
            echo
            
            # ARP cache
            echo "${yellow}[ARP Cache]${normal}"
            ip neigh show
            echo
            
            echo "$dateStamp | INFO: Interface details requested" >> /var/log/toolkat.log
        ;;
        
        connections|conn)
            echo "${blue}=== ACTIVE NETWORK CONNECTIONS ===${normal}"
            echo
            
            # TCP connections
            echo "${yellow}[TCP Connections]${normal}"
            ss -tunap 2>/dev/null | head -20
            echo
            
            # Connection states
            echo "${yellow}[Connection States]${normal}"
            ss -tan | awk 'NR>1 {print $1}' | sort | uniq -c | sort -rn
            echo
            
            echo "$dateStamp | INFO: Active connections viewed" >> /var/log/toolkat.log
        ;;
        
        ports|listening)
            echo "${blue}=== LISTENING PORTS ===${normal}"
            echo
            
            # All listening ports
            echo "${yellow}[Listening Ports (TCP)]${normal}"
            ss -tlnp 2>/dev/null
            echo
            
            echo "${yellow}[Listening Ports (UDP)]${normal}"
            ss -ulnp 2>/dev/null
            echo
            
            echo "$dateStamp | INFO: Listening ports viewed" >> /var/log/toolkat.log
        ;;
        
        test|connectivity)
            echo "${blue}=== CONNECTIVITY TEST ===${normal}"
            echo
            
            # Test common DNS servers
            test_hosts=(
                "8.8.8.8:Google DNS"
                "1.1.1.1:Cloudflare DNS"
                "208.67.222.222:OpenDNS"
            )
            
            for host_info in "${test_hosts[@]}"; do
                IFS=: read -r host name <<< "$host_info"
                echo -n "Testing $name ($host)... "
                if ping -c 2 -W 2 "$host" &>/dev/null; then
                    echo "${green}✓ OK${normal}"
                else
                    echo "${red}✗ FAILED${normal}"
                fi
            done
            echo
            
            # Test HTTP/HTTPS connectivity
            echo "${yellow}[HTTP/HTTPS Connectivity]${normal}"
            test_sites=(
                "http://www.google.com"
                "https://www.cloudflare.com"
            )
            
            for site in "${test_sites[@]}"; do
                echo -n "Testing $site... "
                if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$site" | grep -q "200\|301\|302"; then
                    echo "${green}✓ OK${normal}"
                else
                    echo "${red}✗ FAILED${normal}"
                fi
            done
            echo
            
            # Traceroute to a common host
            if command -v traceroute &> /dev/null; then
                echo "${yellow}[Traceroute to 8.8.8.8]${normal}"
                traceroute -m 10 8.8.8.8 2>/dev/null || echo "Traceroute failed or incomplete"
                echo
            fi
            
            echo "$dateStamp | INFO: Connectivity test performed" >> /var/log/toolkat.log
        ;;
        
        dns|nameserver)
            echo "${blue}=== DNS CONFIGURATION ===${normal}"
            echo
            
            # Current DNS configuration
            echo "${yellow}[Current DNS Servers]${normal}"
            if [ -f /etc/resolv.conf ]; then
                cat /etc/resolv.conf
            else
                echo "No /etc/resolv.conf found"
            fi
            echo
            
            # DNS resolution test
            echo "${yellow}[DNS Resolution Test]${normal}"
            test_domains=("google.com" "github.com" "cloudflare.com")
            for domain in "${test_domains[@]}"; do
                echo -n "Resolving $domain... "
                if host "$domain" &>/dev/null; then
                    result=$(host "$domain" | grep "has address" | head -1 | awk '{print $4}')
                    echo "${green}✓ $result${normal}"
                else
                    echo "${red}✗ FAILED${normal}"
                fi
            done
            echo
            
            # DNS server query time
            if command -v dig &> /dev/null; then
                echo "${yellow}[DNS Query Performance]${normal}"
                for domain in "${test_domains[@]}"; do
                    echo "Query time for $domain:"
                    dig "$domain" | grep "Query time"
                done
                echo
            fi
            
            echo "$dateStamp | INFO: DNS configuration viewed" >> /var/log/toolkat.log
        ;;
        
        speed|speedtest)
            echo "${blue}=== NETWORK SPEED TEST ===${normal}"
            echo
            
            if command -v speedtest-cli &> /dev/null; then
                speedtest-cli
            elif command -v speedtest &> /dev/null; then
                speedtest
            else
                echo "${yellow}Speed test tool not installed${normal}"
                echo
                echo "Install with:"
                echo "  apt: sudo apt install speedtest-cli"
                echo "  pacman: sudo pacman -S speedtest-cli"
                echo "  xbps: sudo xbps-install speedtest-cli"
            fi
            echo
            
            echo "$dateStamp | INFO: Speed test requested" >> /var/log/toolkat.log
        ;;
        
        bandwidth|bw)
            echo "${blue}=== BANDWIDTH MONITORING ===${normal}"
            echo
            
            if command -v vnstat &> /dev/null; then
                echo "${yellow}[Daily Bandwidth Usage]${normal}"
                vnstat -d
                echo
                echo "${yellow}[Hourly Bandwidth Usage]${normal}"
                vnstat -h
                echo
            else
                echo "${yellow}vnstat not installed${normal}"
                echo "Install with: sudo apt install vnstat"
                echo
                
                # Alternative: Show current bandwidth usage
                echo "${yellow}[Current Interface Statistics]${normal}"
                ip -s link
                echo
            fi
            
            echo "$dateStamp | INFO: Bandwidth stats viewed" >> /var/log/toolkat.log
        ;;
        
        firewall|fw)
            echo "${blue}=== FIREWALL STATUS ===${normal}"
            echo
            
            # Check various firewall tools
            if command -v ufw &> /dev/null; then
                echo "${yellow}[UFW Status]${normal}"
                sudo ufw status verbose 2>/dev/null || echo "Need root privileges to view UFW status"
                echo
            fi
            
            if command -v firewall-cmd &> /dev/null; then
                echo "${yellow}[Firewalld Status]${normal}"
                sudo firewall-cmd --state 2>/dev/null || echo "Firewalld not running or need root"
                sudo firewall-cmd --list-all 2>/dev/null
                echo
            fi
            
            # iptables rules
            echo "${yellow}[IPTables Rules]${normal}"
            sudo iptables -L -n -v 2>/dev/null || echo "Need root privileges to view iptables"
            echo
            
            echo "$dateStamp | INFO: Firewall status checked" >> /var/log/toolkat.log
        ;;
        
        wireless|wifi)
            echo "${blue}=== WIRELESS INFORMATION ===${normal}"
            echo
            
            # Wireless interfaces
            echo "${yellow}[Wireless Interfaces]${normal}"
            if command -v iwconfig &> /dev/null; then
                iwconfig 2>&1 | grep -v "no wireless"
            else
                echo "iwconfig not available (install wireless-tools)"
            fi
            echo
            
            # Available networks
            if command -v nmcli &> /dev/null; then
                echo "${yellow}[Available Networks]${normal}"
                nmcli device wifi list 2>/dev/null || echo "Unable to scan (need root or NetworkManager)"
                echo
                
                echo "${yellow}[Saved Connections]${normal}"
                nmcli connection show
                echo
            fi
            
            # Signal strength
            if [ -d /proc/net/wireless ]; then
                echo "${yellow}[Signal Strength]${normal}"
                cat /proc/net/wireless
                echo
            fi
            
            echo "$dateStamp | INFO: Wireless info viewed" >> /var/log/toolkat.log
        ;;
        
        latency|ping)
            echo "${blue}=== NETWORK LATENCY TEST ===${normal}"
            echo
            
            hosts=(
                "8.8.8.8:Google DNS"
                "1.1.1.1:Cloudflare"
                "208.67.222.222:OpenDNS"
            )
            
            for host_info in "${hosts[@]}"; do
                IFS=: read -r host name <<< "$host_info"
                echo "${yellow}[Ping $name ($host)]${normal}"
                ping -c 10 -i 0.2 "$host" 2>/dev/null | tail -2
                echo
            done
            
            echo "$dateStamp | INFO: Latency test performed" >> /var/log/toolkat.log
        ;;
        
        routes|routing)
            echo "${blue}=== ROUTING INFORMATION ===${normal}"
            echo
            
            echo "${yellow}[IP Routing Table]${normal}"
            ip route show
            echo
            
            echo "${yellow}[IPv6 Routing Table]${normal}"
            ip -6 route show 2>/dev/null || echo "IPv6 not available"
            echo
            
            if command -v netstat &> /dev/null; then
                echo "${yellow}[Kernel Routing Table]${normal}"
                netstat -rn
                echo
            fi
            
            echo "$dateStamp | INFO: Routing info viewed" >> /var/log/toolkat.log
        ;;
        
        packets|capture)
            echo "${blue}=== PACKET CAPTURE ===${normal}"
            echo
            
            if [ -z "$Extra" ]; then
                echo "Usage: --net packets <interface>"
                echo "Example: --net packets eth0"
                echo
                echo "Available interfaces:"
                ip -br link show
                exit 1
            fi
            
            if command -v tcpdump &> /dev/null; then
                echo "${yellow}Capturing packets on $Extra (Ctrl+C to stop)${normal}"
                echo "Saving to /tmp/toolkat-capture.pcap"
                echo
                sudo tcpdump -i "$Extra" -w /tmp/toolkat-capture.pcap -v 2>&1 | head -50
            else
                echo "tcpdump not installed"
                echo "Install with: sudo apt install tcpdump"
            fi
            
            echo "$dateStamp | INFO: Packet capture on $Extra" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown network option: $NAME"
            echo "Available: overview, interfaces, connections, ports, test, dns,"
            echo "           speed, bandwidth, firewall, wireless, latency, routes, packets"
            echo "Usage: --net [option]"
        ;;
    esac
}

# NEW: DNS Configuration Management
dns_Config(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    require_root
    
    case "${NAME:-show}" in
        show|"")
            echo "${blue}=== CURRENT DNS CONFIGURATION ===${normal}"
            echo
            
            echo "${yellow}[/etc/resolv.conf]${normal}"
            cat /etc/resolv.conf
            echo
            
            # Check if systemd-resolved is running
            if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
                echo "${yellow}[systemd-resolved Status]${normal}"
                echo "Status: ${green}Active${normal}"
                resolvectl status 2>/dev/null || systemd-resolve --status 2>/dev/null
                echo
            fi
            
            # Check NetworkManager
            if command -v nmcli &> /dev/null; then
                echo "${yellow}[NetworkManager DNS]${normal}"
                nmcli device show | grep DNS
                echo
            fi
            
            echo "$dateStamp | INFO: DNS configuration viewed" >> /var/log/toolkat.log
        ;;
        
        set)
            if [ -z "$Extra" ]; then
                echo "Usage: --dns set <dns_provider>"
                echo
                echo "Available providers:"
                echo "  google       (8.8.8.8, 8.8.4.4)"
                echo "  cloudflare   (1.1.1.1, 1.0.0.1)"
                echo "  quad9        (9.9.9.9, 149.112.112.112)"
                echo "  opendns      (208.67.222.222, 208.67.220.220)"
                echo "  custom       (will prompt for addresses)"
                exit 1
            fi
            
            # Backup current resolv.conf
            cp /etc/resolv.conf /etc/resolv.conf.backup
            
            case "$Extra" in
                google)
                    cat > /etc/resolv.conf << EOF
# Generated by ToolKat - Google DNS
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
                    echo "${green}DNS set to Google DNS (8.8.8.8, 8.8.4.4)${normal}"
                ;;
                
                cloudflare)
                    cat > /etc/resolv.conf << EOF
# Generated by ToolKat - Cloudflare DNS
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
                    echo "${green}DNS set to Cloudflare (1.1.1.1, 1.0.0.1)${normal}"
                ;;
                
                quad9)
                    cat > /etc/resolv.conf << EOF
# Generated by ToolKat - Quad9 DNS
nameserver 9.9.9.9
nameserver 149.112.112.112
EOF
                    echo "${green}DNS set to Quad9 (9.9.9.9, 149.112.112.112)${normal}"
                ;;
                
                opendns)
                    cat > /etc/resolv.conf << EOF
# Generated by ToolKat - OpenDNS
nameserver 208.67.222.222
nameserver 208.67.220.220
EOF
                    echo "${green}DNS set to OpenDNS (208.67.222.222, 208.67.220.220)${normal}"
                ;;
                
                custom)
                    echo "Enter primary DNS server:"
                    read -r dns1
                    echo "Enter secondary DNS server (optional, press enter to skip):"
                    read -r dns2
                    
                    echo "# Generated by ToolKat - Custom DNS" > /etc/resolv.conf
                    echo "nameserver $dns1" >> /etc/resolv.conf
                    [ -n "$dns2" ] && echo "nameserver $dns2" >> /etc/resolv.conf
                    
                    echo "${green}DNS set to custom servers${normal}"
                ;;
                
                *)
                    echo "Unknown DNS provider: $Extra"
                    exit 1
                ;;
            esac
            
            # Prevent NetworkManager from overwriting
            if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
                if ! grep -q "\[main\]" /etc/NetworkManager/NetworkManager.conf; then
                    echo "[main]" >> /etc/NetworkManager/NetworkManager.conf
                fi
                if ! grep -q "dns=none" /etc/NetworkManager/NetworkManager.conf; then
                    sed -i '/\[main\]/a dns=none' /etc/NetworkManager/NetworkManager.conf
                    echo "${yellow}Note: Disabled NetworkManager DNS management${normal}"
                    echo "Restart NetworkManager: sudo systemctl restart NetworkManager"
                fi
            fi
            
            echo
            echo "Backup saved to: /etc/resolv.conf.backup"
            echo "$dateStamp | INFO: DNS changed to $Extra" >> /var/log/toolkat.log
        ;;
        
        restore)
            if [ -f /etc/resolv.conf.backup ]; then
                cp /etc/resolv.conf.backup /etc/resolv.conf
                echo "${green}DNS configuration restored from backup${normal}"
                echo "$dateStamp | INFO: DNS configuration restored" >> /var/log/toolkat.log
            else
                echo "${red}No backup found${normal}"
            fi
        ;;
        
        test)
            echo "${blue}=== DNS RESOLUTION TEST ===${normal}"
            echo
            
            test_domains=("google.com" "github.com" "cloudflare.com" "amazon.com")
            
            for domain in "${test_domains[@]}"; do
                echo -n "Resolving $domain... "
                start=$(date +%s%N)
                if result=$(host "$domain" 2>/dev/null | grep "has address" | head -1 | awk '{print $4}'); then
                    end=$(date +%s%N)
                    time=$((($end - $start) / 1000000))
                    echo "${green}✓ $result (${time}ms)${normal}"
                else
                    echo "${red}✗ FAILED${normal}"
                fi
            done
            echo
            
            echo "$dateStamp | INFO: DNS test performed" >> /var/log/toolkat.log
        ;;
        
        flush)
            echo "${blue}=== FLUSHING DNS CACHE ===${normal}"
            echo
            
            # systemd-resolved
            if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
                systemd-resolve --flush-caches 2>/dev/null || resolvectl flush-caches
                echo "${green}✓ Flushed systemd-resolved cache${normal}"
            fi
            
            # nscd
            if command -v nscd &> /dev/null; then
                systemctl restart nscd 2>/dev/null || /etc/init.d/nscd restart 2>/dev/null
                echo "${green}✓ Restarted nscd${normal}"
            fi
            
            # dnsmasq
            if command -v dnsmasq &> /dev/null; then
                systemctl restart dnsmasq 2>/dev/null || /etc/init.d/dnsmasq restart 2>/dev/null
                echo "${green}✓ Restarted dnsmasq${normal}"
            fi
            
            echo
            echo "$dateStamp | INFO: DNS cache flushed" >> /var/log/toolkat.log
        ;;
        
        benchmark)
            echo "${blue}=== DNS BENCHMARK ===${normal}"
            echo
            
            dns_servers=(
                "8.8.8.8:Google"
                "1.1.1.1:Cloudflare"
                "9.9.9.9:Quad9"
                "208.67.222.222:OpenDNS"
            )
            
            test_domain="google.com"
            
            echo "Testing DNS servers with $test_domain..."
            echo
            
            for server_info in "${dns_servers[@]}"; do
                IFS=: read -r server name <<< "$server_info"
                echo -n "$name ($server): "
                
                total_time=0
                success=0
                
                for i in {1..5}; do
                    start=$(date +%s%N)
                    if dig @"$server" "$test_domain" +short +time=2 &>/dev/null; then
                        end=$(date +%s%N)
                        time=$((($end - $start) / 1000000))
                        total_time=$((total_time + time))
                        success=$((success + 1))
                    fi
                done
                
                if [ $success -gt 0 ]; then
                    avg=$((total_time / success))
                    echo "${green}${avg}ms average (${success}/5 successful)${normal}"
                else
                    echo "${red}FAILED${normal}"
                fi
            done
            echo
            
            echo "$dateStamp | INFO: DNS benchmark performed" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown DNS command: $NAME"
            echo "Available: show, set, restore, test, flush, benchmark"
            echo "Usage: --dns [command] [options]"
        ;;
    esac
}

# System Health Check
system_Health(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    
    case "${NAME:-overview}" in
        overview|"")
            echo "${blue}=== SYSTEM HEALTH CHECK ===${normal}"
            echo
            
            # CPU Load
            echo "${yellow}[CPU Load]${normal}"
            load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
            echo "Load Average: $load"
            cores=$(nproc)
            echo "CPU Cores: $cores"
            echo
            
            # Memory
            echo "${yellow}[Memory Usage]${normal}"
            free -h | awk 'NR==2 {printf "Used: %s/%s (%.0f%%)\n", $3, $2, ($3/$2)*100}'
            echo
            
            # Disk Space
            echo "${yellow}[Disk Space]${normal}"
            df -h | awk 'NR==1 || /^\/dev\// {print}' | column -t
            echo
            
            # System Uptime
            echo "${yellow}[System Uptime]${normal}"
            uptime -p
            echo
            
            # Failed Services
            if command -v systemctl &> /dev/null; then
                echo "${yellow}[Failed Services]${normal}"
                failed=$(systemctl --failed --no-legend | wc -l)
                if [ "$failed" -eq 0 ]; then
                    echo "${green}No failed services${normal}"
                else
                    echo "${red}$failed failed service(s):${normal}"
                    systemctl --failed --no-legend
                fi
                echo
            fi
            
            echo "$dateStamp | INFO: Health check overview" >> /var/log/toolkat.log
        ;;
        
        disk)
            echo "${blue}=== DISK HEALTH CHECK ===${normal}"
            echo
            
            echo "${yellow}[Disk Usage]${normal}"
            df -h | awk 'NR==1 || /^\/dev\// {print}' | column -t
            echo
            
            if [ -n "$Extra" ]; then
                echo "${yellow}[Large Files (>${Extra})]${normal}"
                find / -type f -size "+${Extra}" -exec ls -lh {} \; 2>/dev/null | awk '{print $9": "$5}'
                echo
            fi
            
            echo "$dateStamp | INFO: Disk health check" >> /var/log/toolkat.log
        ;;
        
        smart)
            require_root
            echo "${blue}=== SMART DISK DIAGNOSTICS ===${normal}"
            echo
            
            if command -v smartctl &> /dev/null; then
                for disk in $(lsblk -ndo NAME | grep -E '^sd|^nvme'); do
                    echo "${yellow}[/dev/$disk]${normal}"
                    smartctl -H /dev/$disk 2>/dev/null
                    echo
                done
            else
                echo "smartmontools not installed"
                echo "Install with: sudo apt install smartmontools"
            fi
            
            echo "$dateStamp | INFO: SMART diagnostics performed" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown health option: $NAME"
            echo "Available: overview, disk, smart"
        ;;
    esac
}

# System Cleanup
system_Cleanup(){
    logCheck
    local dateStamp=$(date +%F"|"%r)
    
    case "${NAME:-preview}" in
        preview|"")
            echo "${blue}=== CLEANUP PREVIEW ===${normal}"
            echo
            
            echo "${yellow}[Temporary Files]${normal}"
            tmp_size=$(du -sh /tmp 2>/dev/null | cut -f1)
            echo "/tmp: $tmp_size"
            
            echo "${yellow}[Log Files]${normal}"
            log_size=$(du -sh /var/log 2>/dev/null | cut -f1)
            echo "/var/log: $log_size"
            
            echo "${yellow}[Package Cache]${normal}"
            pkg_mgr=$(detect_package_manager)
            case "$pkg_mgr" in
                apt)
                    cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1)
                    echo "/var/cache/apt: $cache_size"
                ;;
                pacman)
                    cache_size=$(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)
                    echo "/var/cache/pacman: $cache_size"
                ;;
                xbps)
                    cache_size=$(du -sh /var/cache/xbps 2>/dev/null | cut -f1)
                    echo "/var/cache/xbps: $cache_size"
                ;;
            esac
            
            echo
            echo "Use: --clean [temp|logs|packages|cache|trash|all]"
        ;;
        
        temp)
            require_root
            echo "${blue}=== CLEANING TEMPORARY FILES ===${normal}"
            find /tmp -type f -atime +7 -delete 2>/dev/null
            echo "${green}✓ Cleaned /tmp${normal}"
            echo "$dateStamp | INFO: Temporary files cleaned" >> /var/log/toolkat.log
        ;;
        
        logs)
            require_root
            echo "${blue}=== CLEANING LOG FILES ===${normal}"
            find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
            journalctl --vacuum-time=30d 2>/dev/null
            echo "${green}✓ Cleaned old logs${normal}"
            echo "$dateStamp | INFO: Log files cleaned" >> /var/log/toolkat.log
        ;;
        
        packages)
            require_root
            echo "${blue}=== CLEANING PACKAGE CACHE ===${normal}"
            pkg_mgr=$(detect_package_manager)
            case "$pkg_mgr" in
                apt)
                    apt clean && apt autoclean
                ;;
                pacman)
                    pacman -Sc --noconfirm
                ;;
                xbps)
                    xbps-remove -O
                ;;
            esac
            echo "${green}✓ Package cache cleaned${normal}"
            echo "$dateStamp | INFO: Package cache cleaned" >> /var/log/toolkat.log
        ;;
        
        cache)
            echo "${blue}=== CLEANING USER CACHE ===${normal}"
            rm -rf ~/.cache/* 2>/dev/null
            echo "${green}✓ User cache cleaned${normal}"
            echo "$dateStamp | INFO: User cache cleaned" >> /var/log/toolkat.log
        ;;
        
        trash)
            echo "${blue}=== EMPTYING TRASH ===${normal}"
            rm -rf ~/.local/share/Trash/* 2>/dev/null
            echo "${green}✓ Trash emptied${normal}"
            echo "$dateStamp | INFO: Trash emptied" >> /var/log/toolkat.log
        ;;
        
        all)
            require_root
            echo "${blue}=== FULL SYSTEM CLEANUP ===${normal}"
            echo
            
            # All cleanup operations
            system_Cleanup() { NAME="temp"; system_Cleanup; }
            system_Cleanup() { NAME="logs"; system_Cleanup; }
            system_Cleanup() { NAME="packages"; system_Cleanup; }
            
            find /tmp -type f -atime +7 -delete 2>/dev/null
            find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
            journalctl --vacuum-time=30d 2>/dev/null
            
            pkg_mgr=$(detect_package_manager)
            case "$pkg_mgr" in
                apt) apt clean && apt autoclean && apt autoremove -y ;;
                pacman) pacman -Sc --noconfirm ;;
                xbps) xbps-remove -O ;;
            esac
            
            rm -rf ~/.cache/* 2>/dev/null
            rm -rf ~/.local/share/Trash/* 2>/dev/null
            
            echo "${green}✓ Complete cleanup finished${normal}"
            echo "$dateStamp | INFO: Full system cleanup completed" >> /var/log/toolkat.log
        ;;
        
        *)
            echo "Unknown cleanup option: $NAME"
            echo "Available: preview, temp, logs, packages, cache, trash, all"
        ;;
    esac
}

# User Management Helper
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
                echo "$Extra is an existing user."
                echo "$dateStamp | ERROR: tried creating $Extra, user already exists." >> /var/log/toolkat.log
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
    ;;
    esac
}

# Show command history
show_History(){
    logCheck
    echo "${blue}=== TOOLKAT COMMAND HISTORY ===${normal}"
    echo
    
    if [ -f "/var/log/toolkat.log" ]; then
        echo "${yellow}Last 20 commands:${normal}"
        tail -20 /var/log/toolkat.log | while IFS='|' read -r date level message; do
            case "$level" in
                *INFO*)
                    echo "${green}•${normal} $date | $message"
                ;;
                *WARNING*)
                    echo "${yellow}⚠${normal} $date | $message"
                ;;
                *ERROR*)
                    echo "${red}✗${normal} $date | $message"
                ;;
                *)
                    echo "  $date | $level | $message"
                ;;
            esac
        done
        echo
        echo "${cyan}Full log: /var/log/toolkat.log${normal}"
    else
        echo "${yellow}No history found. Run some commands first!${normal}"
    fi
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

${green}System Health:${normal}
--health  System health check
  overview          Complete health check (default)
  disk [size]       Disk health (optional: find files > size)
  smart             SMART disk diagnostics (requires root)

${green}System Cleanup:${normal}
--clean   System cleanup
  preview           Show what can be cleaned (default)
  temp              Clean temporary files (requires root)
  logs              Clean old log files (requires root)
  packages          Clean package cache (requires root)
  cache             Clean user cache
  trash             Empty trash
  all               Clean everything (requires root)

${green}Network Diagnostics:${normal}
--net     Network diagnostics
  overview          Network overview (default)
  interfaces        Detailed interface information
  connections       Active network connections
  ports             Listening ports
  test              Connectivity test
  dns               DNS configuration and tests
  speed             Speed test (requires speedtest-cli)
  bandwidth         Bandwidth monitoring (requires vnstat)
  firewall          Firewall status
  wireless          Wireless information
  latency           Network latency tests
  routes            Routing information
  packets <if>      Packet capture on interface

${green}DNS Management (requires root):${normal}
--dns     DNS configuration
  show              Show current DNS configuration (default)
  set <provider>    Set DNS (google|cloudflare|quad9|opendns|custom)
  restore           Restore DNS from backup
  test              Test DNS resolution
  flush             Flush DNS cache
  benchmark         Benchmark DNS servers

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
--history Show command history

${yellow}Examples:${normal}
  ${cyan}Network Testing:${normal}
    toolkat.sh --net test                    # Test connectivity
    toolkat.sh --net dns                     # Check DNS configuration
    toolkat.sh --net latency                 # Test latency to common hosts
    toolkat.sh --net wireless                # View wireless networks
    toolkat.sh --net bandwidth               # Monitor bandwidth usage
    
  ${cyan}DNS Management:${normal}
    sudo toolkat.sh --dns show               # Show DNS configuration
    sudo toolkat.sh --dns set cloudflare     # Switch to Cloudflare DNS
    sudo toolkat.sh --dns benchmark          # Benchmark DNS servers
    sudo toolkat.sh --dns flush              # Flush DNS cache
    
  ${cyan}System Management:${normal}
    toolkat.sh --health                      # System health check
    sudo toolkat.sh --clean all              # Full system cleanup
    toolkat.sh --perf cpu                    # CPU performance details
    sudo toolkat.sh --umh create john        # Create user 'john'
    
  ${cyan}Advanced Network:${normal}
    sudo toolkat.sh --net packets eth0       # Capture packets
    toolkat.sh --net firewall                # Check firewall status
    toolkat.sh --net routes                  # View routing table
EOF
}

case "${1:-}" in
    --b)
        base_Info
    ;;
    --la)
        log_Analyzer
    ;;
    --health)
        NAME="${2:-}"
        Extra="${3:-}"
        system_Health
    ;;
    --clean)
        NAME="${2:-}"
        Extra="${3:-}"
        system_Cleanup
    ;;
    --net)
        NAME="${2:-}"
        Extra="${3:-}"
        network_Diagnostics
    ;;
    --dns)
        NAME="${2:-}"
        Extra="${3:-}"
        dns_Config
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
    --history)
        show_History
    ;;
    --no-color)
        disable_colors
        Info
    ;;
    --help|"")
        Info
    ;;
    *)
        echo "Unknown command: $1"
        echo "Use --help for available commands"
        exit 1
    ;;
esac
