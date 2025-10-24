############################################################
# REMOVE PERCONA XTRABACKUP (CentOS Stream 9)
# Author: ChatGPT
# Purpose: Completely uninstall Percona XtraBackup + cleanup
############################################################

echo "=== Step 1: Check installed XtraBackup packages ==="
rpm -qa | grep -i xtrabackup || echo "No XtraBackup package found."

echo
echo "=== Step 2: Remove Percona XtraBackup packages ==="
sudo dnf remove percona-xtrabackup* -y

echo
echo "=== Step 3: Remove Percona repository (optional) ==="
sudo dnf remove percona-release -y
sudo rm -f /etc/yum.repos.d/percona-release.repo

echo
echo "=== Step 4: Clean DNF cache ==="
sudo dnf clean all

echo
echo "=== Step 5: Verify that XtraBackup is removed ==="
if ! command -v xtrabackup &> /dev/null
then
    echo "✅ XtraBackup successfully removed."
else
    echo "⚠️  XtraBackup still found on system. Check manually."
fi

echo
echo "=== Step 6: (Optional) Delete backup directories ==="
# Uncomment the next line if you want to delete old backups
# sudo rm -rf /Percona_Backup /backups

echo
echo "=== Step 7: All done! ==="
echo "Percona XtraBackup and repository have been removed."
