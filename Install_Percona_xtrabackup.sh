==============================
Percona XtraBackup 8.0 Guide
MySQL 8.0.44 on Ubuntu 22.04
==============================

Step 0: Prerequisites
---------------------
1. MySQL 8.0.44 is installed and running.
2. You have root or sudo privileges.
3. Install Percona XtraBackup 8.0:

wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup ps80
sudo apt-get update
sudo apt-get install percona-xtrabackup-80

Step 1: Prepare backup directories
---------------------------------
sudo mkdir -p /backup/mysql/full
sudo mkdir -p /backup/mysql/inc1
sudo chown -R mysql:mysql /backup/mysql

Step 2: Take a full backup (hot backup)
---------------------------------------
xtrabackup --backup \
  --target-dir=/backup/mysql/full \
  --user=root \
  --password='your_mysql_root_password'

Step 3: Take incremental backups
--------------------------------
# First incremental backup
xtrabackup --backup \
  --target-dir=/backup/mysql/inc1 \
  --incremental-basedir=/backup/mysql/full \
  --user=root \
  --password='your_mysql_root_password'

# Second incremental backup (if needed)
xtrabackup --backup \
  --target-dir=/backup/mysql/inc2 \
  --incremental-basedir=/backup/mysql/inc1 \
  --user=root \
  --password='your_mysql_root_password'

Step 4: Prepare the backup (apply logs)
---------------------------------------
# Prepare full backup
xtrabackup --prepare --apply-log-only \
  --target-dir=/backup/mysql/full

# Apply incremental backups
xtrabackup --prepare --apply-log-only \
  --target-dir=/backup/mysql/full \
  --incremental-dir=/backup/mysql/inc1

# Apply second incremental if needed
xtrabackup --prepare --apply-log-only \
  --target-dir=/backup/mysql/full \
  --incremental-dir=/backup/mysql/inc2

# Final prepare
xtrabackup --prepare --target-dir=/backup/mysql/full

Step 5: Restore the backup
--------------------------
sudo systemctl stop mysql

sudo xtrabackup --copy-back --target-dir=/backup/mysql/full
sudo chown -R mysql:mysql /var/lib/mysql

sudo systemctl start mysql

Step 6: GTID-safe backups
-------------------------
- XtraBackup supports GTID-enabled servers.
- Prepare backups with --apply-log-only for GTID consistency.
- Check GTID info in backup:

cat /backup/mysql/full/xtrabackup_binlog_info

Notes
-----
- Only InnoDB tables are supported.
- XtraBackup is hot-backup capable.
- Always test restore before using in production.
- For frequent incremental backups, repeat Step 3 & Step 4.

