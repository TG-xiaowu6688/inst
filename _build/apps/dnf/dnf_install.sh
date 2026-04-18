###############

silent() { "$@" >/dev/null 2>&1 || { echo "Error running: $*"; echo "sth error"; exit 1; }; }


debmirror=${1:-http://deb.debian.org/debian}
echo -e "deb ${debmirror} bullseye main\ndeb ${debmirror} bullseye-updates main\ndeb ${debmirror}-security bullseye-security main" > /etc/apt/sources.list

echo "Installing Dependencies"
silent apt-get update -y
silent apt-get install -y curl sudo mc gnupg netcat
echo "Installed Dependencies"

cd /root

rlsmirror=${2:-https://github.com/minlearn/inst/releases/download/inital}
mkdir -p download
wget -q --no-check-certificate $rlsmirror/dnfserver.tar.xz -O download/server.tar.gz

if apt list --installed 2>/dev/null | grep -q 'mysql-community-client/.*5\.6\.'; then
    echo "mysql-community-client 5.6 已安装，不装 default-mysql-client,强行继续"
else
    silent apt-get -y install default-mysql-client
fi


dpkg --add-architecture i386
silent apt-get update -y
silent apt-get -y install libc6:i386 libstdc++6:i386 zlib1g:i386

DNFS_DIR=/root/app/dnf

echo "Installing dnf..."
mkdir -p ${DNFS_DIR}
tar -xJf download/server.tar.gz -C /usr/lib/x86_64-linux-gnu dnfserver/libmysqlclient.so.16 --strip-components=1
tar -xJf download/server.tar.gz -C /usr/lib/i386-linux-gnu dnfserver/libhook.so --strip-components=1
tar -xJf download/server.tar.gz -C /usr/lib/i386-linux-gnu dnfserver/libGeoIP.so.1 --strip-components=1
tar -xJf download/server.tar.gz -C /usr/lib/i386-linux-gnu dnfserver/build/game/libnxencryption.so --strip-components=1
tar -xJf download/server.tar.gz -C ${DNFS_DIR} --strip-components=1

cat <<EOF >/root/init.sh
#!/bin/bash

if [ -f /root/inited ]; then echo "already inited, del /root/inited to re init"; fi
if [ ! -f /root/inited ]; then
read -p "give a dbip(127.0.0.1,10.10.10.x,publicip,etc..):" ip
read -p "give a dbpassword:" pw
HOSTNAME=\$ip
PORT="3306"
USERNAME="root"
PASSWORD=\${pw/\//\\\/}

# Wait for Mysql to become available.
until nc -z -v -w30 \${HOSTNAME} 3306; do
  echo "Database @\${HOSTNAME} not yet available. Sleeping..."
  sleep 10
done

mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "SELECT VERSION();" | grep -q "5.6"
if [ \$? -ne 0 ]; then
  echo "MySQL 版本不是5.6，脚本退出"
  exit 1
fi

mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database d_channel DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database d_guild DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database d_taiwan_secu DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database d_taiwan DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database d_technical_report DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_billing DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain_2nd DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain_auction_cera DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain_auction_gold DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain_log DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain_web DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_cain DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_game_event DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_login_play DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_login DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_mng_manager DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_prod DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} -e "create database taiwan_se_event DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} d_channel < ${DNFS_DIR}/database/d_channel.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} d_guild < ${DNFS_DIR}/database/d_guild.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} d_taiwan_secu < ${DNFS_DIR}/database/d_taiwan_secu.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} d_taiwan < ${DNFS_DIR}/database/d_taiwan.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} d_technical_report < ${DNFS_DIR}/database/d_technical_report.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_billing < ${DNFS_DIR}/database/taiwan_billing.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain_2nd < ${DNFS_DIR}/database/taiwan_cain_2nd.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain_auction_cera < ${DNFS_DIR}/database/taiwan_cain_auction_cera.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain_auction_gold < ${DNFS_DIR}/database/taiwan_cain_auction_gold.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain_log < ${DNFS_DIR}/database/taiwan_cain_log.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain_web < ${DNFS_DIR}/database/taiwan_cain_web.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_cain < ${DNFS_DIR}/database/taiwan_cain.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_game_event < ${DNFS_DIR}/database/taiwan_game_event.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_login_play < ${DNFS_DIR}/database/taiwan_login_play.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_login < ${DNFS_DIR}/database/taiwan_login.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_mng_manager < ${DNFS_DIR}/database/taiwan_mng_manager.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_prod < ${DNFS_DIR}/database/taiwan_prod.sql
mysql -h\${HOSTNAME} -P\${PORT} -u\${USERNAME} -p\${pw} taiwan_se_event < ${DNFS_DIR}/database/taiwan_se_event.sql
echo "数据库导入成功"

# Process environment variables in the configuration files.
echo "配置文件修改成功"

touch /root/inited
fi
EOF
chmod +x /root/init.sh

cat <<EOF >/lib/systemd/system/df_stun.service
[Unit]
Description=stun
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/stun
ExecStart=${DNFS_DIR}/build/stun/df_stun_r start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_monitor.service
[Unit]
Description=monitor
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/monitor
ExecStart=${DNFS_DIR}/build/monitor/df_monitor_r mnt_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_manager.service
[Unit]
Description=manager
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/manager
ExecStart=${DNFS_DIR}/build/manager/df_manager_r manager start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_relay.service
[Unit]
Description=relay
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/relay
ExecStart=${DNFS_DIR}/build/relay/df_relay_r relay_200 start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_bridge.service
[Unit]
Description=bridge
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/bridge
ExecStart=${DNFS_DIR}/build/bridge/df_bridge_r bridge start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_channel.service
[Unit]
Description=channel
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/channel
ExecStart=${DNFS_DIR}/build/channel/df_channel_r channel start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_dbmw_guild.service
[Unit]
Description=dbmw_guild
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/dbmw_guild
ExecStart=${DNFS_DIR}/build/dbmw_guild/df_dbmw_r dbmw_gld_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_dbmw_mnt.service
[Unit]
Description=dbmw_mnt
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/dbmw_mnt
ExecStart=${DNFS_DIR}/build/dbmw_mnt/df_dbmw_r dbmw_mnt_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_dbmw_stat.service
[Unit]
Description=dbmw_stat
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/dbmw_stat
ExecStart=${DNFS_DIR}/build/dbmw_stat/df_dbmw_r dbmw_stat_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_auction.service
[Unit]
Description=auction
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/auction
ExecStart=${DNFS_DIR}/build/auction/df_auction_r ./cfg/auction_siroco.cfg start ./df_auction_r
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_point.service
[Unit]
Description=point
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/point
ExecStart=${DNFS_DIR}/build/point/df_point_r ./cfg/point_siroco.cfg start df_point_r
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_guild.service
[Unit]
Description=guild
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/guild
ExecStart=${DNFS_DIR}/build/guild/df_guild_r gld_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_statics.service
[Unit]
Description=statics
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/statics
ExecStart=${DNFS_DIR}/build/statics/df_statics_r stat_siroco start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_coserver.service
[Unit]
Description=coserver
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/coserver
ExecStart=${DNFS_DIR}/build/coserver/df_coserver_r coserver start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_community.service
[Unit]
Description=community
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/community
ExecStart=${DNFS_DIR}/build/community/df_community_r community start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_gunnersvr.service
[Unit]
Description=gunnersvr
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/secsvr/gunnersvr
ExecStart=${DNFS_DIR}/build/secsvr/gunnersvr/gunnersvr -t30 -i1
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_zergsvr1.service
[Unit]
Description=zergsvr1
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/secsvr/zergsvr
ExecStart=${DNFS_DIR}/build/secsvr/zergsvr/secagent
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_zergsvr2.service
[Unit]
Description=zergsvr2
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/secsvr/zergsvr
ExecStart=${DNFS_DIR}/build/secsvr/zergsvr/zergsvr -t30 -i1
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_game1.service
[Unit]
Description=game1
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/game
ExecStart=${DNFS_DIR}/build/game/df_game_r siroco11 start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/lib/systemd/system/df_game2.service
[Unit]
Description=game2
After=syslog.target
After=network.target

[Service]
Environment=dm=_r
RestartSec=2s
Type=forking
WorkingDirectory=${DNFS_DIR}/build/game
ExecStart=${DNFS_DIR}/build/game/df_game_r siroco52 start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now df_stun df_monitor df_manager df_relay df_bridge df_channel df_dbmw_guild df_dbmw_mnt df_dbmw_stat df_auction df_point df_guild df_statics df_coserver df_community df_gunnersvr df_zergsvr1 df_zergsvr2 df_game1 df_game2

echo "dnf installation completed successfully!"
echo "You can access it at: tcp "


echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############
