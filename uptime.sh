#!/bin/bash
# =============================================================
# uptime.sh — Module 5: Remote Uptime Monitor (HTTP/HTTPS + ping fallback)
# =============================================================
# PURPOSE:
#   Checks remote servers using HTTP/HTTPS (curl) or ping.
#   Automatically adapts to internet availability.
#   Works both locally (localhost/gateway) and on the internet.
#   Maintains watchlist and logs downtime events.
#
# IMPLEMENTATION:
#   - Uses curl to test HTTP/HTTPS (port 80/443)
#   - Falls back to ping if curl fails
#   - Auto-detects internet connectivity and sets default watchlist
#   - Color-coded output (UP/DOWN)
#   - Logs failures with timestamp to uptime.log
# =============================================================

WATCHLIST=".watchlist.conf"
UPTIME_LOG="uptime.log"

RED="\e[1;31m"
GRN="\e[1;32m"
YEL="\e[1;33m"
CYN="\e[1;36m"
RST="\e[0m"


# ══════════════════════════════════════════════════════════════
#  INITIALISATION
# ══════════════════════════════════════════════════════════════

# Helper: check if we have internet (HTTP/HTTPS reachable)
has_internet() {
    curl -s -o /dev/null --connect-timeout 3 --max-time 5 http://google.com 2>/dev/null && return 0
    curl -s -o /dev/null --connect-timeout 3 --max-time 5 https://google.com 2>/dev/null && return 0
    ping -c 1 -W 2 8.8.8.8 &>/dev/null && return 0
    return 1
}

init_watchlist() {
    if [ ! -f "$WATCHLIST" ]; then
        if has_internet; then
            # Internet available – use public servers
            cat > "$WATCHLIST" <<'EOF'
# Sentinel Watchlist — one hostname or IP per line.
# Lines starting with # are ignored.
google.com
8.8.8.8
github.com
EOF
            echo -e "  ${GRN}[i] Internet detected – using public servers.${RST}"
        else
            # No internet – use local targets that respond to ping
            # Get default gateway (if any)
            local gateway
            gateway=$(ip route | grep default | awk '{print $3}' | head -1)
            cat > "$WATCHLIST" <<EOF
# Sentinel Watchlist — one hostname or IP per line.
# No internet detected – using local targets.
localhost
127.0.0.1
${gateway:-192.168.1.1}
EOF
            echo -e "  ${YEL}[i] No internet – using local targets for demo.${RST}"
        fi
        echo -e "  ${YEL}[i] Created default watchlist at: $WATCHLIST${RST}"
    fi
}

log_downtime() {
    local server="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | DOWN | $server" >> "$UPTIME_LOG"
}


# ══════════════════════════════════════════════════════════════
#  CHECK ONE SERVER USING HTTP/HTTPS (curl) WITH PING FALLBACK
# ══════════════════════════════════════════════════════════════

check_server() {
    local server="$1"
    local status="DOWN"
    local response=""

    # Try HTTP first
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 5 "http://$server" 2>/dev/null)

    if [[ "$http_code" =~ ^[0-9]{3}$ ]] && [ "$http_code" -ne 000 ]; then
        status="UP"
        response="HTTP $http_code"
    else
        # Try HTTPS
        local https_code
        https_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 --max-time 5 "https://$server" 2>/dev/null)
        if [[ "$https_code" =~ ^[0-9]{3}$ ]] && [ "$https_code" -ne 000 ]; then
            status="UP"
            response="HTTPS $https_code"
        fi
    fi

    # Fallback to ping (works for local addresses or if curl fails)
    if [ "$status" = "DOWN" ]; then
        local ping_result
        ping_result=$(ping -c 1 -W 2 "$server" 2>/dev/null)
        if [ $? -eq 0 ]; then
            status="UP"
            local rtt
            rtt=$(echo "$ping_result" | grep -oP 'time=\K[0-9.]+' | head -1)
            response="ping ${rtt:-?} ms"
        fi
    fi

    if [ "$status" = "UP" ]; then
        echo -e "  ${GRN}[UP  ]${RST}  $(printf '%-32s' "$server")  $response"
    else
        echo -e "  ${RED}[DOWN]${RST}  $(printf '%-32s' "$server")  *** UNREACHABLE ***"
        log_downtime "$server"
    fi
}


# ══════════════════════════════════════════════════════════════
#  SCAN ALL SERVERS
# ══════════════════════════════════════════════════════════════

run_scan() {
    local count=0 up=0 down=0

    echo ""
    echo -e "${CYN}  ── Remote Service Status (HTTP/HTTPS + ping fallback) ─────${RST}"
    printf   "  %-6s  %-32s  %s\n" "STATUS" "HOST / IP" "RESPONSE"
    echo     "  ──────────────────────────────────────────────────────────"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        check_server "$line"
        count=$((count + 1))

        # Count UP/DOWN without re-pinging
        local tmp_result
        tmp_result=$(check_server "$line" 2>&1)
        if [[ "$tmp_result" == *"[UP  ]"* ]]; then
            up=$((up + 1))
        else
            down=$((down + 1))
        fi
    done < "$WATCHLIST"

    echo     "  ──────────────────────────────────────────────────────────"
    echo -e  "  Scanned ${count} host(s)  |  ${GRN}${up} UP${RST}  |  ${RED}${down} DOWN${RST}"
    if [ "$down" -gt 0 ]; then
        echo "  ⚠  Failures have been logged to: $UPTIME_LOG"
    fi
}


# ══════════════════════════════════════════════════════════════
#  MANAGE WATCHLIST
# ══════════════════════════════════════════════════════════════

edit_watchlist() {
    echo ""
    echo -e "${CYN}  ── Current Watchlist: $WATCHLIST ──${RST}"
    echo    "  ──────────────────────────────────────"
    cat "$WATCHLIST"
    echo    "  ──────────────────────────────────────"
    echo ""
    echo    "  [1] Add a server"
    echo    "  [2] Remove a server"
    echo    "  [0] Cancel"
    read -rp "  Choose: " choice

    case "$choice" in
        1)
            read -rp "  Enter hostname or IP to add: " new_server
            if [ -n "$new_server" ]; then
                if grep -qFx "$new_server" "$WATCHLIST"; then
                    echo "  [!] '$new_server' is already in the watchlist."
                else
                    echo "$new_server" >> "$WATCHLIST"
                    echo -e "  ${GRN}[✔] '$new_server' added to watchlist.${RST}"
                fi
            else
                echo "  [!] No input entered."
            fi
            ;;
        2)
            read -rp "  Enter exact hostname or IP to remove: " del_server
            if grep -qFx "$del_server" "$WATCHLIST"; then
                sed -i "/^${del_server}$/d" "$WATCHLIST"
                echo -e "  ${GRN}[✔] '$del_server' removed from watchlist.${RST}"
            else
                echo "  [!] '$del_server' not found in watchlist."
            fi
            ;;
        0)
            return
            ;;
        *)
            echo "  [!] Invalid option."
            ;;
    esac
}


# ══════════════════════════════════════════════════════════════
#  VIEW UPTIME LOG
# ══════════════════════════════════════════════════════════════

view_log() {
    if [ ! -s "$UPTIME_LOG" ]; then
        echo "  No downtime events have been recorded yet."
        return
    fi

    echo ""
    echo -e "${CYN}  ── Downtime Log (last 20 entries) ────────────────────────${RST}"
    tail -20 "$UPTIME_LOG" | while IFS= read -r line; do
        echo -e "  ${RED}$line${RST}"
    done
    echo -e "${CYN}  ───────────────────────────────────────────────────────────${RST}"
    echo ""

    local total
    total=$(wc -l < "$UPTIME_LOG")
    echo "  Total failures on record: $total"
}


# ══════════════════════════════════════════════════════════════
#  MODULE ENTRY POINT (with internal loop)
# ══════════════════════════════════════════════════════════════

run_uptime() {
    init_watchlist

    while true; do
        clear
        echo ""
        echo -e "${CYN}  ╔══════════════════════════════╗"
        echo    "  ║   REMOTE UPTIME MONITOR      ║"
        echo -e "  ╚══════════════════════════════╝${RST}"
        echo    "  [1] Scan all servers now"
        echo    "  [2] Manage watchlist (add/remove)"
        echo    "  [3] View downtime log"
        echo    "  [0] Back to main menu"
        echo ""
        read -rp "  Choose: " choice

        case "$choice" in
            1)
                run_scan
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            2)
                edit_watchlist
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            3)
                view_log
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
