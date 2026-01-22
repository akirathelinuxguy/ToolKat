#!/bin/bash
set -euo pipefail
normal=$(printf '\033[0m')
yellow=$(printf '\033[33m')

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
User_Management_Helper(){
logCheck
local dateStamp=$(date +%F"|"%r)
case "$NAME" in
    create)
        require_root
            if [ -z "$Extra" ]; then #if empty -z shall detect
              echo "Error: You must provide a name." #put this under ur case thing and it will search second
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
                    echo "$dateStamp | INFO: user $Extra has been created" >> /var/log/toolkat.log #alos add timestamps
            fi
        fi
    ;;
    delete)
        user=$(id -un)
        require_root
            if [ -z "$Extra" ]; then #if empty -z shall detect
              echo "Error: You must provide a name." #put this under ur case thing and it will search second
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
                    echo "$dateStamp | ERROR: tried deleting unexisting user called $Extra." >> /var/log/toolkat.log #alos add timestamps
            fi
        fi
    ;;
    lock)
        require_root
            if [ -z "$Extra" ]; then #if empty -z shall detect
              echo "Error: You must provide a name." #put this under ur case thing and it will search second
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
                    echo "$dateStamp | ERROR: tried locking unexisting user called $Extra." >> /var/log/toolkat.log #alos add timestamps
        fi
        fi
    ;;
    unlock)
        require_root
            if [ -z "$Extra" ]; then #if empty -z shall detect
              echo "Error: You must provide a name." #put this under ur case thing and it will search second
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
                    echo "$dateStamp | ERROR: tried unlocking unexisting user called $Extra." >> /var/log/toolkat.log #alos add timestamps
        fi
    fi
    ;;
    list)
        if [ -z "$Extra" ]; then #if empty -z shall detect
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

--b Base info
--la Log analyzer
--umh User management helper
  create to create User(req root)
  delete to delete User(req root)
  lock to lock User(req root)
  unlock to unlock User(req root)
  list   to list all Users
    Username (see if user exists)

--help cli help interface
EOF
}



case "$1" in
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
    --help)
    Info
    ;;

    *)
       echo "--help for commands"


esac
