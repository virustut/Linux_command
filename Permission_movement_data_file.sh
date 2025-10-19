1️⃣ Restart SQL Server Services
# Restart SQL Server
sudo systemctl restart mssql-server

# Check status
sudo systemctl status mssql-server

# Enable automatic start on boot
sudo systemctl enable mssql-server

# (Optional) Restart SQL Server Agent if using jobs
sudo systemctl restart mssql-server-agent
sudo systemctl enable mssql-server-agent


2️⃣ Enable TCP/IP Port 1433 for Remote Connections

# Set SQL Server to listen on all IPs
sudo /opt/mssql/bin/mssql-conf set network.ipaddress 0.0.0.0

# Set TCP port
sudo /opt/mssql/bin/mssql-conf set network.tcpport 1433

# Restart service to apply changes
sudo systemctl restart mssql-server

3️⃣ Open Firewall for SQL Server
# Check firewall status
sudo ufw status

# Allow SSH
sudo ufw allow 22/tcp

# Allow SQL Server default port
sudo ufw allow 1433/tcp

# Reload firewall
sudo ufw reload

# Enable firewall
sudo ufw enable

4️⃣ Set Permissions for SQL Data Folder

# Give ownership to SQL Server user
sudo chown -R mssql:mssql /mssql2022

# Set proper permissions
sudo chmod -R 770 /mssql2022


5️⃣ Enable Always On / HADR Feature
# Enable HADR (Always On) features
sudo /opt/mssql/bin/mssql-conf set hadr.hadrenabled 1

# Restart service to apply
sudo systemctl restart mssql-server

# Verify HADR status in SQL Server
sqlcmd -S localhost -U SA -P '<YourPassword>' -Q "SELECT SERVERPROPERTY('IsHadrEnabled')"

6️⃣ SQL Server Database Setup (Optional)

-- Set database to full recovery model (required for AG)
ALTER DATABASE YourDB SET RECOVERY FULL;

-- Create availability group endpoint
CREATE ENDPOINT [Hadr_endpoint]
STATE=STARTED
AS TCP (LISTENER_PORT = 5022)
FOR DATABASE_MIRRORING (ROLE = ALL);

7️⃣ Verify SQL Server Listening Ports
sudo ss -tulnp | grep 1433



-------------------------Change my database creation path in mssql-----------------------
1️⃣ Check current default paths
SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DataPath,
       SERVERPROPERTY('InstanceDefaultLogPath') AS LogPath;
GO

This shows the current default paths, usually:

/var/opt/mssql/data for data
/var/opt/mssql/data for logs

2️⃣ Choose your new default folder

Example: you want /mssql2022/data for data and /mssql2022/log for logs.

Create directories if they don’t exist:
sudo mkdir -p /mssql2022/data
sudo mkdir -p /mssql2022/log

Set proper permissions for SQL Server (mssql user):
sudo chown -R mssql:mssql /mssql2022
sudo chmod -R 770 /mssql2022

3️⃣ Update SQL Server configuration
Use mssql-conf:

sudo /opt/mssql/bin/mssql-conf set filelocation.defaultdatadir /mssql2022/data
sudo /opt/mssql/bin/mssql-conf set filelocation.defaultlogdir /mssql2022/log

defaultdatadir → for .mdf and .ndf files
defaultlogdir → for .ldf files

4️⃣ Restart SQL Server
sudo systemctl restart mssql-server

5️⃣ Verify the change

Run in SQL:
SELECT SERVERPROPERTY('InstanceDefaultDataPath') AS DataPath,
       SERVERPROPERTY('InstanceDefaultLogPath') AS LogPath;
GO

✅ Now any new database will use your new folders by default.

