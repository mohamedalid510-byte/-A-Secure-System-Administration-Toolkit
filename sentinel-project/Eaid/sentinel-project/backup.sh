#!/bin/bash
# =============================================================
# Sentinel Project — Module 3: Backup Utility
# IT 101 Shell and Script Programming with UNIX
# =============================================================
# DESCRIPTION:
#   Creates compressed, timestamped backups of user-selected
#   directories and maintains an audit log of all operations.
#
# FEATURES:
#   - Directory validation before backup
#   - Timestamped archive creation (.tar.gz)
#   - Automatic backup storage directory
#   - Backup history logging (backup.log)
#
# DEPENDENCIES:
#   tar, du, date, mkdir, nl
# =============================================================

# ── Configuration ─────────────────────────────────────────────
BACKUP_LOG="backup.log"
BACKUP_DEST="${HOME}/sentinel_backups"


# ══════════════════════════════════════════════════════════════
#  HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════

# Append a backup record to log file
log_backup() {
    echo "$1 | Source: $2 | Dest: $3 | Size: $4" >> "$BACKUP_LOG"
}

# Display last 20 backup records
list_backups() {
    if [ ! -f "$BACKUP_LOG" ] || [ ! -s "$BACKUP_LOG" ]; then
        echo "  No backups have been performed yet."
        return
    fi

    echo ""
    echo -e "\e[1;36m  ─── Backup History (last 20 entries) ──────────────────────\e[0m"
    echo ""

    nl -ba "$BACKUP_LOG" | tail -20 | while IFS= read -r line; do
        echo "  $line"
    done

    echo ""
    echo -e "\e[1;36m  ────────────────────────────────────────────────────────────\e[0m"
}


# ══════════════════════════════════════════════════════════════
#  BACKUP OPERATION
# ══════════════════════════════════════════════════════════════
do_backup() {
    # Ensure backup destination exists
    mkdir -p "$BACKUP_DEST"

    echo ""
    read -rp "  Enter full path of directory to back up: " src_dir

    # Remove trailing slash if present
    src_dir="${src_dir%/}"

    # Validate input
    if [ -z "$src_dir" ]; then
        echo "  [!] No path entered. Backup cancelled."
        return 1
    fi

    if [ ! -d "$src_dir" ]; then
        echo "  [!] '$src_dir' is not a valid directory."
        return 1
    fi

    # Generate archive name with timestamp
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M')

    local base_name
    base_name=$(basename "$src_dir")

    local archive_name="backup_${base_name}_${timestamp}.tar.gz"
    local dest_path="${BACKUP_DEST}/${archive_name}"

    # Display backup summary
    echo ""
    echo "  ┌─────────────────────────────────────────────────┐"
    echo "  │  Backup Preview                                 │"
    echo "  ├─────────────────────────────────────────────────┤"
    printf "  │  Source  : %-37s│\n" "$src_dir"
    printf "  │  Archive : %-37s│\n" "$archive_name"
    printf "  │  Dest    : %-37s│\n" "$BACKUP_DEST"
    echo "  └─────────────────────────────────────────────────┘"
    echo ""

    read -rp "  Proceed with backup? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "  [!] Backup cancelled."
        return 0
    fi

    # Create compressed archive
    echo "  [*] Creating backup, please wait..."
    tar -czf "$dest_path" "$src_dir" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo -e "  \e[1;31m[✗] Backup failed! Check permissions on '$src_dir'.\e[0m"
        rm -f "$dest_path"
        return 1
    fi

    # Get archive size
    local size
    size=$(du -sh "$dest_path" 2>/dev/null | awk '{print $1}')

    # Success message
    echo ""
    echo -e "  \e[1;32m╔══════════════════════════════════════╗"
    echo    "  ║   [✔] Backup Completed!              ║"
    echo -e "  ╚══════════════════════════════════════╝\e[0m"
    echo    "      Archive : $dest_path"
    echo    "      Size    : ${size:-unknown}"
    echo ""

    # Log backup operation
    log_backup \
        "$(date '+%Y-%m-%d %H:%M')" \
        "$src_dir" \
        "$dest_path" \
        "${size:-unknown}"
}


# ══════════════════════════════════════════════════════════════
#  MODULE ENTRY POINT (with internal loop)
# ══════════════════════════════════════════════════════════════
run_backup() {
    while true; do
        clear
        echo ""
        echo -e "\e[1;36m  ╔══════════════════════════════╗"
        echo    "  ║      BACKUP MANAGER          ║"
        echo -e "  ╚══════════════════════════════╝\e[0m"
        echo    "  Backup destination : $BACKUP_DEST"
        echo    "  Log file           : $BACKUP_LOG"
        echo ""
        echo    "  [1] Create new backup"
        echo    "  [2] View backup history"
        echo    "  [0] Back to main menu"
        echo ""
        read -rp "  Choose: " choice

        case "$choice" in
            1)
                do_backup
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            2)
                echo ""
                list_backups
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
