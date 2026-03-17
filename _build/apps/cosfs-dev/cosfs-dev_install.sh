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


echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############
