#!/bin/bash
# =============================================================
# tasks.sh — Module 4: Admin Task List (Full CRUD)
# =============================================================
# PURPOSE:
#   Implements a lightweight task manager for system admins.
#   Tasks are stored in a simple CSV file for portability.
#
# CSV FORMAT (.admin_tasks.csv):
#   ID,Title,Priority,DueDate,Status
#   1,Fix login bug,HIGH,2026-04-20,PENDING
#
# FIELDS:
#   ID       → unique auto-increment integer
#   Title    → short description (commas removed)
#   Priority → HIGH | MED | LOW
#   DueDate  → YYYY-MM-DD or "N/A"
#   Status   → PENDING | DONE
#
# FEATURES:
#   • View tasks (sorted by priority then due date)
#   • Add new tasks
#   • Update existing tasks (status, priority, date)
#   • Delete tasks safely with confirmation
#
# TOOLS USED:
#   awk, sed, sort, grep, printf
# =============================================================

# ── Configuration ─────────────────────────────────────────────
TASKS_FILE=".admin_tasks.csv"   # Hidden storage file


# ══════════════════════════════════════════════════════════════
# INITIALIZATION
# ══════════════════════════════════════════════════════════════

# Ensure tasks file exists with secure permissions
init_tasks() {
    if [ ! -f "$TASKS_FILE" ]; then
        touch "$TASKS_FILE"
        chmod 600 "$TASKS_FILE"
        echo "  [i] Task file created: $TASKS_FILE"
    fi
}

# Get next available task ID
next_id() {
    if [ ! -s "$TASKS_FILE" ]; then
        echo 1
    else
        awk -F',' '{print $1}' "$TASKS_FILE" \
            | sort -n \
            | tail -1 \
            | xargs -I{} expr {} + 1
    fi
}


# ══════════════════════════════════════════════════════════════
# ADD TASK
# ══════════════════════════════════════════════════════════════
add_task() {
    echo ""
    echo -e "\e[1;36m  ── Add New Task ──────────────────────────\e[0m"

    read -rp "  Task title      : " title
    if [ -z "$title" ]; then
        echo "  [!] Title cannot be empty."
        return 1
    fi

    # Remove commas to preserve CSV structure
    title="${title//,/}"

    echo "  Priority options: HIGH | MED | LOW"
    read -rp "  Priority        : " priority
    priority=$(echo "$priority" | tr '[:lower:]' '[:upper:]')

    # Validate priority
    if [[ "$priority" != "HIGH" && "$priority" != "MED" && "$priority" != "LOW" ]]; then
        echo "  [!] Invalid priority — defaulting to MED."
        priority="MED"
    fi

    read -rp "  Due date (YYYY-MM-DD, or press Enter to skip): " due_date

    if [ -z "$due_date" ]; then
        due_date="N/A"
    elif ! [[ "$due_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "  [!] Invalid date format. Storing as N/A."
        due_date="N/A"
    fi

    local id
    id=$(next_id)

    echo "${id},${title},${priority},${due_date},PENDING" >> "$TASKS_FILE"

    echo ""
    echo -e "  \e[1;32m[✔] Task #${id} added successfully.\e[0m"
}


# ══════════════════════════════════════════════════════════════
# VIEW TASKS
# ══════════════════════════════════════════════════════════════
view_tasks() {
    if [ ! -s "$TASKS_FILE" ]; then
        echo ""
        echo "  No tasks found. Use [2] Add new task to get started."
        return
    fi

    echo ""
    echo -e "\e[1;36m  ── Task List (sorted by priority and date) ───\e[0m"
    echo ""

    printf "  %-4s %-32s %-6s %-12s %-10s\n" "ID" "TITLE" "PRIO" "DUE DATE" "STATUS"
    echo    "  ──────────────────────────────────────────────────────────────"

    # Sort by priority (HIGH→LOW) then due date
    awk -F',' '{
        if ($3=="HIGH")      p=1
        else if ($3=="MED")  p=2
        else                 p=3
        printf "%d,%s\n", p, $0
    }' "$TASKS_FILE" \
        | sort -t',' -k1,1n -k5,5 \
        | cut -d',' -f2- \
        | while IFS=',' read -r id title priority due_date status; do

            case "$priority" in
                HIGH) pcol="\e[1;31m" ;;
                MED)  pcol="\e[1;33m" ;;
                LOW)  pcol="\e[1;32m" ;;
                *)    pcol="\e[0m"    ;;
            esac

            if [ "$status" = "DONE" ]; then
                scol="\e[1;32m"
            else
                scol="\e[1;33m"
            fi

            printf "  %-4s %-32s ${pcol}%-6s\e[0m %-12s ${scol}%-10s\e[0m\n" \
                   "$id" "${title:0:31}" "$priority" "$due_date" "$status"
        done

    echo    "  ──────────────────────────────────────────────────────────────"
    echo ""

    local total pending done
    total=$(wc -l < "$TASKS_FILE")
    pending=$(grep -c ",PENDING$" "$TASKS_FILE" 2>/dev/null || echo 0)
    done=$(grep -c ",DONE$" "$TASKS_FILE" 2>/dev/null || echo 0)

    echo -e "  Total: $total  |  \e[1;33mPending: $pending\e[0m  |  \e[1;32mDone: $done\e[0m"
}


# ══════════════════════════════════════════════════════════════
# UPDATE TASK
# ══════════════════════════════════════════════════════════════
update_task() {
    view_tasks
    echo ""
    read -rp "  Enter task ID to update (or 0 to cancel): " id
    [ "$id" = "0" ] && return

    if ! grep -q "^${id}," "$TASKS_FILE"; then
        echo "  [!] Task #${id} not found."
        return 1
    fi

    echo ""
    echo "  What would you like to update?"
    echo "  [1] Mark as DONE"
    echo "  [2] Change Priority"
    echo "  [3] Change Due Date"
    echo "  [0] Cancel"
    echo ""
    read -rp "  Choose: " field

    case "$field" in
        1)
            sed -i "s/^${id},\(.*\),PENDING$/${id},\1,DONE/" "$TASKS_FILE"
            echo -e "  \e[1;32m[✔] Task #${id} marked as DONE.\e[0m"
            ;;

        2)
            echo "  New priority (HIGH | MED | LOW):"
            read -rp "  > " new_prio
            new_prio=$(echo "$new_prio" | tr '[:lower:]' '[:upper:]')

            if [[ "$new_prio" != "HIGH" && "$new_prio" != "MED" && "$new_prio" != "LOW" ]]; then
                echo "  [!] Invalid priority."
                return 1
            fi

            awk -F',' -v id="$id" -v np="$new_prio" \
                'BEGIN{OFS=","} $1==id{$3=np} {print}' \
                "$TASKS_FILE" > "${TASKS_FILE}.tmp" \
                && mv "${TASKS_FILE}.tmp" "$TASKS_FILE"

            echo -e "  \e[1;32m[✔] Priority updated.\e[0m"
            ;;

        3)
            read -rp "  New due date (YYYY-MM-DD): " new_date

            if ! [[ "$new_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                echo "  [!] Invalid date format."
                return 1
            fi

            awk -F',' -v id="$id" -v nd="$new_date" \
                'BEGIN{OFS=","} $1==id{$4=nd} {print}' \
                "$TASKS_FILE" > "${TASKS_FILE}.tmp" \
                && mv "${TASKS_FILE}.tmp" "$TASKS_FILE"

            echo -e "  \e[1;32m[✔] Due date updated.\e[0m"
            ;;

        0) return ;;
        *) echo "  [!] Invalid choice." ;;
    esac
}


# ══════════════════════════════════════════════════════════════
# DELETE TASK
# ══════════════════════════════════════════════════════════════
delete_task() {
    view_tasks
    echo ""
    read -rp "  Enter task ID to DELETE (or 0 to cancel): " id
    [ "$id" = "0" ] && return

    if ! grep -q "^${id}," "$TASKS_FILE"; then
        echo "  [!] Task not found."
        return 1
    fi

    echo ""
    echo "  Task to be deleted:"
    grep "^${id}," "$TASKS_FILE" | \
        awk -F',' '{printf "    #%s — %s [%s]\n", $1,$2,$3}'

    echo ""
    read -rp "  Confirm deletion (y/N): " confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sed -i "/^${id},/d" "$TASKS_FILE"
        echo -e "  \e[1;32m[✔] Task deleted.\e[0m"
    else
        echo "  [i] Cancelled."
    fi
}


# ══════════════════════════════════════════════════════════════
# MODULE ENTRY POINT (with internal loop)
# ══════════════════════════════════════════════════════════════
run_tasks() {
    init_tasks

    while true; do
        clear
        echo ""
        echo -e "\e[1;36m  ╔══════════════════════════════╗"
        echo    "  ║      ADMIN TASK LIST         ║"
        echo -e "  ╚══════════════════════════════╝\e[0m"
        echo    "  [1] View all tasks"
        echo    "  [2] Add new task"
        echo    "  [3] Update a task"
        echo    "  [4] Delete a task"
        echo    "  [0] Back to main menu"
        echo ""
        read -rp "  Choose: " choice

        case "$choice" in
            1)
                view_tasks
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            2)
                add_task
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            3)
                update_task
                echo ""
                read -rp "  Press [Enter] to continue..." _
                ;;
            4)
                delete_task
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
