🧱 Example Setup (Free + Efficient)

🔹 1. Weekly Full Backup

xtrabackup --backup \
  --target-dir=/backups/full_2025-10-19 \
  --user=backupuser --password='yourpassword'

🔹 2. Daily Incremental Backup

xtrabackup --backup \
  --target-dir=/backups/inc_2025-10-20 \
  --incremental-basedir=/backups/full_2025-10-19 \
  --user=backupuser --password='yourpassword'


For the next day:

xtrabackup --backup \
  --target-dir=/backups/inc_2025-10-21 \
  --incremental-basedir=/backups/inc_2025-10-20 \
  --user=backupuser --password='yourpassword'

🧾 Restore Steps (Briefly)

Prepare full backup:
xtrabackup --prepare --apply-log-only \
  --target-dir=/backups/full_2025-10-19

Apply each incremental in order:
xtrabackup --prepare --apply-log-only \
  --target-dir=/backups/full_2025-10-19 \
  --incremental-dir=/backups/inc_2025-10-20
xtrabackup --prepare --apply-log-only \
  --target-dir=/backups/full_2025-10-19 \
  --incremental-dir=/backups/inc_2025-10-21

Finalize for restore:

xtrabackup --prepare \
  --target-dir=/backups/full_2025-10-19

------------------Below are the full script to run full bakcup incremental backup----------------------


🗂️ Folder Structure (Recommended)

/backups/
 ├── full/
 │    └── full_YYYY-MM-DD/
 ├── inc/
 │    └── inc_YYYY-MM-DD/
 └── logs/


🧰 Prerequisites

Before using the scripts:
Install XtraBackup

sudo apt install percona-xtrabackup-80

Create a backup user in MySQL:

CREATE USER 'backupuser'@'localhost' IDENTIFIED BY 'StrongPassword';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backupuser'@'localhost';
FLUSH PRIVILEGES;

Ensure /backups/ has enough space and correct permissions:

sudo mkdir -p /backups/{full,inc,logs}
sudo chown -R mysql:mysql /backups


-----🗓️ 1️⃣ Weekly Full Backup Script

Save this as:
/usr/local/bin/mysql_full_backup.sh

#!/bin/bash
# === Weekly Full Backup Script ===

BACKUP_DIR="/backups/full/full_$(date +%F)"
LOGFILE="/backups/logs/full_$(date +%F).log"
USER="backupuser"
PASS="StrongPassword"

echo "[$(date)] Starting FULL backup..." | tee -a $LOGFILE

xtrabackup --backup \
  --target-dir="$BACKUP_DIR" \
  --user=$USER --password=$PASS \
  --parallel=4 2>&1 | tee -a $LOGFILE

if [ $? -eq 0 ]; then
  echo "[$(date)] FULL backup completed successfully." | tee -a $LOGFILE
else
  echo "[$(date)] ERROR: FULL backup failed!" | tee -a $LOGFILE
  exit 1
fi

-----🗓️ 2️⃣ Daily Incremental Backup Script

Save as:
/usr/local/bin/mysql_incremental_backup.sh.

#!/bin/bash
# === Daily Incremental Backup Script ===

INC_DIR="/backups/inc/inc_$(date +%F)"
LOGFILE="/backups/logs/inc_$(date +%F).log"
USER="backupuser"
PASS="StrongPassword"

# Find the latest backup base
if [ -d "/backups/inc" ] && [ "$(ls -A /backups/inc)" ]; then
  BASE_DIR=$(find /backups/inc -maxdepth 1 -type d -name "inc_*" | sort | tail -n 1)
else
  BASE_DIR=$(find /backups/full -maxdepth 1 -type d -name "full_*" | sort | tail -n 1)
fi

echo "[$(date)] Starting INCREMENTAL backup..."
echo "Base directory: $BASE_DIR" | tee -a $LOGFILE

xtrabackup --backup \
  --target-dir="$INC_DIR" \
  --incremental-basedir="$BASE_DIR" \
  --user=$USER --password=$PASS \
  --parallel=4 2>&1 | tee -a $LOGFILE

if [ $? -eq 0 ]; then
  echo "[$(date)] INCREMENTAL backup completed successfully." | tee -a $LOGFILE
else
  echo "[$(date)] ERROR: INCREMENTAL backup failed!" | tee -a $LOGFILE
  exit 1
fi


-----🧹 3️⃣ Optional: Auto-Cleanup Script

Keeps only the last 2 full backups and their related incrementals.

Save as:
/usr/local/bin/mysql_backup_cleanup.sh

#!/bin/bash
# === Backup Cleanup Script ===

cd /backups/full
KEEP=2

# Remove older full backups
ls -1t | tail -n +$((KEEP+1)) | while read OLD_FULL; do
  echo "Deleting old full backup: $OLD_FULL"
  rm -rf "/backups/full/$OLD_FULL"

  # Delete related incremental backups
  FULL_DATE=$(echo $OLD_FULL | cut -d'_' -f2)
  find /backups/inc -type d -name "inc_${FULL_DATE}*" -exec rm -rf {} +
done


----🕒 4️⃣ Schedule with Cron
sudo crontab -e

# Weekly full backup (Sunday at 2 AM)
0 2 * * 0 /usr/local/bin/mysql_full_backup.sh

# Daily incremental backups (Mon–Sat at 2 AM)
0 2 * * 1-6 /usr/local/bin/mysql_incremental_backup.sh

# Cleanup every Monday at 3 AM
0 3 * * 1 /usr/local/bin/mysql_backup_cleanup.sh



🧾 Logs

All backups (full & incremental) log to /backups/logs/.
You can review them with:

less /backups/logs/full_2025-10-20.log

------------------------------------Restore Summary-----------------------------------------

🧩 Restore Process (Summary)

Prepare full backup:
xtrabackup --prepare --apply-log-only --target-dir=/backups/full/full_2025-10-19

Apply incrementals (in order):
xtrabackup --prepare --apply-log-only \
  --target-dir=/backups/full/full_2025-10-19 \
  --incremental-dir=/backups/inc/inc_2025-10-20

Repeat for all days.

Finalize:
xtrabackup --prepare --target-dir=/backups/full/full_2025-10-19

Restore data directory:
systemctl stop mysql
rm -rf /var/lib/mysql/*
xtrabackup --copy-back --target-dir=/backups/full/full_2025-10-19
chown -R mysql:mysql /var/lib/mysql
systemctl start mysql

-------------------------------------Prepare Bakcup in zip File-------------------------------------------

🗓️ 1️⃣ Weekly Full Backup (Compressed)

File: /usr/local/bin/mysql_full_backup.sh

#!/bin/bash
# === Weekly Full Backup Script (Compressed) ===

BACKUP_BASE="/backups/full"
BACKUP_DIR="${BACKUP_BASE}/full_$(date +%F)"
ARCHIVE="${BACKUP_DIR}.tar.gz"
LOGFILE="/backups/logs/full_$(date +%F).log"
USER="backupuser"
PASS="StrongPassword"

echo "[$(date)] Starting FULL backup..." | tee -a $LOGFILE

xtrabackup --backup \
  --target-dir="$BACKUP_DIR" \
  --user=$USER --password=$PASS \
  --parallel=4 2>&1 | tee -a $LOGFILE

if [ $? -eq 0 ]; then
  echo "[$(date)] Backup complete — compressing..." | tee -a $LOGFILE
  tar -czf "$ARCHIVE" -C "$BACKUP_BASE" "$(basename $BACKUP_DIR)" && rm -rf "$BACKUP_DIR"
  echo "[$(date)] FULL backup compressed to $ARCHIVE" | tee -a $LOGFILE
else
  echo "[$(date)] ERROR: FULL backup failed!" | tee -a $LOGFILE
  exit 1
fi


🗓️ 2️⃣ Daily Incremental Backup (Compressed)

File: /usr/local/bin/mysql_incremental_backup.sh

#!/bin/bash
# === Daily Incremental Backup Script (Compressed) ===

INC_BASE="/backups/inc"
INC_DIR="${INC_BASE}/inc_$(date +%F)"
ARCHIVE="${INC_DIR}.tar.gz"
LOGFILE="/backups/logs/inc_$(date +%F).log"
USER="backupuser"
PASS="StrongPassword"

# Find the latest base (either last incremental or full)
if ls /backups/inc/inc_*.tar.gz 1> /dev/null 2>&1; then
  BASE_ARCHIVE=$(ls -t /backups/inc/inc_*.tar.gz | head -n 1)
else
  BASE_ARCHIVE=$(ls -t /backups/full/full_*.tar.gz | head -n 1)
fi

# Extract base temporarily to use as reference
TMP_BASE="/tmp/xb_base_$$"
mkdir -p "$TMP_BASE"
tar -xzf "$BASE_ARCHIVE" -C "$TMP_BASE"

echo "[$(date)] Starting INCREMENTAL backup (base: $BASE_ARCHIVE)..." | tee -a $LOGFILE

xtrabackup --backup \
  --target-dir="$INC_DIR" \
  --incremental-basedir="$TMP_BASE/$(ls $TMP_BASE)" \
  --user=$USER --password=$PASS \
  --parallel=4 2>&1 | tee -a $LOGFILE

if [ $? -eq 0 ]; then
  echo "[$(date)] Incremental backup complete — compressing..." | tee -a $LOGFILE
  tar -czf "$ARCHIVE" -C "$INC_BASE" "$(basename $INC_DIR)" && rm -rf "$INC_DIR"
  echo "[$(date)] INCREMENTAL backup compressed to $ARCHIVE" | tee -a $LOGFILE
else
  echo "[$(date)] ERROR: INCREMENTAL backup failed!" | tee -a $LOGFILE
  exit 1
fi

# Cleanup temporary base
rm -rf "$TMP_BASE"


🧹 3️⃣ Cleanup Script (Updated for Compressed Backups)

File: /usr/local/bin/mysql_backup_cleanup.sh

#!/bin/bash
# === Cleanup Old Backups (Compressed) ===

cd /backups/full
KEEP=2

# Delete old full backups (.tar.gz)
ls -1t full_*.tar.gz | tail -n +$((KEEP+1)) | while read OLD_FULL; do
  echo "Deleting old full backup: $OLD_FULL"
  rm -f "/backups/full/$OLD_FULL"

  # Also remove related incrementals
  FULL_DATE=$(echo $OLD_FULL | cut -d'_' -f2 | cut -d'.' -f1)
  find /backups/inc -type f -name "inc_${FULL_DATE}*.tar.gz" -exec rm -f {} +
done


🕒 4️⃣ Cron Schedule (same as before)

sudo crontab -e

# Weekly full backup (Sunday 2 AM)
0 2 * * 0 /usr/local/bin/mysql_full_backup.sh

# Daily incremental backups (Mon–Sat 2 AM)
0 2 * * 1-6 /usr/local/bin/mysql_incremental_backup.sh

# Cleanup (Monday 3 AM)
0 3 * * 1 /usr/local/bin/mysql_backup_cleanup.sh

🧾 Result

Each backup (full or incremental) becomes a single compressed file:
/backups/full/full_2025-10-19.tar.gz
/backups/inc/inc_2025-10-20.tar.gz
/backups/inc/inc_2025-10-21.tar.gz


🔁 Restore Process (with compressed backups)

Extract the full and incremental backups in order:
tar -xzf /backups/full/full_2025-10-19.tar.gz -C /tmp/restore/full
tar -xzf /backups/inc/inc_2025-10-20.tar.gz -C /tmp/restore/inc1
tar -xzf /backups/inc/inc_2025-10-21.tar.gz -C /tmp/restore/inc2

Prepare the backups as usual with xtrabackup --prepare ...
Copy back to MySQL data directory.
