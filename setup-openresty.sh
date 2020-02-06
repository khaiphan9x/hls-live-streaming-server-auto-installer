#! /bin/bash
#
# Coded by Khai Phan
#
# Email: khaiphan9x@gmail.com
#
# Auto installer RTMP server script for
# Debian and Ubuntu
#
#

openesty_version="1.15.8.2"
php_version="7.3"
nginx_path="/usr/local/openresty/nginx"
build_path="kkk"

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

clear
mkdir /tmp/openresty-nginx-rtmp-build
cd /tmp/openresty-nginx-rtmp-build
echo "Ban dang su dung script tu dong cai dat OpenResty Nginx RTMP cho Debian va Ubuntu duoc viet boi Khai Phan"
echo "================================================"
echo "" 
echo "Dang cap nhat tai nguyen..."
apt-get update > /dev/null 2>&1
apt-get -y upgrade > /dev/null 2>&1
echo ""
echo "Bat dau cai dat OpenResty NGINX RTMP Server"
echo ""

read -e -p "Nhap port RTMP: " -i "1935" rtmp_port
read -e -p "Nhap port HTTP: " -i "80" http_port

apt-get -y install \
  build-essential \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  zlib1g \
  zlib1g-dev \
  libssl-dev \
  unzip \
  gcc \
  lsof

// Install OpenResty
echo ""
echo "Dang cai dat Openresty..."
wget https://github.com/winshining/nginx-http-flv-module/archive/master.zip -O nginx-http-flv.zip && unzip nginx-http-flv.zip
wget https://github.com/openresty/headers-more-nginx-module/archive/master.zip -O headers-more-nginx.zip && unzip headers-more-nginx.zip
wget "https://openresty.org/download/openresty-${openresty_version}.tar.gz" && tar -zxvf "openresty-${openresty_version}.tar.gz"
cd "openresty-${openresty_version}"

./configure --user=www-data --group=www-data \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --add-module=../nginx-http-flv-module-master \
  --add-module=../headers-more-nginx-module-master
make -j8 && make install && make clean

// Install PHP
echo ""
echo "Dang cai dat PHP..."
apt-get -y install \
  software-properties-common
apt-get update
apt-get -y install \
  "php${php_version}-fpm" \
  "php${php_version}-curl"
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' "/etc/php/${php_version}/fpm/php.ini"

// Install FFMPEG
echo ""
echo "Dang cai dat FFMPEG..."
apt-get -y install \
  yasm \
  libx264-dev \
  x264 \
  libmp3lame-dev \
  libtheora-dev \
  libvorbis-dev \
  libxvidcore-dev \
  libxext-dev \
  libxfixes-dev \
  ffmpeg

echo ""
echo "Dang tao cac thu muc can thiet"
mkdir -p \
  "${nginx_path}/conf.d" \
  "${nginx_path}/html/rec" \
  /tmp/hls
chown -R www-data:www-data /tmp/hls

echo ""
echo "Dang tao file /etc/init.d/openresty"
wget https://raw.githubusercontent.com/openresty/openresty-packaging/master/deb/openresty/debian/openresty.init -O /etc/init.d/openresty > /dev/null 2>&1 && chmod +x /etc/init.d/openresty

echo ""
echo "Dang tao file config file ${nginx_path}/conf/nginx.conf"
wget https://raw.githubusercontent.com/khaiphan9x/hls-live-streaming-server-auto-installer/master/nginx-openresty.conf -O "${nginx_path}/conf/nginx.conf" > /dev/null 2>&1
sed -i "s/RTMP_PORT/${rtmp_port}/g" "${nginx_path}/conf/nginx.conf"
sed -i "s/HTTP_PORT/${http_port}/g" "${nginx_path}/conf/nginx.conf"

echo ""
echo "Dang cai dat PHP HTTP Proxy"
wget https://github.com/walkor/php-http-proxy/archive/master.zip -O php-http-proxy.zip && unzip php-http-proxy.zip -d ~/ && sed -i 's/8080/8686/g' ~/php-http-proxy-master/start.php

echo ""
echo "Dang tai cac tai nguyen can thiet"

echo ""
echo "Dang cai dat script ho tro"
wget https://raw.githubusercontent.com/khaiphan9x/hls-live-streaming-server-auto-installer/master/start.sh -O ~/start.sh > /dev/null 2>&1 && chmod +x ~/start.sh

echo ""
echo "Dang don dep rac sau cai dat"
rm -rf /tmp/openresty-nginx-rtmp-build
rm ~/setup-openresty.sh

ln -s /etc/init.d/openresty /etc/init.d/nginx
update-rc.d openresty defaults
update-rc.d php7.3-fpm defaults
cd ~
bash start.sh

echo ""
echo ""
echo "Da hoan thanh cai dat"
echo "Push to rtmp://<host>:11935/input/<yourkey>_<yourhash>"