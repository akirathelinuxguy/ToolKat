# ToolKat

**ToolKat** is a Bash-based system utility script that bundles common Linux admin tasks into a single CLI tool.  
It provides system info, log analysis, and a user management helper with built-in logging.

> Some features require **root privileges** and directly modify system users. Use responsibly.

---

## Features

### Base System Info (--b)
Quick snapshot of your system:
- Logged-in user
- Linux distribution
- Kernel version
- Terminal & shell
- Disk usage
- System uptime

### 🔍 Log Analyzer (--la)
Searches `/var/log/` for common failure indicators:
- `error`
- `failed`
- `exception`
- `fatal`

Great for quick troubleshooting.

### 👥 User Management Helper (--umh)
Create, delete, lock, unlock, and list users with automatic logging.

Actions are logged to: /var/log/toolkat.log
