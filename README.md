# ToolKat

**ToolKat** is a Bash-based system utility script that bundles common Linux admin tasks into a single CLI tool.  
It provides system info, log analysis, and a user management helper with built-in logging.

> Some features require **root privileges** and directly modify system users. Use responsibly.

---
## Features
### Base System Info `--b`
<img src="https://github.com/Scryv/ToolKat/blob/main/pictures/1.png">
Quick snapshot of your system:
- Logged-in user
- Linux distribution
- Kernel version
- Terminal & shell
- Disk usage
- System uptime

### User Management Helper `--umh`
Create, delete, lock, unlock, and list users with automatic logging. <br />
- `--uhm create "user"` <br />
- `--uhm delete "user"` <br />
- `--uhm lock "user"` <br />
- `--uhm unlock "user"` <br />
- `--uhm list` <br />
- `--uhm create "user"` <br /> <br />
Actions are logged to: /var/log/toolkat.log

### Log Analyzer `--la`
Searches `/var/log/` for common failure indicators:
- `error`
- `failed`
- `exception`
- `fatal` <br />

### Cli Helper Command `--help`
<img src="https://github.com/Scryv/ToolKat/blob/main/pictures/2.png">


