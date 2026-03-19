###############

silent() { "$@" >/dev/null 2>&1 || { echo "Error running: $*"; echo "sth error"; exit 1; }; }


debmirror=${1:-http://deb.debian.org/debian}
echo -e "deb ${debmirror} bullseye main\ndeb ${debmirror} bullseye-updates main\ndeb ${debmirror}-security bullseye-security main" > /etc/apt/sources.list

echo "Installing Dependencies"
silent apt-get update -y
silent apt-get install -y curl sudo mc
echo "Installed Dependencies"

cd /root

rlsmirror=${2:-https://github.com/minlearn/inst/releases/download/inital}
mkdir -p download
wget --no-check-certificate https://ftp.gnu.org/gnu/gcc/gcc-7.5.0/gcc-7.5.0.tar.xz -O download/gcc.xz
wget --no-check-certificate https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz -O download/python.xz
wget --no-check-certificate https://www.kernel.org/pub/linux/kernel/v2.6/linux-2.6.33.7.tar.xz -O download/linuxsrc.xz

silent apt-get -y install build-essential libgmp-dev libmpfr-dev libmpc-dev
silent apt-get -y install libssl-dev libbz2-dev libreadline-dev libsqlite3-dev
silent apt-get -y install git

tar xJf download/gcc.xz
cd gcc-7.5.0
./configure --prefix=/usr/local/gcc-7.5.0 --enable-languages=c
make -j$(nproc)
make install
cd ..

tar xJf download/python.xz
cd Python-2.7.18
./configure
make -j$(nproc)
make install
cd ..

mkdir -p linux-2.6.33.7-source linux-2.6.33.7-source_tobepatch
tar xJf -C linux-2.6.33.7-source download/linuxsrc.xz --strip-components=1
tar xJf -C linux-2.6.33.7-source_tobepatch download/linuxsrc.xz --strip-components=1

git clone https://github.com/da-x/colinux

cat > /root/start.sh << 'EOL'
cd /root

export PATH=/usr/local/gcc-7.5.0/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/gcc-7.5.0/lib64:$LD_LIBRARY_PATH
export CC=gcc
export CXX=g++
export AR=ar
export LD=ld

cd colinux

echo "Compiling"
./configure --colinux-os=linux --targetkerneldir=/root/linux-2.6.33.7-source_tobepatch --hostkerneldir=/root/linux-2.6.33.7-source
make -j$(nproc)
echo "Compiled"
EOL
chmod +x /root/start.sh


echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############
