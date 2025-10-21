🧩 1️⃣ Install MariaDB with Galera

Run this:
sudo dnf install -y MariaDB-server MariaDB-client galera

Then verify installation:
which galera_new_cluster


✅ Expected output:

/usr/bin/galera_new_cluster

If it still doesn’t appear, check contents of the package:
rpm -ql MariaDB-server | grep galera_new_cluster

🧩 2️⃣ Enable & Prepare Service

sudo systemctl enable mariadb
sudo systemctl stop mariadb

🧩 3️⃣ Configure Galera Cluster (Primary Node Example)

Edit this file:
sudo nano /etc/my.cnf.d/mariadb.cnf
Add or modify the [mysqld] section like this:

[mysqld]
bind-address=0.0.0.0

# Basic settings
default_storage_engine=InnoDB
binlog_format=ROW
innodb_autoinc_lock_mode=2

# Galera provider
wsrep_on=ON
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

# Cluster configuration
wsrep_cluster_name="my_galera_cluster"
wsrep_cluster_address="gcomm://10.0.0.1,10.0.0.2,10.0.0.3"

# Node configuration
wsrep_node_name="primary"
wsrep_node_address="10.0.0.1"

# SST method
wsrep_sst_method=rsync

Note : 
💡 Replace:

10.0.0.1 → Primary node IP
10.0.0.2 → Secondary node IP
10.0.0.3 → Tertiary node IP

🧩 4️⃣ Open Galera Ports on Firewalld

Run this on each node:
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --permanent --add-port=4444/tcp
sudo firewall-cmd --permanent --add-port=4567/tcp
sudo firewall-cmd --permanent --add-port=4568/tcp
sudo firewall-cmd --reload

🧩 5️⃣ Bootstrap First Node (Primary)
sudo systemctl stop mariadb
sudo galera_new_cluster

Then check cluster size:
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

Expected:
| wsrep_cluster_size | 1 |

🧩 6️⃣ Start Other Nodes Normally
On the secondary and tertiary nodes:

sudo systemctl start mariadb

Then check on any node:
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"



