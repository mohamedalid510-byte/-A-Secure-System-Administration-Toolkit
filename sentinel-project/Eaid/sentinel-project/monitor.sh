#!/bin/bash
# =============================================================
# Sentinel Project — Module 2: System Resource Monitor
# IT 101 Shell and Script Programming with UNIX
# =============================================================
# DESCRIPTION:
#   Provides real-time system monitoring including CPU, RAM,
#   disk usage, and top running processes.
#
# FEATURES:
#   - Single snapshot mode
#   - Auto-refresh monitoring (every 3 seconds)
#   - Threshold-based warnings with colored output
#   - Ctrl+C in auto-refresh returns to menu (does NOT exit)
#   - Internal loop: stays in monitor until user chooses 0
#
# DEPENDENCIES:
#   top, free, df, ps, bc
# =============================================================

# ── Warning Thresholds (%) ────────────────────────────────────
CPU_WARN=80
MEM_WARN=80
DISK_WARN=85

# ── ANSI Colour Codes ─────────────────────────────────────────
RED="\e[1;31m"
YEL="\e[1;33m"
GRN="\e[1;32m"
CYN="\e[1;36m"
RST="\e[0m"


# ══════════════════════════════════════════════════════════════
#  COLOUR HELPER
# ══════════════════════════════════════════════════════════════

# Returns colored percentage based on threshold
color_pct() {
    local val="$1"
    local warn="$2"

    if [ "$val" -ge "$warn" ]; then
        echo -e "${RED}${val}%${RST}"
    elif [ "$val" -ge $((warn - 15)) ]; then
        echo -e "${YEL}${val}%${RST}"
    else
        echo -e "${GRN}${val}%${RST}"
    fi
}


# ══════════════════════════════════════════════════════════════
#  DATA COLLECTION FUNCTIONS
# ══════════════════════════════════════════════════════════════

# Get CPU usage percentage
get_cpu_usage() {
    local idle
    idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%us,')

    # Fallback for alternative top formats
    if [ -z "$idle" ]; then
        idle=$(top -bn1 | grep -i "cpu" | head -1 \
               | grep -oP '[0-9.]+(?=.*id)' | tail -1)
    fi

    local usage
    usage=$(echo "100 - ${idle:-0}" | bc 2>/dev/null | cut -d'.' -f1)
    echo "${usage:-0}"
}

# Get RAM usage percentage
get_mem_usage() {
    local total used
    read -r total used <<< "$(free -m | awk '/^Mem:/{print $2, $3}')"

    if [ "${total:-0}" -gt 0 ]; then
        echo $(( (used * 100) / total ))
    else
        echo 0
    fi
}

# Get detailed RAM info
get_mem_details() {
    free -h | awk '/^Mem:/{printf "Total: %s  |  Used: %s  |  Free: %s", $2, $3, $4}'
}

# Get disk usage percentage for root (/)
get_disk_usage() {
    df / | awk 'NR==2{print $5}' | tr -d '%'
}

# Get detailed disk info
get_disk_details() {
    df -h / | awk 'NR==2{printf "Total: %s  |  Used: %s  |  Free: %s", $2, $3, $4}'
}


# ══════════════════════════════════════════════════════════════
#  SNAPSHOT DISPLAY
# ══════════════════════════════════════════════════════════════

# Display system monitoring dashboard
print_monitor_snapshot() {
    local cpu mem disk
    cpu=$(get_cpu_usage)
    mem=$(get_mem_usage)
    disk=$(get_disk_usage)

    local cpu_col mem_col disk_col
    cpu_col=$(color_pct "$cpu" "$CPU_WARN")
    mem_col=$(color_pct "$mem" "$MEM_WARN")
    disk_col=$(color_pct "$disk" "$DISK_WARN")

    echo -e "${CYN}  ╔══════════════════════════════════════════════╗"
    echo    "  ║        SYSTEM HEALTH MONITOR                ║"
    echo -e "  ╚══════════════════════════════════════════════╝${RST}"
    echo    "  Snapshot time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo    ""

    # CPU
    echo -e "  ${CYN}▌ CPU Usage   :${RST} ${cpu_col}"
    _draw_bar "$cpu" 100
    if [ "$cpu" -ge "$CPU_WARN" ]; then
        echo -e "  ${RED}  ⚠  WARNING: CPU usage is critically high!${RST}"
    fi
    echo ""

    # Memory
    echo -e "  ${CYN}▌ RAM Usage   :${RST} ${mem_col}"
    _draw_bar "$mem" 100
    echo "    $(get_mem_details)"
    if [ "$mem" -ge "$MEM_WARN" ]; then
        echo -e "  ${RED}  ⚠  WARNING: Memory usage is critically high!${RST}"
    fi
    echo ""

    # Disk
    echo -e "  ${CYN}▌ Disk (/)    :${RST} ${disk_col}"
    _draw_bar "$disk" 100
    echo "    $(get_disk_details)"
    if [ "$disk" -ge "$DISK_WARN" ]; then
        echo -e "  ${RED}  ⚠  WARNING: Disk usage is critically high!${RST}"
    fi
    echo ""

    # Top Processes
    echo -e "  ${CYN}▌ Top 5 Processes by CPU:${RST}"
    echo "  ─────────────────────────────────────────────"

    ps aux --sort=-%cpu 2>/dev/null | \
        awk 'NR>1 && NR<=6 {
            printf "  %-25s  CPU: %5s%%  MEM: %5s%%\n", $11, $3, $4
        }'
    echo ""
}

# Draw ASCII progress bar
_draw_bar() {
    local val="$1"
    local max="$2"
    local width=20

    local filled=$(( (val * width) / max ))
    local empty=$(( width - filled ))

    local bar="  ["
    local i
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done
    bar+="]"

    echo "$bar"
}


# ══════════════════════════════════════════════════════════════
#  MODULE ENTRY POINT (with internal loop)
# ══════════════════════════════════════════════════════════════

run_monitor() {
    while true; do
        clear
        echo ""
        echo -e "  ${CYN}Monitor Mode — choose display type:${RST}"
        echo "  [1] Single snapshot"
        echo "  [2] Auto-refresh (every 3 seconds) — press Ctrl+C to stop"
        echo "  [0] Back to main menu"
        echo ""
        read -rp "  Choose: " mode

        case "$mode" in
            1)
                clear
                print_monitor_snapshot
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            2)
                echo -e "  ${YEL}Starting auto-refresh... Press Ctrl+C to stop.${RST}"
                sleep 1

                stop_refresh=0
                trap 'stop_refresh=1' INT
                while [ $stop_refresh -eq 0 ]; do
                    clear
                    print_monitor_snapshot
                    echo -e "  ${YEL}[Auto-refresh every 3s — Ctrl+C to stop]${RST}"
                    sleep 3
                done
                trap - INT
                # After auto-refresh, stay in monitor menu (no extra pause needed)
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
