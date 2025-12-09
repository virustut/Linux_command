import streamlit as st
import psutil
import mysql.connector
import pandas as pd
import plotly.express as px
import time

# ----------------------------
# MySQL Connection
# ----------------------------
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="password",
    database="monitoring"
)
cursor = db.cursor()

# ----------------------------
# Streamlit UI
# ----------------------------
st.set_page_config(page_title="MySQL Server Monitor", layout="wide")

st.markdown("""
<style>
.big-font { font-size:40px !important; font-weight: bold; }
.card { padding:20px; border-radius:15px; background:#f0f2f6; box-shadow:2px 2px 10px rgba(0,0,0,0.1); }
.red { color:red; }
.green { color:green; }
</style>
""", unsafe_allow_html=True)

st.title("🚀 MySQL Professional Server Monitoring Dashboard")

# ----------------------------
# Live System Metrics
# ----------------------------
cpu = psutil.cpu_percent(interval=1)
ram = psutil.virtual_memory().percent
disk = psutil.disk_usage('/').percent

# MySQL Connections
cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
mysql_connections = int(cursor.fetchone()[1])

# ----------------------------
# Replication Status
# ----------------------------
try:
    cursor.execute("SHOW SLAVE STATUS")
    rep = cursor.fetchone()
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
# Store Metrics in MySQL
# ----------------------------
insert_sql = """
INSERT INTO system_metrics 
(cpu_usage, ram_usage, disk_usage, mysql_connections, slave_io, slave_sql, replication_lag)
VALUES (%s, %s, %s, %s, %s, %s, %s)
"""
cursor.execute(insert_sql, (cpu, ram, disk, mysql_connections, slave_io, slave_sql, replication_lag))
db.commit()

# ----------------------------
# Metric Cards
# ----------------------------
c1, c2, c3, c4, c5 = st.columns(5)

c1.markdown(f"<div class='card big-font'>CPU<br>{cpu}%</div>", unsafe_allow_html=True)
c2.markdown(f"<div class='card big-font'>RAM<br>{ram}%</div>", unsafe_allow_html=True)
c3.markdown(f"<div class='card big-font'>Disk<br>{disk}%</div>", unsafe_allow_html=True)
c4.markdown(f"<div class='card big-font'>Connections<br>{mysql_connections}</div>", unsafe_allow_html=True)

rep_color = "green" if slave_io == "Yes" and slave_sql == "Yes" else "red"
c5.markdown(
    f"<div class='card big-font {rep_color}'>Replication<br>{slave_io}/{slave_sql}<br>Lag: {replication_lag}s</div>",
    unsafe_allow_html=True
)

# ----------------------------
# Load History
# ----------------------------
df = pd.read_sql("""
SELECT captured_at, cpu_usage, ram_usage, disk_usage, mysql_connections, replication_lag
FROM system_metrics
ORDER BY captured_at DESC
LIMIT 300
""", db)

df = df.sort_values("captured_at")

# ----------------------------
# Charts
# ----------------------------
st.subheader("📈 Performance History")

cpu_chart = px.line(df, x="captured_at", y="cpu_usage", title="CPU Usage History")
ram_chart = px.line(df, x="captured_at", y="ram_usage", title="RAM Usage History")
disk_chart = px.line(df, x="captured_at", y="disk_usage", title="Disk Usage History")
conn_chart = px.line(df, x="captured_at", y="mysql_connections", title="MySQL Connections History")
lag_chart = px.line(df, x="captured_at", y="replication_lag", title="Replication Lag History")

st.plotly_chart(cpu_chart, use_container_width=True)
st.plotly_chart(ram_chart, use_container_width=True)
st.plotly_chart(disk_chart, use_container_width=True)
st.plotly_chart(conn_chart, use_container_width=True)
st.plotly_chart(lag_chart, use_container_width=True)

# ----------------------------
# Auto Refresh
# ----------------------------
st.sidebar.success("✅ Auto refresh every 5 seconds")
time.sleep(5)
st.rerun()
