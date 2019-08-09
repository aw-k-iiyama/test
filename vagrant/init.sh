#!/bin/sh

setenforce 0
timedatectl set-timezone Asia/Tokyo

yum -y update
yum -y install https://centos7.iuscommunity.org/ius-release.rpm

#----------------------------------------------------------------
# install
#----------------------------------------------------------------
# MySQL
yum -y remove mariadb-libs
rm -rf /var/lib/mysql/
rpm -ivh https://dev.mysql.com/get/mysql80-community-release-el7-2.noarch.rpm
yum -y install mysql-community-server
systemctl enable mysqld.service
# password policy を変更するので事前に初回起動しておく
systemctl start mysqld.service
systemctl stop mysqld.service

# httpd
yum -y install https://centos7.iuscommunity.org/ius-release.rpm
yum -y install openldap-devel expat-devel libdb-devel mailcap system-logos
yum --disablerepo=base,extras,updates --enablerepo=ius -y install httpd mod_ssl
systemctl enable httpd.service

# PHP
yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum -y install --enablerepo=remi,remi-php73 php php-devel php-mbstring php-pdo php-gd php-xml php-mcrypt php-pecl-zip php-mysql

# Postfix
rpm -ivh http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm
yum -y --enablerepo=gf-plus install postfix3
systemctl enable postfix

# git
yum -y install gcc curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker
git clone git://git.kernel.org/pub/scm/git/git.git
cd git
make prefix=/usr/local all
make prefix=/usr/local install
export PATH=/usr/local/bin:$PATH
cd ..
rm -rf git

#----------------------------------------------------------------
# start service
#----------------------------------------------------------------
systemctl start postfix
systemctl start mysqld.service
systemctl start httpd.service

#----------------------------------------------------------------
# DB init
#----------------------------------------------------------------
DB_PW=`grep password /var/log/mysqld.log | tail -1 | awk '{ print $(NF) }'`
mysql --connect-expired-password -u root -p${DB_PW} <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
CREATE DATABASE testapp;
CREATE USER testuser IDENTIFIED BY 'testuser';
GRANT ALL PRIVILEGES ON testapp.* TO testuser;
EOF
