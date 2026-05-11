#!/bin/bash
# =============================================================
# Sentinel Project — Module 1: Secure Authentication
# IT 101 Shell and Script Programming with UNIX
# =============================================================
# DESCRIPTION:
#   Provides user authentication for The Sentinel system.
#   Supports secure Sign Up and Sign In functionality.
#
# SECURITY DESIGN:
#   - Passwords are hashed using SHA-256 (never stored in plain text)
#   - Credentials stored in a hidden file (.sentinel_users)
#   - File permissions enforced to 600 (owner-only access)
#
# INTERFACE:
#   run_auth() is called by sentinel.sh
#   Returns:
#     0 → authentication successful
#     1 → authentication failed
# =============================================================

# ── Configuration ─────────────────────────────────────────────
USERS_FILE=".sentinel_users"
MAX_AUTH_ATTEMPTS=3


# ══════════════════════════════════════════════════════════════
#  HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════

# Initialize user storage file and enforce permissions
init_users_file() {
    if [ ! -f "$USERS_FILE" ]; then
        touch "$USERS_FILE"
        chmod 600 "$USERS_FILE"
        echo "  [i] Created new users file: $USERS_FILE"
    fi

    chmod 600 "$USERS_FILE"
}

# Generate SHA-256 hash for a given password
hash_password() {
    echo -n "$1" | sha256sum | awk '{print $1}'
}

# Validate username format (3–20 chars, alphanumeric, _ or -)
validate_username() {
    local uname="$1"

    if [ -z "$uname" ]; then
        echo "  [!] Username cannot be empty."
        return 1
    fi

    if [ "${#uname}" -lt 3 ] || [ "${#uname}" -gt 20 ]; then
        echo "  [!] Username must be 3–20 characters."
        return 1
    fi

    if ! [[ "$uname" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "  [!] Username may only contain letters, digits, _ or -."
        return 1
    fi

    return 0
}

# Validate password strength (minimum length)
validate_password() {
    local pass="$1"

    if [ -z "$pass" ]; then
        echo "  [!] Password cannot be empty."
        return 1
    fi

    if [ "${#pass}" -lt 6 ]; then
        echo "  [!] Password must be at least 6 characters."
        return 1
    fi

    return 0
}


# ══════════════════════════════════════════════════════════════
#  SIGN UP FUNCTION
# ══════════════════════════════════════════════════════════════
sign_up() {
    echo ""
    echo "  ╔══════════════════════════╗"
    echo "  ║        SIGN UP           ║"
    echo "  ╚══════════════════════════╝"
    echo ""

    read -rp "  Enter new username : " username
    validate_username "$username" || return 1

    # Check if username already exists
    if grep -q "^${username}:" "$USERS_FILE" 2>/dev/null; then
        echo "  [!] Username '$username' is already taken. Please sign in."
        return 1
    fi

    # Read password securely (hidden input)
    read -rsp "  Enter password (min 6 chars) : " password
    echo ""
    validate_password "$password" || return 1

    read -rsp "  Confirm password             : " password2
    echo ""

    if [ "$password" != "$password2" ]; then
        echo "  [!] Passwords do not match. Please try again."
        return 1
    fi

    # Store hashed credentials
    local hashed
    hashed=$(hash_password "$password")
    echo "${username}:${hashed}" >> "$USERS_FILE"

    echo ""
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║  [✔] Account created successfully!  ║"
    echo "  ║      You can now sign in.            ║"
    echo "  ╚══════════════════════════════════════╝"
    return 0
}


# ══════════════════════════════════════════════════════════════
#  SIGN IN FUNCTION
# ══════════════════════════════════════════════════════════════
sign_in() {
    echo ""
    echo "  ╔══════════════════════════╗"
    echo "  ║        SIGN IN           ║"
    echo "  ╚══════════════════════════╝"
    echo ""

    read -rp  "  Username : " username
    read -rsp "  Password : " password
    echo ""

    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "  [!] Both username and password are required."
        return 1
    fi

    # Hash input password and compare with stored hash
    local hashed
    hashed=$(hash_password "$password")

    local stored
    stored=$(grep "^${username}:" "$USERS_FILE" 2>/dev/null | cut -d':' -f2)

    if [ -n "$stored" ] && [ "$hashed" = "$stored" ]; then
        echo ""
        echo -e "  \e[1;32m[✔] Welcome back, ${username}!\e[0m"

        export SENTINEL_USER="$username"
        return 0
    else
        echo -e "  \e[1;31m[✗] Invalid username or password.\e[0m"
        return 1
    fi
}


# ══════════════════════════════════════════════════════════════
#  MAIN AUTH INTERFACE
# ══════════════════════════════════════════════════════════════
run_auth() {
    init_users_file

    echo ""
    echo "  ┌─────────────────────────────┐"
    echo "  │  🛡️  THE SENTINEL — AUTH     │"
    echo "  └─────────────────────────────┘"
    echo "  [1] Sign In"
    echo "  [2] Sign Up"
    echo "  [0] Exit"
    echo ""
    read -rp "  Choose an option: " choice

    case "$choice" in
        1)
            sign_in
            return $?
            ;;
        2)
            sign_up
            if [ $? -eq 0 ]; then
                echo ""
                echo "  Please sign in with your new account."
                sign_in
                return $?
            fi
            return 1
            ;;
        0)
            echo "  Goodbye."
            exit 0
            ;;
        *)
            echo "  [!] Invalid option. Please choose 0, 1, or 2."
            return 1
            ;;
    esac
}
