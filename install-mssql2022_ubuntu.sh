#!/bin/bash
# ==========================================================
# Microsoft SQL Server 2022 Installer for Ubuntu 22.04 / 24.04
# Author: Virus Tutorial (for DBA Lab setup)
# ==========================================================

set -e

echo "=========================================="
echo "🚀 Starting Microsoft SQL Server 2022 Setup"
echo "=========================================="

# Step 1: Create optional folder (for your use)
if [ ! -d "/mssql2022" ]; then
  echo "📁 Creating /mssql2022 directory..."
  sudo mkdir /mssql2022
  sudo chmod 755 /mssql2022
fi

# Step 2: Add Microsoft GPG key
echo "🔑 Adding Microsoft GPG key..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Step 3: Add the SQL Server 2022 repository (22.04 works for 24.04 too)
echo "📦 Adding SQL Server 2022 repository..."
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" -y
sudo apt update -y

# Step 4: Install SQL Server
echo "💾 Installing SQL Server 2022..."
sudo apt install -y mssql-server

# Step 5: Run setup wizard (manual step)
echo "⚙️  Running SQL Server setup wizard..."
echo "👉 When prompted:"
echo "   • Choose edition: Developer"
echo "   • Accept license terms"
echo "   • Set a strong SA password"
sudo /opt/mssql/bin/mssql-conf setup

# Step 6: Enable and start SQL Server service
echo "🔄 Enabling and starting SQL Server service..."
sudo systemctl enable --now mssql-server
sudo systemctl status mssql-server --no-pager

# Step 7: Add Microsoft Tools repository
echo "🧰 Adding SQL command-line tools repository..."
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/prod.list)" -y
sudo apt update -y

# Step 8: Install SQL command-line tools
echo "📡 Installing sqlcmd and related tools..."
sudo apt install -y mssql-tools18 unixodbc-dev

# Step 9: Add tools to PATH
if ! grep -q "mssql-tools18" ~/.bashrc; then
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
  source ~/.bashrc
fi

# Step 10: Display success message
echo "✅ SQL Server 2022 Installation Complete!"
echo "------------------------------------------"
echo "To connect locally, use:"
echo "  sqlcmd -S localhost -U sa -P '<YourPassword>'"
echo "------------------------------------------"
echo "For remote access from SSMS (Windows):"
echo "  1️⃣ Run: sudo ufw allow 1433/tcp"
echo "  2️⃣ Connect to: <your-linux-ip>,1433"
echo "------------------------------------------"
echo "Enjoy your SQL Server 2022 on Ubuntu! 🎉"


🧰 How to Use

Save the script:

nano install-mssql2022.sh


(paste the above content, then press Ctrl+O → Enter → Ctrl+X)

Make it executable:

chmod +x install-mssql2022.sh


Run it:

sudo ./install-mssql2022.sh

🧠 Notes

The script pauses once at:

sudo /opt/mssql/bin/mssql-conf setup


➤ This lets you choose Developer Edition and enter the SA password.
(You must complete that interactively once.)

After that, SQL Server auto-starts on every boot.
