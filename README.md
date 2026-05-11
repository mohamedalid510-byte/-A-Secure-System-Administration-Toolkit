# The Sentinel — Secure System Administration Toolkit

A modular, menu-driven Bash toolkit designed for Linux system administration tasks.

Developed as part of the **IT 101 — Shell and Script Programming with UNIX** course at Zewail City of Science and Technology.

---

#  Project Overview

The Sentinel simulates real-world Linux administration operations through an interactive terminal dashboard built entirely with Bash scripting.

The toolkit provides modules for:

-  Authentication & Access Control
- System Monitoring
- Automated Backups
- Administrative Task Management
- Network/Uptime Monitoring
- LAN File Sharing

---

#  System Architecture

```text
Login / Sign Up
       ↓
 Main Dashboard
       ↓
 Select Module
       ↓
 Execute Operation
       ↓
 Return to Dashboard
```

---

#  Authors

## Eyad Walid Elkammar
- ID: 202500234
- Email: s-eyad.elkammar@zewailcity.edu.eg

## Mohamed Ali
- ID: 202505177
- Email: s-mohamed.dabash@zewailcity.edu.eg

## Youssef Alaa 
- ID: 202500937
- Email: s-youssef.ibrhim@zewailcity.edu.eg

### Institution
Zewail City of Science and Technology  
Information Technology Program

---

#  Project Structure

```text
sentinel-project/
│
├── sentinel.sh
├── auth.sh
├── monitor.sh
├── backup.sh
├── tasks.sh
├── uptime.sh
├── fileserver.sh
│
├── .sentinel_users
├── .admin_tasks.csv
├── .watchlist.conf
│
├── backup.log
├── uptime.log
├── fileserver_access.log
│
└── README.md
```

---

#  Features

##  Authentication System
- User Sign Up & Login
- SHA-256 password hashing
- Hidden password input
- Login attempt protection
- Secure credential storage

---

##  System Monitoring
Monitor system resources in real time:

- CPU Usage
- RAM Usage
- Disk Usage
- Top Running Processes

### Includes
- Single snapshot mode
- Auto-refresh monitoring mode
- Threshold alerts

---

##  Backup Utility
- Creates compressed `.tar.gz` backups
- Automatic timestamp naming
- Backup history logging
- Organized backup storage

Backup location:

```bash
~/sentinel_backups/
```

---

##  Admin Task Manager
Manage administrative tasks using CSV storage.

### Supported Operations
- Add Tasks
- View Tasks
- Update Tasks
- Delete Tasks

### Priority Levels
- HIGH
- MED
- LOW

---

##  Remote Uptime Monitor
Monitor remote servers using ICMP ping.

### Features
- Reads targets from configuration file
- Detects UP/DOWN status
- RTT response monitoring
- Failure logging

---

##  LAN File Server
Share directories locally through a lightweight HTTP server.

### Features
- Python-based HTTP server
- Background execution
- Start/Stop controls
- Access logging

Server Example:

```bash
http://<LAN_IP>:8000
```

> Intended for local network use only.

---

#  Installation & Setup

##  Clone Repository

```bash
git clone https://github.com/eyad-walid-elkammar/IT-101-A-Secure-System-Administration-Toolkit.git
cd sentinel-project
```

---

##  Install Dependencies

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y python3 bc
```

---

#  Required Tools

| Tool | Purpose |
|------|----------|
| bash | Shell scripting |
| sha256sum | Password hashing |
| tar | Backup compression |
| ping | Network testing |
| python3 | HTTP file server |
| bc | CPU calculations |
| coreutils | System monitoring |

---

##  Grant Execution Permissions

```bash
chmod +x sentinel.sh auth.sh monitor.sh backup.sh tasks.sh uptime.sh fileserver.sh
```

---

##  Run the Application

```bash
./sentinel.sh
```

---

#  First-Time Usage

## Create Admin Account

1. Launch the application:

```bash
./sentinel.sh
```

2. Select:

```text
[2] Sign Up
```

3. Enter:
- Username
- Password

4. Login to access the dashboard.

---

#  Security Features

- SHA-256 password hashing
- Protected credential files
- Login attempt limitation
- Log-based auditing
- Modular isolated scripts

Protected files use:

```bash
chmod 600
```

---

#  Logging System

| File | Description |
|------|-------------|
| backup.log | Backup history |
| uptime.log | Server failure logs |
| fileserver_access.log | HTTP access logs |

---

#  Key Highlights

- Modular Bash architecture
- Real-world Linux administration simulation
- Secure authentication system
- Automated backup management
- Resource monitoring dashboard
- Network monitoring utilities
- Lightweight LAN file server

---

#  Educational Purpose

This project was developed for academic and educational purposes as part of the IT 101 coursework.

The Sentinel demonstrates practical Linux/UNIX administration concepts including:

- Shell scripting
- Process management
- System automation
- Logging systems
- Network monitoring
- Security practices
- File handling

---

#  License

This project is intended for educational use only.

---

#  Repository

GitHub Repository:

https://github.com/mohamedalid510-byte/-A-Secure-System-Administration-Toolkit.git
