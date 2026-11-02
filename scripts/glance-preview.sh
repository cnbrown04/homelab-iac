#!/usr/bin/env bash
# Runs the dashboard (Dynacat, a fork of Glance) on this machine, with fake
# data, at http://localhost:8091. Run it from the root of the repository:
#
#   scripts/glance-preview.sh
#
# The script copies typhon-cluster/apps/glance/dynacat.yml to .glance-preview/
# and changes the copy:
#   - Each ${secret:...} gets a placeholder value.
#   - The Proxmox API, the Kubernetes API, and each check of a service in the
#     cluster go to scripts/glance-preview-mock.py, which gives fake data.
# GitHub, the feeds, and the public services give real data.
# After a change to dynacat.yml, the script makes the copy again, and Dynacat
# reads it. Reload the page.
set -euo pipefail

source_config=typhon-cluster/apps/glance/dynacat.yml
dir=.glance-preview
glance_port=8091
mock_port=8092
mock="http://127.0.0.1:${mock_port}"

# Use the version of Dynacat that the cluster runs.
version=$(grep -o 'panonim/dynacat:[0-9.]*' typhon-cluster/apps/glance/deployment.yaml | cut -d: -f2)

mkdir -p "$dir"
if [[ ! -x "$dir/dynacat-$version" ]]; then
  echo "Downloading Dynacat $version."
  base="https://github.com/Panonim/dynacat/releases/download/${version}"
  curl -fsSL -o "$dir/dynacat.tar.gz" "$base/dynacat-linux-amd64.tar.gz"
  # Check the file against the checksums of the release.
  sum=$(curl -fsSL "$base/checksums.txt" | awk '$2 == "dynacat-linux-amd64.tar.gz" { print $1 }')
  echo "$sum  $dir/dynacat.tar.gz" | sha256sum -c --quiet
  tar -xzf "$dir/dynacat.tar.gz" -C "$dir" dynacat
  rm "$dir/dynacat.tar.gz"
  mv "$dir/dynacat" "$dir/dynacat-$version"
fi

render() {
  sed -E \
    -e 's/\$\{secret:[a-z-]+\}/local-preview/g' \
    -e "s/^  port: 8080$/  port: ${glance_port}/" \
    -e 's/^  proxied: true$/  proxied: false/' \
    -e "s#https://10\.0\.1\.120:8006#${mock}/pantheon#g" \
    -e "s#https://10\.0\.1\.124:8006#${mock}/atlas#g" \
    -e "s#https://kubernetes\.default\.svc#${mock}/k8s#g" \
    -e "s#http://([a-z0-9-]+)\.[a-z0-9-]+\.svc\.cluster\.local(:[0-9]+)?#${mock}/svc/\1#g" \
    -e "s#http://10\.0\.1\.69(:[0-9]+)?#${mock}/home#g" \
    "$source_config" >"$dir/dynacat.yml"
}

render
# Dynacat writes its cache to .cache/ in the folder where it starts.
(cd "$dir" && "./dynacat-$version" -config dynacat.yml config:validate)

PREVIEW_COMMIT=$(git rev-parse HEAD) python3 scripts/glance-preview-mock.py "$mock_port" &
mock_pid=$!

# Make the copy again when dynacat.yml changes.
(
  while sleep 1; do
    if [[ "$source_config" -nt "$dir/dynacat.yml" ]]; then
      render
      echo "Copied the changes of $source_config."
    fi
  done
) &
watch_pid=$!

trap 'kill "$mock_pid" "$watch_pid" 2>/dev/null' EXIT

echo "Open http://localhost:${glance_port}. Push Ctrl+C to stop."
(cd "$dir" && "./dynacat-$version" -config dynacat.yml)
