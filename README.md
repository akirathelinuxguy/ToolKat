# ToolKat

**ToolKat** is a comprehensive Bash-based system utility script that bundles common Linux admin tasks into a single CLI tool.  
It provides system info, log analysis, user management, **performance monitoring**, and **package management** with built-in logging.

> Some features require **root privileges** and directly modify system users/packages. Use responsibly.

---

## Features

### Base System Info `--b`

Quick snapshot of your system:
- Logged-in user
- Linux distribution
- Kernel version
- Terminal & shell
- Disk usage
- System uptime

**Example:**
```bash
./toolkat.sh --b
```

---

### User Management Helper `--umh`

Create, delete, lock, unlock, and list users with automatic logging.   
**Be sure to use `sudo` with these commands**

**Commands:**
- `--umh create "user"` - Create a new user
- `--umh delete "user"` - Delete a user
- `--umh lock "user"` - Lock a user account
- `--umh unlock "user"` - Unlock a user account
- `--umh list` - List all users
- `--umh list "username"` - Search for specific user

All actions are logged to: `/var/log/toolkat.log`

**Examples:**
```bash
sudo ./toolkat.sh --umh create john
sudo ./toolkat.sh --umh lock john
sudo ./toolkat.sh --umh list john
```

---

### Log Analyzer `--la`

Searches `/var/log/` for common failure indicators:
- `error`
- `failed`
- `exception`
- `fatal`

**Example:**
```bash
./toolkat.sh --la
```

---

### 🆕 Performance Monitoring `--perf`

Monitor system performance metrics in real-time.

**Commands:**
- `--perf` or `--perf overview` - Complete system overview
- `--perf cpu` - Detailed CPU information and usage
- `--perf memory` - Memory usage and statistics
- `--perf disk` - Disk usage and I/O statistics
- `--perf processes` - Process information (CPU/Memory hogs)
- `--perf temp` - Temperature sensor readings (requires lm-sensors)

**Examples:**
```bash
./toolkat.sh --perf              # Full overview
./toolkat.sh --perf cpu          # CPU details
./toolkat.sh --perf memory       # Memory stats
./toolkat.sh --perf processes    # Process list
```

**What it shows:**
- **Overview**: CPU load, memory usage, top 5 processes by CPU/memory, disk I/O
- **CPU**: Model, cores, architecture, per-core usage, clock speeds
- **Memory**: Total/used/free memory, swap usage, buffers/cache
- **Disk**: Filesystem usage, I/O statistics, read/write operations
- **Processes**: Top processes, zombie count, running processes
- **Temp**: All temperature sensors (CPU, GPU, etc.)

**Optional Dependencies:**
- `sysstat` package for `iostat` and `mpstat` (disk/CPU stats)
- `lm-sensors` package for temperature monitoring

---

### 🆕 Package Management `--pkg`

Universal package manager interface that auto-detects and works with:
- **xbps** (Void Linux)
- **pacman** (Arch Linux, Manjaro)
- **apt** (Debian, Ubuntu, Linux Mint)

**Commands:**
- `--pkg update` - Update package database (requires root)
- `--pkg upgrade` - Upgrade all packages (requires root)
- `--pkg install <package>` - Install a package (requires root)
- `--pkg remove <package>` - Remove a package (requires root)
- `--pkg search <term>` - Search for packages
- `--pkg info <package>` - Show detailed package information
- `--pkg list [filter]` - List installed packages (optionally filtered)
- `--pkg clean` - Clean package cache (requires root)

**Examples:**
```bash
# Update package database
sudo ./toolkat.sh --pkg update

# Install a package
sudo ./toolkat.sh --pkg install htop

# Search for packages
./toolkat.sh --pkg search firefox

# Get package info
./toolkat.sh --pkg info vim

# List all installed packages
./toolkat.sh --pkg list

# List packages matching a pattern
./toolkat.sh --pkg list python

# Upgrade all packages
sudo ./toolkat.sh --pkg upgrade

# Clean package cache
sudo ./toolkat.sh --pkg clean
```

**Features:**
- Automatic package manager detection
- Unified interface across different distros
- All package operations logged to `/var/log/toolkat.log`
- Color-coded output for better readability

---

### Help Interface `--help`

Display all available commands and usage examples.

**Example:**
```bash
./toolkat.sh --help
```

---

## Installation

1. **Download the script:**
   ```bash
   git clone https://github.com/akirathelinuxguy/ToolKat.git
   cd ToolKat
   ```

2. **Make it executable:**
   ```bash
   chmod +x toolkat.sh
   ```

3. **Run it:**
   ```bash
   ./toolkat.sh --help
   ```

4. **Optional - Install system-wide:**
   ```bash
   sudo cp toolkat.sh /usr/local/bin/toolkat
   sudo chmod +x /usr/local/bin/toolkat
   # Now you can run it from anywhere
   toolkat --help
   ```

---

## Requirements

### Core Requirements
- Bash shell
- Linux system (tested on Void, Arch, Debian/Ubuntu)
- Root access for certain operations

### Optional for Full Functionality
- `sysstat` - For disk and CPU statistics (`iostat`, `mpstat`)
  - Void: `sudo xbps-install -S sysstat`
  - Arch: `sudo pacman -S sysstat`
  - Debian/Ubuntu: `sudo apt install sysstat`

- `lm-sensors` - For temperature monitoring
  - Void: `sudo xbps-install -S lm_sensors`
  - Arch: `sudo pacman -S lm_sensors`
  - Debian/Ubuntu: `sudo apt install lm-sensors`

---

## Logging

All user management and package operations are automatically logged to:
```
/var/log/toolkat.log
```

Log format:
```
YYYY-MM-DD|HH:MM:SS AM/PM | LEVEL: message
```

Example log entries:
```
2026-01-29|02:30:45 PM | INFO: user john has been created
2026-01-29|02:31:12 PM | INFO: Package htop installed (pacman)
2026-01-29|02:32:05 PM | INFO: Performance overview requested
```

---

## Security Notes

- **User Management**: Cannot delete root or your own user account
- **Package Management**: Most operations require root privileges
- **Logging**: All sensitive operations are logged for audit trails
- **Input Validation**: Script validates user input to prevent common errors

---

## Troubleshooting

### "Package manager not found"
Make sure you're on a supported distribution (Void/Arch/Debian/Ubuntu-based).

### "sysstat not installed"
Install the sysstat package for full disk/CPU statistics:
```bash
# Void
sudo xbps-install -S sysstat

# Arch
sudo pacman -S sysstat

# Debian/Ubuntu
sudo apt install sysstat
```

### "lm-sensors not installed"
Install lm-sensors for temperature monitoring:
```bash
# Void
sudo xbps-install -S lm_sensors

# Arch
sudo pacman -S lm_sensors

# Debian/Ubuntu
sudo apt install lm-sensors && sudo sensors-detect
```

---

## Contributing

Feel free to fork this repository and submit pull requests with improvements!

---

## License

This is a fork of ToolKat from [Scryv](https://github.com/Scryv/ToolKat) with additional features.

---

- User management
- Log analyzer
