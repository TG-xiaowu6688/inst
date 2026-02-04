###############

silent() { "$@" >/dev/null 2>&1 || { echo "Error running: $*"; echo "sth error"; exit 1; }; }


debmirror=${1:-http://deb.debian.org/debian}
echo -e "deb ${debmirror} bullseye main\ndeb ${debmirror} bullseye-updates main\ndeb ${debmirror}-security bullseye-security main" > /etc/apt/sources.list

echo "Installing Dependencies"
silent apt-get update -y
silent apt-get install -y curl sudo mc
echo "Installed Dependencies"

silent apt-get install -y openjdk-11-jdk postgresql-client git unzip
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | tee /etc/apt/trusted.gpg.d/sbt.asc
silent apt-get update
silent apt-get install sbt

cat > /root/compile.sh << 'EOL'
cd /root
git clone https://github.com/debiki/talkyard.git
git checkout 9ef9b55d16301fa67087993c83b2a954aae323f4
cd talkyard
git submodule update --init --recursive
sbt compile
sbt dist

# https://github.com/debiki/talkyard/blob/main/s/impl/build-prod-app-image.sh
rm -rf /opt/talkyard
mkdir -p /opt/talkyard
cp -a images/app/assets /opt/talkyard/
cp version.txt /opt/talkyard/
version="`cat version.txt | sed s/WIP/SNAPSHOT/`"
if [[ ! -f target/universal/talkyard-server-$version.zip ]]; then
  echo "Error: output File target/universal/talkyard-server-$version.zip not found."
  exit 1
fi
unzip -o -q target/universal/talkyard-server-$version.zip -d /opt/talkyard
mv /opt/talkyard/talkyard-server-$version /opt/talkyard/app

# https://github.com/debiki/talkyard-prod-one/raw/refs/heads/main/conf/play-framework.conf
wget -q https://github.com/debiki/talkyard-prod-one/raw/refs/heads/main/conf/play-framework.conf -O /opt/talkyard/app/conf/app-prod-override.conf

EOL

cat > /root/start.sh << 'EOL'
#!/bin/bash

# https://github.com/debiki/talkyard/blob/main/images/app/Dockerfile.prod
PLAY_HEAP_MEMORY_MB=1024

/opt/talkyard/app/bin/talkyard-server \
  -J-Xms${PLAY_HEAP_MEMORY_MB}m \
  -J-Xmx${PLAY_HEAP_MEMORY_MB}m \
  -J-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:9999 \
  -Dcom.sun.management.jmxremote.port=3333 \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dhttp.port=9000 \
  -Dlogback.configurationFile=/opt/talkyard/app/conf/logback-prod.xml \
  -Dconfig.file=/opt/talkyard/app/conf/app-prod.conf
EOL

echo "Cleaning up"
silent apt-get -y autoremove
silent apt-get -y autoclean
echo "Cleaned"

##############
