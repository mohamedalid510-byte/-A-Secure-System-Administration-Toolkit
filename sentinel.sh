#!/bin/bash
# =============================================================
# Sentinel Project — Secure System Administration Toolkit
# IT 101 Shell and Script Programming with UNIX
# Author: Eyad Walid 202500234
# =============================================================
# DESCRIPTION:
#   Main entry point for "The Sentinel" system.
#   Handles user authentication and provides access to all
#   administrative modules through a unified dashboard.
#
# ARCHITECTURE:
#   The system is modular. Each feature is implemented in a
#   separate script and loaded dynamically using 'source'.
#   Modules:
#     - auth.sh        (Authentication)
#     - monitor.sh     (System Monitoring)
#     - backup.sh      (Backup Management)
#     - tasks.sh       (Task Management)
#     - uptime.sh      (Remote Monitoring)
#     - fileserver.sh  (File Sharing)
# =============================================================

# ── Ensure execution from project directory ───────────────────
# This guarantees all relative paths (logs, configs) are correct.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || {
    echo "[!] Cannot access project directory: $SCRIPT_DIR"
    exit 1
}

# ── Load required modules ─────────────────────────────────────
# Each module is sourced to make its functions available.
for module in auth.sh monitor.sh backup.sh tasks.sh uptime.sh fileserver.sh; do
    if [ ! -f "$SCRIPT_DIR/$module" ]; then
        echo "[!] Missing module: $module"
        echo "    Ensure all project files are in the same directory."
        exit 1
    fi
    source "$SCRIPT_DIR/$module"
done


# ══════════════════════════════════════════════════════════════
#  DISPLAY FUNCTIONS
# ══════════════════════════════════════════════════════════════

# Displays system header and session info
print_banner() {
    clear
    echo ""
    echo -e "\e[1;36m  ╔════════════════════════════════════════╗"
    echo    "  ║          🛡️  THE SENTINEL  🛡️            ║"
    echo    "  ║     Secure System Admin Toolkit         ║"
    echo -e "  ╚════════════════════════════════════════╝\e[0m"

    echo -e "  Logged in as: \e[1;33m${SENTINEL_USER}\e[0m"
    echo    "  $(date '+%A, %d %B %Y  %H:%M:%S')"
    echo ""
}

# Displays main menu options
print_menu() {
    echo "  ┌─────────────────────────────────────┐"
    echo "  │           ADMIN MENU                │"
    echo "  ├─────────────────────────────────────┤"
    echo "  │  [1]  Monitor System Health         │"
    echo "  │  [2]  Manage Backups                │"
    echo "  │  [3]  Admin Task List               │"
    echo "  │  [4]  Monitor Remote Services       │"
    echo "  │  [5]  Quick File Share              │"
    echo "  │  [0]  Logout                        │"
    echo "  └─────────────────────────────────────┘"
    echo ""
}


# ══════════════════════════════════════════════════════════════
#  AUTHENTICATION PHASE
# ══════════════════════════════════════════════════════════════
# Allows a maximum of 3 login attempts before terminating.

MAX_ATTEMPTS=3
attempt=0
logged_in=false

while [ $attempt -lt $MAX_ATTEMPTS ]; do
    clear
    echo ""
    echo -e "\e[1;36m  ╔════════════════════════════════════════╗"
    echo    "  ║          🛡️  THE SENTINEL  🛡️            ║"
    echo -e "  ╚════════════════════════════════════════╝\e[0m"

    # Execute authentication (defined in auth.sh)
    run_auth

    if [ $? -eq 0 ]; then
        logged_in=true
        break
    fi

    attempt=$(( attempt + 1 ))
    remaining=$(( MAX_ATTEMPTS - attempt ))

    if [ $remaining -gt 0 ]; then
        echo ""
        echo -e "  \e[1;31m[!] Authentication failed. ${remaining} attempt(s) remaining.\e[0m"
        sleep 1
    fi
done

# ── Access control: deny after failed attempts ────────────────
if [ "$logged_in" = false ]; then
    echo ""
    echo -e "\e[1;31m  ╔══════════════════════════════════════╗"
    echo    "  ║  [✗] Too many failed attempts.       ║"
    echo    "  ║      Access denied. Goodbye.         ║"
    echo -e "  ╚══════════════════════════════════════╝\e[0m"
    echo ""
    exit 1
fi


# ══════════════════════════════════════════════════════════════
#  MAIN DASHBOARD LOOP
# ══════════════════════════════════════════════════════════════
# Runs continuously until the user selects logout.

while true; do
    print_banner
    print_menu

    read -rp "  Enter your choice: " option
    echo ""

    case "$option" in
        1)
            # System Monitoring Module
            run_monitor
            ;;
        2)
            # Backup Management Module
            run_backup
            ;;
        3)
            # Task Management Module
            run_tasks
            ;;
        4)
            # Remote Uptime Monitoring Module
            run_uptime
            ;;
        5)
            # File Sharing Module
            run_fileserver
            ;;
        0)
            # Exit system
            echo -e "  \e[1;32m[✔] Logged out. Goodbye, ${SENTINEL_USER}!\e[0m"
            echo ""
            exit 0
            ;;
        *)
            # Input validation
            echo -e "  \e[1;31m[!] Invalid option. Please choose 0–5.\e[0m"
            ;;
    esac

    echo ""
    read -rp "  Press [Enter] to return to the main menu..." _
done
