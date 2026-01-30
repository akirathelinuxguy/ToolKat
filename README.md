# ToolKat
ToolKat is a Bash-based system utility script that bundles common Linux admin tasks into a single CLI tool.
It provides system info, log analysis, and a user management helper with built-in logging.

Some features require root privileges and directly modify system users. Use responsibly.

## commands
Basic:
--b       Base info
--la      Log analyzer

## System Health:
--health  System health check
  overview          Complete health check (default)
  
  disk [size]       Disk health (optional: find files > size)
  
  smart             SMART disk diagnostics (requires root)

## System Cleanup:
--clean   System cleanup
  preview           Show what can be cleaned (default)
  
  temp              Clean temporary files (requires root)
  
  logs              Clean old log files (requires root)
  
  packages          Clean package cache (requires root)
  
  cache             Clean user cache
  
  trash             Empty trash
  
  all               Clean everything (requires root, may not work in certain circumstances)
  

## Network Diagnostics:


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
  

## DNS Management (requires root):
--dns     DNS configuration
  show              Show current DNS configuration (default)
  
  set <provider>    Set DNS (google|cloudflare|quad9|opendns|custom)
  
  restore           Restore DNS from backup
  
  test              Test DNS resolution
  
  flush             Flush DNS cache
  
  benchmark         Benchmark DNS servers

## User Management (requires root):
--umh     User management helper

  create <user>     Create a user
  
  delete <user>     Delete a user
  
  lock <user>       Lock a user
  
  unlock <user>     Unlock a user
  
  list [user]       List all users or search for specific user

## Performance Monitoring:

--perf    Performance monitoring

  overview          System performance overview (default)
  
  cpu               Detailed CPU information
  
  memory            Detailed memory information
  
  disk              Detailed disk I/O statistics
  
  processes         Detailed process information
  
  temp              Temperature sensors

## Package Management (requires root for most):

--pkg     Package manager (auto-detects xbps/pacman/apt)

  update            Update package database
  
  upgrade           Upgrade all packages
  
  install <pkg>     Install a package
  
  remove <pkg>      Remove a package
  
  search <term>     Search for packages
  
  info <pkg>        Show package information
  
  list [filter]     List installed packages
  
  clean             Clean package cache
## general commands
--help    Show this help interface

--history Show command history


