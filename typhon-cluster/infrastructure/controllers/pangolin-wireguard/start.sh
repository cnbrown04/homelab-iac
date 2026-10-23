#!/bin/bash
# The peer of the basic WireGuard site "typhon" of Pangolin. Gerbil on hermes
# and this pod both use kernel WireGuard. Pangolin sends each request to the
# tunnel address of this pod, and NAT sends it on to the Gateway.
set -euo pipefail

conf=/etc/wireguard/pangolin.conf
ipt=$(command -v iptables-nft || command -v iptables)

# The network namespace of the pod stays after a restart of the container.
ip link delete wg0 2>/dev/null || true
"$ipt" -t nat -F
"$ipt" -F FORWARD

# wg setconf does not accept the wg-quick fields Address, DNS, and MTU.
address=$(awk -F' *= *' '/^Address/ {print $2}' "$conf")
tunnel_ip=${address%/*}
ip link add wg0 type wireguard
wg setconf wg0 <(grep -vE '^(Address|DNS|MTU)[[:space:]]*=' "$conf")
ip address add "$address" dev wg0
ip link set wg0 mtu "$MTU" up
for net in $(wg show wg0 allowed-ips | awk '{for (i = 2; i <= NF; i++) print $i}'); do
  ip route replace "$net" dev wg0
done

# Forward only the HTTP port of the tunnel address to the Gateway.
sysctl -qw net.ipv4.ip_forward=1
"$ipt" -P FORWARD DROP
"$ipt" -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
"$ipt" -A FORWARD -i wg0 -d "$GATEWAY_IP" -p tcp --dport "$GATEWAY_PORT" -j ACCEPT
"$ipt" -t nat -A PREROUTING -i wg0 -d "$tunnel_ip" -p tcp --dport "$GATEWAY_PORT" \
  -j DNAT --to-destination "$GATEWAY_IP:$GATEWAY_PORT"
"$ipt" -t nat -A POSTROUTING -o eth0 -d "$GATEWAY_IP" -j MASQUERADE

echo "wg0 is up at $tunnel_ip. Port $GATEWAY_PORT goes to $GATEWAY_IP."
trap 'ip link delete wg0; exit 0' TERM INT
sleep infinity &
wait
