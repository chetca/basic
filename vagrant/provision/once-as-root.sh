#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Enable russian locale"
sed -i '/^# ru_RU\.UTF-8 UTF-8/s/^#\s*//' /etc/locale.gen
locale-gen
echo "Done!"

info "Configure timezone"
timedatectl set-timezone ${TIMEZONE} --no-ask-password
echo "Done!"

info "Update OS software"
apt-get update
apt-get upgrade -y
echo "Done!"

info "Add PHP 7.2 repository"
add-apt-repository ppa:ondrej/php -y
apt-get update
echo "Done!"

info "Install additional software"
apt-get install -y php7.2 php7.2-curl php7.2-cli php7.2-fpm php7.2-intl php7.2-mbstring php7.2-gd php7.2-zip php7.2-xml php7.2-mysql nginx supervisor curl mc
echo "Done!"

info "Prepare root password for MySQL (MariaDB)"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
echo "Done!"

info "Install MariaDB 10.2"
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64] http://mirror.timeweb.ru/mariadb/repo/10.2/debian stretch main'
apt-get update
apt-get install -y mariadb-server
echo "Done!"

info "Configure MySQL"
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"

info "Configure PHP-FPM"
sed -i 's/user = www-data/user = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php/7.2/fpm/pool.d/www.conf
cat << EOF > /etc/php/7.2/mods-available/xdebug.ini
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_autostart=1
EOF
echo "Done!"

info "Configure NGINX"
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

info "Enabling site configuration"
ln -s /app/vagrant/nginx/app.conf /etc/nginx/sites-enabled/app.conf
echo "Done!"

info "Removing default site configuration"
rm /etc/nginx/sites-enabled/default
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE yii2basic"
mysql -uroot <<< "CREATE DATABASE yii2basic_test"
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
echo "Done!"

info "Install phpmyadmin"
apt-get install -q -y -f phpmyadmin
ln -s /usr/share/phpmyadmin /app/web
service php7.2-fpm restart
service nginx restart
echo "Done!"
