#!/usr/bin/env bash
# Puts shunt online at https://shunt.tomrhodes.it (SPEC.md §9).
#
# Run it from a checkout of the repo, on a computer with Haxe and Node:
#
#     deploy/deploy.sh you@your-vps [ssh-port]
#
# It builds the game and the server here, copies them up, and then runs
# deploy/on-the-server.sh there with sudo (it asks for your password).
# Run it again whenever the game changes: the first time it also sets up
# the service, nginx and the certificate; after that it just updates.
set -euo pipefail

server="${1:?Say where: deploy/deploy.sh you@your-vps [ssh-port]}"
port="${2:-22}"
repo="$(cd "$(dirname "$0")/.." && pwd)"
upload="shunt-upload"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

say "Checking the tools needed here"
for tool in haxe node npm rsync ssh; do
	command -v "$tool" >/dev/null || { echo "Needs $tool, which isn't installed here."; exit 1; }
done

say "Building the game page"
(cd "$repo/client" && haxe build.hxml)

say "Building the server"
(cd "$repo/server" && npm ci && npm run build)

say "Copying everything up to $server"
copy() { rsync -az --delete -e "ssh -p $port" "$@"; }
ssh -p "$port" "$server" "mkdir -p $upload/server"
copy "$repo/client/www/" "$server:$upload/www/"
copy "$repo/tracks/" "$server:$upload/tracks/"
copy "$repo/server/dist" "$repo/server/package.json" "$repo/server/package-lock.json" "$server:$upload/server/"
copy "$repo/deploy/" "$server:$upload/deploy/"

say "Setting it up there (sudo will ask for your password)"
ssh -t -p "$port" "$server" "sudo bash $upload/deploy/on-the-server.sh \"\$HOME/$upload\""
