#!/bin/bash
# ============================================================
# MariaDB 10.11 Installation Script for Rocky Linux 9
# ============================================================

echo "🚀 Updating system packages..."
sudo dnf update -y

echo "📦 Checking available MariaDB modules..."
dnf module list mariadb -y

echo "🧩 Enabling MariaDB 10.11 module..."
sudo dnf module reset mariadb -y
sudo dnf module enable mariadb:10.11 -y

echo "⬇️ Installing MariaDB server..."
sudo dnf install mariadb-server -y

echo "🔧 Enabling and starting MariaDB service..."
sudo systemctl enable mariadb --now

echo "🧠 Securing MariaDB installation..."
sudo mysql_secure_installation <<EOF

y
StrongRootPass@123
StrongRootPass@123
y
y
y
y
EOF

echo "✅ MariaDB secured with root password: StrongRootPass@123"

echo "🌐 Configuring MariaDB for remote connections..."
CONFIG_FILE="/etc/my.cnf.d/mariadb-server.cnf"
sudo sed -i 's/^bind-address\s*=.*/bind-address=0.0.0.0/' $CONFIG_FILE

echo "🔁 Restarting MariaDB service..."
sudo systemctl restart mariadb

echo "🔥 Opening MySQL port in firewall..."
sudo firewall-cmd --add-service=mysql --permanent
sudo firewall-cmd --reload

echo "🧪 Verifying installation..."
mysql -u root -pStrongRootPass@123 -e "SELECT VERSION();"

echo "✅ MariaDB installation and configuration completed successfully!"
echo "You can now connect using: mysql -u root -pStrongRootPass@123"
