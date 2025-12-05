===============================
GTID-Based MySQL Replication
MySQL 8.0.44 - Master → Slave
===============================

Step 0: Prerequisites
---------------------
1. Both servers run MySQL 8.0.44.
2. Root access to both servers.
3. Network connectivity on MySQL port 3306.
4. Unique server_id on each server.
5. Both server bind_address should be 0.0.0.0

---

Step 1: Configure Master (Source) Server
----------------------------------------
Edit /etc/mysql/mysql.conf.d/mysqld.cnf on the master:

[mysqld]
server_id = 1
log_bin = mysql-bin
binlog_format = ROW
gtid_mode = ON
enforce_gtid_consistency = ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
log_slave_updates = ON
# binlog_do_db = your_database_name   # optional

Restart MySQL:
sudo systemctl restart mysql

Create replication user:
CREATE USER 'repl_user'@'%' IDENTIFIED with mysql_native_password BY 'Repl@1234';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;

Check GTID and binary log:
SHOW MASTER STATUS;

---

Step 2: Configure Slave (Replica) Server
----------------------------------------
Edit /etc/mysql/mysql.conf.d/mysqld.cnf on the slave:

[mysqld]
server_id = 2
gtid_mode = ON
enforce_gtid_consistency = ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
read_only = ON
super_read_only=ON
Restart MySQL:
sudo systemctl restart mysql

---

Step 3: Take a snapshot of the master
-------------------------------------
# Take consistent backup
mysqldump --all-databases --single-transaction --master-data=2 \
--routines --triggers --events -u root -p > full_backup.sql

/####
3. --master-data=2

This includes the binlog coordinates or GTID info inside the dump as a comment.

Useful for replication:

=1 → writes it un-commented (used for setting up replicas)

=2 → writes it as a comment (safer for general backups)

For production, =2 is recommended.

###/



# Copy backup to slave
scp full_backup.sql user@slave_server:/tmp/

root@db-01:/mysql_backup# rsync -avzh --progress /mysql_backup/ root@172.18.163.66:/mysql_backup/

# Restore on slave
mysql -u root -p < /tmp/full_backup.sql

---

Step 4: Start replication on the slave
--------------------------------------
Connect to MySQL on the slave:

CHANGE MASTER TO
  MASTER_HOST='master_ip_or_hostname',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='StrongPassword',
  MASTER_AUTO_POSITION = 1;  -- GTID-based replication

START SLAVE;

Check replication status:
SHOW SLAVE STATUS\G

Look for:
- Slave_IO_Running: Yes
- Slave_SQL_Running: Yes
- Seconds_Behind_Master: 0

---

Step 5: Notes
-------------
1. GTID replication removes the need for MASTER_LOG_FILE / MASTER_LOG_POS.
2. enforce_gtid_consistency=ON ensures only safe statements are replicated.
3. log_bin must be enabled on the master.
4. For multiple databases, carefully use binlog_do_db or replicate_do_db.
5. Monitor replication regularly to catch any errors.


Step 6: When master is down
        Option A - Wait for master recovery if it is quickly up replication will resume automatically
	Option B - Promote slave to master
		Run on slave
		STOP SLAVE SQL_THREAD;
		RESET SLAVE ALL;
		SET GLOBAL read_only = OFF
		SET GLOBAL super_read_only=OFF
	Update your application to point to the new master

	

Scenario Recap

Original master (M1) goes down.
You promote a slave (S1) to act as the new master.
Original master (M1) is back online the next day.
You want to turn the old master into a slave of the new master.


Step-by-Step Procedure
1️. Ensure your new master (S1) is fully up and GTID is working

SHOW MASTER STATUS\G
SHOW SLAVE STATUS\G


Note the GTID executed on the new master.
Make sure replication is healthy if it has its own slaves.



2. Stop MySQL on the old master (M1)

systemctl stop mysql

3. Backup old master data (optional but recommended)

xtrabackup --backup --target-dir=/tmp/old_master_backup

Note : This ensures you can restore if anything goes wrong.

4. Clean up old replicate state on old master(m1)
SQL>
RESET SLAVE ALL;
STOP SLAVE;

Removes old replication coordinates.

Prepares M1 to become a slave.

5. Restore or synchronize old master with new master

You have two options:

Option A — Take a fresh backup from new master and restore to old master

	On new master (S1), take backup (XtraBackup or mysqldump).

	Copy backup to old master (M1).

	Prepare and restore backup.

This is safest and ensures M1 is fully in sync.

Option B — If M1 data is not changed at all since it went down

	You can skip backup, but check GTID consistency.

6. Configure old master (M1) as a slave of new master (S1)

On old master M1

CHANGE MASTER TO 
MASTER_HOST='S1_IP',
MASTER_USER='repl_user',
MASTER_PASSWORD='password',
MASTER_AUTO_POSITION=1;

MASTER_AUTO_POSITION=1 uses GTID → safest.

No need to specify binlog file/position manually.

7. Start replication on old master (now slave)

START SLAVE;
SHOW SLAVE STATUS\G


Check Seconds_Behind_Master → should start applying missing transactions from new master.

Check for errors.

8. Enable read-only (recommended) on old master(m1)

SET GLOBAL read_only=ON;
SET GLOBAL super_read_only=ON;

Prevents accidental writes on this new slave.




Summary Workflow

| Step | Action                                             |
| ---- | -------------------------------------------------- |
| 1    | Promote slave to new master                        |
| 2    | Stop old master                                    |
| 3    | Backup old master (optional)                       |
| 4    | Reset replication state on old master              |
| 5    | Restore/sync data from new master                  |
| 6    | Configure old master as slave (GTID auto position) |
| 7    | Start replication & verify                         |
| 8    | Enable read-only on old master                     |


===========================New Scenario=========================
          ┌───────────┐
          │  Master   │
          └───────────┘
           /       \
          /         \
 ┌────────────┐  ┌────────────┐
 │ Replica1   │  │ Replica2   │
 │ (S1)       │  │ (S2)       │
 └────────────┘  └────────────┘

Replica1 → can be promoted if master fails.

Replica2 → always follows the current master.


---THE THIRD SERVER ARE COMING IN TO  THE PICTURE----
S1 (Master) ──▶ S2 (Slave)
S3 = new server (to be added)

Step 1 : prepare the new server S3

my.cnf file 
server-id=3
gtid_mode=ON
enforce_gtid_consistency=ON
log_slave_updates=ON
read_only=ON
super_read_only=ON

Note : stop mysql and restore to using below steps 

Step 2 : Take a bakcup from master and restore S3
xtrabackup --backup --target-dir=/tmp/full_backup

Step 3 : Restore the backup on S3
xtrabackup --prepare --target-dir=/tmp/full_backup
xtrabackup --copy-back --target-dir=/tmp/full_backup
chown -R mysql:mysql /var/lib/mysql

or using mysql<bakup.sql

start mysql

Step 4 : Configure replication on S3
CHANGE MASTER TO 
MASTER_HOST='S1_IP',
MASTER_USER='repl_user',
MASTER_PASSWORD='password',
MASTER_AUTO_POSITION=1;

Start replication

START SLAVE;
SHOW SLAVE STATUS\G

Note : 
Ensure Seconds_Behind_Master = 0 and no errors.

Keep read_only=ON.

Now our new topology 

          ┌───────────┐
          │  Master S1│
          └───────────┘
           /       \
          /         \
 ┌────────────┐  ┌────────────┐
 │ Slave S2   │  │ Slave S3   │
 │ (read-only)│  │ (read-only)│
 └────────────┘  └────────────┘

Now u watch monitor replication 
###############################################################################

