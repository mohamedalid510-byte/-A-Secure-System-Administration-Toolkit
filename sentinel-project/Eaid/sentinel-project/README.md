#  The Sentinel — Secure System Administration Toolkit

A modular, menu-driven Bash dashboard for system administrators.
Developed as part of **IT 101: Shell and Script Programming with UNIX**.

---

## Author

**Eyad Walid**
ID: 202500234
Email: [s-eyad.elkammar@zewailcity.edu.eg](mailto:s-eyad.elkammar@zewailcity.edu.eg)
Zewail City of Science and Technology
Information Technology

---

## License

This project is for **educational purposes** under IT 101 coursework.

---

## System Overview

The Sentinel is a Linux-based automation toolkit built using Bash scripting.
It simulates real-world system administration tasks such as monitoring, backups, authentication, task management, network checking, and file sharing.

### System Flow

```
Login / Sign Up → Main Menu → Select Module → Execute Task → Return to Menu
```

---

## GitHub Repository

 Clone this project from GitHub:

```bash
git clone https://github.com/USERNAME/sentinel-project.git
cd sentinel-project

---

##  Project Structure

```
sentinel-project/
├── sentinel.sh           ← Main entry point (dashboard)
├── auth.sh               ← Module 1: Sign In / Sign Up
├── monitor.sh            ← Module 2: CPU / RAM / Disk monitor
├── backup.sh             ← Module 3: Backup utility
├── tasks.sh              ← Module 4: Admin task list (CRUD)
├── uptime.sh             ← Module 5: Remote server ping monitor
├── fileserver.sh         ← Module 6: LAN file sharing
│
├── .sentinel_users       ← (auto-created) Hashed credentials (chmod 600)
├── .admin_tasks.csv      ← (auto-created) Task list storage
├── .watchlist.conf       ← (auto-created) Servers to monitor
│
├── backup.log            ← Backup operation history
├── uptime.log            ← Server downtime events
├── fileserver_access.log ← HTTP access log
└── README.md             ← Project documentation
```

---

##  Setup & Installation

### 1. System Requirements


Install required dependencies:

| Tool                          | Purpose            |
| ----------------------------- | ------------------ |
| bash (v4+)                    | Shell scripting    |
| sha256sum                     | Password hashing   |
| tar                           | Backup compression |
| ping                          | Network testing    |
| python3                       | File server        |
| bc                            | CPU calculations   |
| coreutils (top, free, df, ps) | System monitoring  |


### Install dependencies (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y python3 bc
```

---

### 2. Set Execution Permissions

```bash
chmod +x sentinel.sh auth.sh monitor.sh backup.sh tasks.sh uptime.sh fileserver.sh
```

---

### 3. Run the Application

```bash
./sentinel.sh
```

---

## Getting Started First-Time Setup (Admin Account)

1. Launch the system:

   ```bash
   ./sentinel.sh
   ```

2. Select:

   ```
   [2] Sign Up
   ```

3. Enter:

   * Username
   * Password (hidden input)

4. After successful registration:

   * You will be prompted to sign in automatically
   * The main dashboard will appear

Credentials are stored securely in:

```
.sentinel_users
```

Format:

```
username:sha256hash
```

---

## Modules Overview

---

### Module 1 — Authentication (`auth.sh`)

* Secure user registration and login
* Password hashing using SHA-256
* File protection using `chmod 600`
* Blocks access after 3 failed attempts

---

###  Module 2 — System Monitor (`monitor.sh`)

Monitors system health in real time:

* CPU usage (%)
* RAM usage (with totals)
* Disk usage (/ partition)
* Top 5 CPU-consuming processes

#### Modes:

* Single snapshot
* Auto-refresh (every 3 seconds)

#### Thresholds:

| Resource | Limit |
| -------- | ----- |
| CPU      | ≥ 80% |
| RAM      | ≥ 80% |
| Disk     | ≥ 85% |

---

###  Module 3 — Backup Utility (`backup.sh`)

* Creates compressed backups (`.tar.gz`)
* Stores backups in:

```
~/sentinel_backups/
```

* Automatically timestamps files:

```
backup_<folder>_YYYY-MM-DD_HH-MM.tar.gz
```

* Logs all operations in:

```
backup.log
```

---

###  Module 4 — Admin Task Manager (`tasks.sh`)

Stores tasks in CSV format:

```
.admin_tasks.csv
```

#### Features:

* Add new tasks
* View tasks (sorted by priority + due date)
* Update task status/priority/date
* Delete tasks with confirmation

#### Priority Levels:

* HIGH
* MED
* LOW

---

###  Module 5 — Remote Uptime Monitor (`uptime.sh`)

* Reads servers from:

```
.watchlist.conf
```

* Checks connectivity using `ping`

* Displays:

  * 🟢 UP
  * 🔴 DOWN + RTT (if available)

* Logs failures in:

```
uptime.log
```

---

###  Module 6 — LAN File Server (`fileserver.sh`)

* Shares selected directory via:

```
http://<LAN_IP>:8000
```

* Uses Python HTTP server
* Runs in background with PID tracking
* Stop/start control included
* Logs access requests in:

```
fileserver_access.log
```

 Intended for **local network only (no authentication)**

---

##  Security Features

* Passwords stored as SHA-256 hashes (no plain text)
* Critical files protected using:

```bash
chmod 600
```

* File server has no authentication (LAN-only use recommended)
* Logs used for auditing system activity

---

##  Logging System

| File                  | Purpose          |
| --------------------- | ---------------- |
| backup.log            | Backup history   |
| uptime.log            | Server failures  |
| fileserver_access.log | HTTP access logs |


---

##  Key Highlights

* Fully modular Bash system
* Real-world system administration simulation
* Secure authentication system
* Automated backups and logging
* Network monitoring tools
* Lightweight local file server

---

##  Final Note

The Sentinel demonstrates practical UNIX/Linux system administration skills including process management, automation, security practices, and system monitoring in a modular architecture.

---
