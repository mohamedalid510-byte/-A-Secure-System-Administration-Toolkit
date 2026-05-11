#!/bin/bash
# =============================================================
# fileserver.sh — Module 6: Temporary File Server (Robust)
# =============================================================
# PURPOSE:
#   Allows any admin to instantly share a local folder over the
#   LAN without installing extra software. Automatically handles
#   port conflicts and stale PID files.
#
# HOW IT WORKS:
#   START:
#     1. Admin picks a directory to share.
#     2. Script checks if port is free. If busy, kills the conflicting
#        Python process (with confirmation) or switches to a different port.
#     3. Starts python3 -m http.server in background.
#     4. Saves PID to /tmp/sentinel_fileserver.pid.
#   STOP:
#     1. Reads PID from file, kills the process.
#     2. Removes PID file.
# =============================================================

FS_PID_FILE="/tmp/sentinel_fileserver.pid"
FS_PORT=8000
FS_LOG="fileserver_access.log"

RED="\e[1;31m"
GRN="\e[1;32m"
YEL="\e[1;33m"
CYN="\e[1;36m"
RST="\e[0m"

get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

is_running() {
    if [ -f "$FS_PID_FILE" ]; then
        local pid
        pid=$(cat "$FS_PID_FILE")
        if ps -p "$pid" -o comm= 2>/dev/null | grep -qi "python"; then
            return 0
        fi
    fi
    # Also check if port is listening (in case PID file is missing)
    if ss -tlnp 2>/dev/null | grep -q ":${FS_PORT}.*python"; then
        return 0
    fi
    return 1
}

# Kill any process using the given port
kill_process_on_port() {
    local port=$1
    local pids
    pids=$(ss -tlnp 2>/dev/null | grep ":${port}" | grep -oP 'pid=\K[0-9]+' | sort -u)
    if [ -n "$pids" ]; then
        echo -e "  ${YEL}[i] Port ${port} is in use by PID(s): ${pids}${RST}"
        read -rp "  Kill these processes and continue? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for pid in $pids; do
                kill -9 "$pid" 2>/dev/null
                echo -e "  ${GRN}[✔] Killed PID ${pid}${RST}"
            done
            sleep 1
            return 0
        else
            return 1
        fi
    fi
    return 0
}

start_server() {
    if is_running; then
        local pid
        pid=$(cat "$FS_PID_FILE" 2>/dev/null)
        echo -e "  ${YEL}[i] File server already running (PID ${pid:-unknown}).${RST}"
        echo "      Stop it first with option [2]."
        return 1
    fi

    echo ""
    read -rp "  Enter full path of directory to share: " share_dir
    share_dir="${share_dir%/}"

    if [ -z "$share_dir" ]; then
        echo "  [!] No path entered."
        return 1
    fi

    if [ ! -d "$share_dir" ]; then
        echo "  [!] '$share_dir' is not a valid directory."
        return 1
    fi

    if ! command -v python3 &>/dev/null; then
        echo "  [!] python3 is not installed. Install with: sudo apt install python3"
        return 1
    fi

    local port=$FS_PORT
    # Check if port is free; if not, try to kill the occupying process
    if ss -tlnp 2>/dev/null | grep -q ":${port}"; then
        echo -e "  ${YEL}[!] Port ${port} is busy.${RST}"
        if kill_process_on_port "$port"; then
            echo -e "  ${GRN}Port ${port} is now free.${RST}"
        else
            # Offer to use a different port
            echo ""
            read -rp "  Use a different port? (y/N): " change_port
            if [[ "$change_port" =~ ^[Yy]$ ]]; then
                read -rp "  Enter new port number (e.g., 8080): " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1024 ] && [ "$new_port" -le 65535 ]; then
                    port=$new_port
                else
                    echo "  [!] Invalid port. Using default 8000 anyway (may fail)."
                fi
            else
                echo "  [!] Cannot start server. Free the port manually or use a different one."
                return 1
            fi
        fi
    fi

    # Remove stale PID file
    rm -f "$FS_PID_FILE"

    # Start the server in the background
    (
        cd "$share_dir" || exit 1
        python3 -m http.server "$port" >> "$OLDPWD/$FS_LOG" 2>&1
    ) &

    local pid=$!
    echo "$pid" > "$FS_PID_FILE"
    sleep 1

    if ps -p "$pid" &>/dev/null; then
        local ip
        ip=$(get_local_ip)
        echo ""
        echo -e "  ${GRN}[✔] File server started successfully!${RST}"
        echo    "  ┌───────────────────────────────────────────────┐"
        printf  "  │  Sharing  : %-33s│\n" "$share_dir"
        printf  "  │  PID      : %-33s│\n" "$pid"
        printf  "  │  Access   : %-33s│\n" "http://${ip}:${port}"
        printf  "  │  Log file : %-33s│\n" "$FS_LOG"
        echo    "  └───────────────────────────────────────────────┘"
        echo ""
        echo -e "  ${YEL}[i] Anyone on your network can browse the shared folder.${RST}"
        echo -e "  ${YEL}    Do NOT expose this to the internet — no authentication!${RST}"
    else
        echo -e "  ${RED}[✗] Server failed to start.${RST}"
        rm -f "$FS_PID_FILE"
        return 1
    fi
}

stop_server() {
    if ! is_running; then
        echo "  [i] No file server is currently running."
        return
    fi

    # Kill by PID file if exists, otherwise kill by port
    if [ -f "$FS_PID_FILE" ]; then
        local pid
        pid=$(cat "$FS_PID_FILE")
        kill "$pid" 2>/dev/null
        sleep 0.5
        rm -f "$FS_PID_FILE"
        echo -e "  ${GRN}[✔] File server (PID $pid) stopped.${RST}"
    else
        # Fallback: kill any Python process on FS_PORT
        local pids
        pids=$(ss -tlnp 2>/dev/null | grep ":${FS_PORT}" | grep -oP 'pid=\K[0-9]+')
        if [ -n "$pids" ]; then
            for pid in $pids; do
                kill "$pid" 2>/dev/null
            done
            echo -e "  ${GRN}[✔] File server on port ${FS_PORT} stopped.${RST}"
        else
            echo "  [i] No server found on port ${FS_PORT}."
        fi
    fi
}

show_status() {
    if is_running; then
        local pid ip port
        pid=$(cat "$FS_PID_FILE" 2>/dev/null)
        ip=$(get_local_ip)
        # Determine actual port from listening socket
        port=$(ss -tlnp 2>/dev/null | grep ":${FS_PORT}\|:8080" | grep -oP ':\K[0-9]+' | head -1)
        port=${port:-$FS_PORT}
        echo -e "  ${GRN}● File server is RUNNING${RST}"
        [ -n "$pid" ] && echo "    PID  : $pid"
        echo "    URL  : http://${ip}:${port}"
    else
        echo -e "  ${RED}● File server is STOPPED${RST}"
    fi
}

view_access_log() {
    if [ ! -s "$FS_LOG" ]; then
        echo "  No access log entries yet."
        echo "  (Logs appear once someone connects to the server.)"
        return
    fi

    echo ""
    echo -e "${CYN}  ── File Server Access Log (last 20 requests) ─────────────${RST}"
    tail -20 "$FS_LOG" | while IFS= read -r line; do
        echo "  $line"
    done
    echo -e "${CYN}  ───────────────────────────────────────────────────────────${RST}"
}

run_fileserver() {
    while true; do
        clear
        echo ""
        echo -e "${CYN}  ╔══════════════════════════════╗"
        echo    "  ║     QUICK FILE SHARE         ║"
        echo -e "  ╚══════════════════════════════╝${RST}"
        echo ""

        show_status
        echo ""

        echo "  [1] Start sharing a directory"
        echo "  [2] Stop the file server"
        echo "  [3] View access log"
        echo "  [0] Back to main menu"
        echo ""
        read -rp "  Choose: " choice

        case "$choice" in
            1)
                start_server
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            2)
                stop_server
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            3)
                view_access_log
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            0)
                break
                ;;
            *)
                echo "  [!] Invalid option."
                sleep 1
                ;;
        esac
    done
}
