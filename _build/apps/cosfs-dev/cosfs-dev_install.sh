###############

silent() { "$@" >/dev/null 2>&1 || { echo "Error running: $*"; echo "sth error"; exit 1; }; }


debmirror=${1:-http://deb.debian.org/debian}
echo -e "deb ${debmirror} bullseye main\ndeb ${debmirror} bullseye-updates main\ndeb ${debmirror}-security bullseye-security main" > /etc/apt/sources.list

echo "Installing Dependencies"
silent apt-get update -y
silent apt-get install -y curl sudo mc
echo "Installed Dependencies"

cd /root

silent apt-get -y install build-essential automake pkg-config libssl-dev libcurl4-gnutls-dev libxml2-dev libfuse-dev fuse
silent apt-get -y install git

git clone https://github.com/tencentyun/cosfs.git
cd cosfs
./autogen.sh
./configure
make
sudo make install

mkdir -p /lhcos-data
echo "Creating Service"
cat <<EOF >/etc/systemd/system/lhcos-data.service
[Unit]
Description=Mount COSFS Bucket
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/cosfs sg-xxx:/lhcos-data /lhcos-data \
  -ourl=http://cos.ap-yyy.myqcloud.com \
  -odbglevel=err \
  -oallow_other \
  -opublic_bucket=1 \
  -oensure_diskfree=5120 \
-f
ExecStop=fusermount -u /lhcos-data
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now lhcos-data
echo "Created Service"

echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############
