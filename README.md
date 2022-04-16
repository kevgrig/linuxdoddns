# linuxdoddns

## Installation

1. `sudo git clone https://github.com/kevgrig/linuxdoddns /opt/linuxdoddns`
2. Create API token at <https://cloud.digitalocean.com/account/api/tokens>
3. `sudo vi /etc/linuxdodns.pwd` with contents set to that token
4. `sudo chmod 600 /etc/linuxdodns.pwd`
5. `sudo ln -s /opt/linuxdoddns/linuxdodns@.service /etc/systemd/system/linuxdodns@.service`
6. `sudo systemctl daemon-reload`
7. `sudo systemctl start linuxdodns@$SUBDOMAIN.$DOMAIN.service`
8. `sudo systemctl status linuxdodns@$SUBDOMAIN.$DOMAIN.service`
9. `sudo systemctl enable linuxdodns@$SUBDOMAIN.$DOMAIN.service`
