# Install repository
sudo apt-get update
sudo apt-get -fy install debian-archive-keyring
sudo apt-get -fy install curl gnupg apt-transport-https
curl -L https://packagecloud.io/varnishcache/varnish60/gpgkey | sudo apt-key add -

apt-get install -fy lsb-release bc
REL=`lsb_release -sc`
DISTRO=`lsb_release -is | tr [:upper:] [:lower:]`

deb https://packagecloud.io/varnishcache/varnish60/$DISTRO/ $REL main
deb-src https://packagecloud.io/varnishcache/varnish60/$DISTRO/ $REL main

sudo apt-get update

sudo apt-get  -fy install varnish
# sudo systemctl stop varnish.service
# sudo systemctl start varnish.service
# sudo systemctl enable varnish.service

# Change Nginx default port
sed -i "s,80;,8080;,g" /etc/nginx/conf.d/default.conf

wget https://raw.githubusercontent.com/juliosene/Wordpress-AWS-/master/files/varnish
mv varnish /etc/default/varnish

sudo systemctl stop varnish.service
sudo systemctl start varnish.service

# sudo /usr/sbin/varnishd -a :80 -b localhost:8080

# https://www.linode.com/docs/websites/varnish/use-varnish-and-nginx-to-serve-wordpress-over-ssl-and-http-on-debian-8/

