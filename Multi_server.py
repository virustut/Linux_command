import streamlit as st
import psutil
import mysql.connector
import pandas as pd
import plotly.express as px
import time

# ----------------------------
# SERVER CONFIG
# ----------------------------
SERVERS = {
    "Primary-MySQL": {"ip": "192.168.1.10", "db_host": "192.168.1.10", "user": "root", "password": "password"},
    "Replica-MySQL": {"ip": "192.168.1.11", "db_host": "192.168.1.11", "user": "root", "password": "password"},
    "Test-MySQL": {"ip": "127.0.0.1", "db_host": "127.0.0.1", "user": "root", "password": "password"}
}

MONITOR_DB = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "password",
    "database": "monitoring"
}

# ----------------------------
# UI
# ----------------------------
st.set_page_config(page_title="Multi Server MySQL Monitor", layout="wide")
st.title("🌐 Multi-Server MySQL Monitoring Dashboard")

# ✅ DROPDOWN MENU
selected_server_name = st.sidebar.selectbox(
    "Select MySQL Server",
    list(SERVERS.keys())
)

selected_server = SERVERS[selected_server_name]

# ----------------------------
# MySQL Connections
# ----------------------------
monitor_db = mysql.connector.connect(**MONITOR_DB)
monitor_cursor = monitor_db.cursor()

target_db = mysql.connector.connect(
    host=selected_server["db_host"],
    user=selected_server["user"],
    password=selected_server["password"]
)
target_cursor = target_db.cursor()

# ----------------------------
# LIVE METRICS (LOCAL MACHINE)
# ----------------------------
cpu = psutil.cpu_percent(interval=1)
ram = psutil.virtual_memory().percent
disk = psutil.disk_usage('/').percent

# ----------------------------
# MYSQL METRICS
# ----------------------------
target_cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
mysql_connections = int(target_cursor.fetchone()[1])

# ----------------------------
# REPLICATION STATUS
# ----------------------------
try:
    target_cursor.execute("SHOW SLAVE STATUS")
    rep = target_cursor.fetchone()
    if rep:
        slave_io = rep[10]
        slave_sql = rep[11]
        replication_lag = rep[32]
    else:
        slave_io = "No"
        slave_sql = "No"
        replication_lag = 0
except:
    slave_io = "No"
    slave_sql = "No"
    replication_lag = 0

# ----------------------------
# STORE METRICS
# ----------------------------
insert_sql = """
INSERT INTO system_metrics
(server_name, server_ip, cpu_usage, ram_usage, disk_usage,
 mysql_connections, slave_io, slave_sql, replication_lag)
VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
"""
monitor_cursor.execute(insert_sql, (
    selected_server_name,
    selected_server["ip"],
    cpu, ram, disk,
    mysql_connections,
    slave_io, slave_sql, replication_lag
))
monitor_db.commit()

# ----------------------------
# METRIC CARDS
# ----------------------------
c1, c2, c3, c4, c5 = st.columns(5)

c1.metric("CPU %", f"{cpu}")
c2.metric("RAM %", f"{ram}")
c3.metric("Disk %", f"{disk}")
c4.metric("Connections", mysql_connections)
c5.metric("Replication Lag (s)", replication_lag)

rep_status = "Healthy ✅" if slave_io == "Yes" and slave_sql == "Yes" else "Broken ❌"
st.subheader(f"Replication Status: {rep_status}")

# ----------------------------
# LOAD HISTORY FOR SELECTED SERVER
# ----------------------------
df = pd.read_sql(f"""
SELECT captured_at, cpu_usage, ram_usage, disk_usage,
       mysql_connections, replication_lag
FROM system_metrics
WHERE server_name = '{selected_server_name}'
ORDER BY captured_at DESC
LIMIT 400
""", monitor_db)

df = df.sort_values("captured_at")

# ----------------------------
# CHARTS
# ----------------------------
st.subheader(f"📈 Performance History – {selected_server_name}")

st.plotly_chart(px.line(df, x="captured_at", y="cpu_usage", title="CPU Usage"), use_container_width=True)
st.plotly_chart(px.line(df, x="captured_at", y="ram_usage", title="RAM Usage"), use_container_width=True)
st.plotly_chart(px.line(df, x="captured_at", y="disk_usage", title="Disk Usage"), use_container_width=True)
st.plotly_chart(px.line(df, x="captured_at", y="mysql_connections", title="MySQL Connections"), use_container_width=True)
st.plotly_chart(px.line(df, x="captured_at", y="replication_lag", title="Replication Lag"), use_container_width=True)

# ----------------------------
# AUTO REFRESH
# ----------------------------
st.sidebar.success("✅ Auto refresh every 5 seconds")
time.sleep(5)
st.rerun()
