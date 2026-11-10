#!/usr/bin/env bash
# Runs on the VPS, as root (deploy/deploy.sh starts it): moves the upload
# into /opt/shunt, installs the server's packages, and (the first time)
# sets up the system service, the nginx site and the HTTPS certificate.
# Safe to run again and again.
set -euo pipefail

upload="${1:?Where the upload is}"
home=/opt/shunt
domain=shunt.tomrhodes.it
site=/etc/nginx/sites-available/$domain

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "Checking Node (Colyseus needs 22 or newer)"
major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$major" -lt 22 ]; then
	echo "Node here is version $major. Install Node 22, for example:"
	echo "  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - && sudo apt install -y nodejs"
	exit 1
fi

say "A user of its own for the server"
id shunt >/dev/null 2>&1 || useradd --system --home "$home" --shell /usr/sbin/nologin shunt

say "Moving the new version into $home"
mkdir -p "$home/server"
rsync -a --delete "$upload/www/" "$home/www/"
rsync -a --delete "$upload/tracks/" "$home/tracks/"
rsync -a --delete --exclude node_modules "$upload/server/" "$home/server/"
chown -R shunt:shunt "$home"
(cd "$home/server" && sudo -u shunt npm ci --omit=dev --no-audit --no-fund)

say "The system service"
install -m 644 "$upload/deploy/shunt.service" /etc/systemd/system/shunt.service
systemctl daemon-reload
systemctl enable shunt >/dev/null
systemctl restart shunt

say "The nginx site for $domain"
if [ ! -f "$site" ]; then
	install -m 644 "$upload/deploy/nginx-shunt.conf" "$site"
	ln -sf "$site" "/etc/nginx/sites-enabled/$domain"
	nginx -t && systemctl reload nginx
	echo "Getting a certificate (the DNS record for $domain must point here first)."
	if command -v certbot >/dev/null; then certbot --nginx -d "$domain"; else echo "certbot isn't installed: sudo apt install certbot python3-certbot-nginx, then: sudo certbot --nginx -d $domain"; fi
else
	echo "Already set up; left as it is."
fi

say "Checking it answers"
sleep 2
if curl -fsS http://127.0.0.1:2567/online.json >/dev/null; then echo "shunt is running: https://$domain"; else echo "It didn't answer. See: journalctl -u shunt -n 50"; exit 1; fi
