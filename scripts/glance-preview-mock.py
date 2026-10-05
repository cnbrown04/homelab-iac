#!/usr/bin/env python3
"""Fake APIs for the local preview of Glance. See scripts/glance-preview.sh.

The server answers the calls of the Proxmox API (/pantheon, /atlas), of the
Kubernetes API (/k8s), and of glance-k8s (/svc/glance-k8s) with fake data.
Each other path gets 200, so the monitors show the services as up.
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

GIB = 1024**3
DAY = 86400
COMMIT = os.environ.get("PREVIEW_COMMIT", "0" * 40)


def now(minutes_ago=0):
    time = datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)
    return time.strftime("%Y-%m-%dT%H:%M:%SZ")


def pve_node(name, cpu, maxcpu, mem, maxmem, disk, maxdisk, days, status="online"):
    return {
        "type": "node", "node": name, "status": status, "uptime": days * DAY,
        "cpu": cpu, "maxcpu": maxcpu, "mem": mem * GIB, "maxmem": maxmem * GIB,
        "disk": disk * GIB, "maxdisk": maxdisk * GIB,
    }


def pve_guest(vmid, name, node, kind="qemu", status="running", cpu=0.05, maxcpu=4, mem=4.0, maxmem=8, template=0, tags=""):
    guest = {
        "type": kind, "vmid": vmid, "name": name, "node": node, "status": status,
        "cpu": cpu, "maxcpu": maxcpu, "mem": mem * GIB, "maxmem": maxmem * GIB,
        "template": template,
    }
    # Proxmox sends no tags field for a guest with no tags.
    if tags:
        guest["tags"] = tags
    return guest


def pve_storage(storage, node, disk, maxdisk, status="available"):
    return {
        "type": "storage", "storage": storage, "node": node, "status": status,
        "disk": disk * GIB, "maxdisk": maxdisk * GIB,
    }


PROXMOX = {
    "pantheon": {
        "node": [
            pve_node("gaia", 0.31, 16, 41, 64, 12, 94, 23),
            pve_node("hyperion", 0.18, 12, 22, 32, 9, 94, 23),
            pve_node("tartarus", 0.04, 8, 5, 16, 7, 94, 11),
            pve_node("theia", 0, 8, 0, 16, 0, 94, 0, status="offline"),
        ],
        "vm": [
            pve_guest(501, "typhon-cp-1", "gaia", cpu=0.12, maxcpu=4, mem=3.1, maxmem=4, tags="controlplane;talos;typhon"),
            pve_guest(511, "typhon-w-1", "gaia", cpu=0.21, mem=6.2, tags="talos;typhon;worker"),
            pve_guest(512, "typhon-w-2", "gaia", cpu=0.09, mem=5.4, tags="talos;typhon;worker"),
            pve_guest(513, "typhon-w-3", "hyperion", cpu=0.47, mem=7.1, tags="talos;typhon;worker"),
            pve_guest(514, "typhon-w-4", "hyperion", cpu=0.06, mem=4.8, tags="talos;typhon;worker"),
            pve_guest(9000, "debian-13-template", "gaia", status="stopped", template=1),
        ],
        "storage": [
            pve_storage("lethe", "gaia", 21400, 36000),
            pve_storage("local", "gaia", 12, 94),
            pve_storage("local-lvm", "gaia", 160, 350),
            pve_storage("local", "hyperion", 9, 94),
            pve_storage("local-lvm", "hyperion", 310, 350),
            pve_storage("local", "tartarus", 7, 94),
        ],
    },
    "atlas": {
        "node": [pve_node("atlas", 0.07, 4, 6, 16, 8, 58, 41)],
        "vm": [
            pve_guest(100, "haos-18.2", "atlas", cpu=0.03, maxcpu=2, mem=2.6, maxmem=4),
            pve_guest(200, "example", "atlas", kind="lxc", status="stopped", maxcpu=1, maxmem=1),
        ],
        "storage": [pve_storage("local", "atlas", 8, 58)],
    },
}


def flux_ready(name, revision):
    return {
        "metadata": {"name": name},
        "status": {
            "conditions": [{"type": "Ready", "status": "True"}],
            "lastAppliedRevision": revision,
        },
    }


def helm_release(name, version):
    return {
        "metadata": {"name": name},
        "status": {
            "conditions": [{"type": "Ready", "status": "True"}],
            "history": [{"chartVersion": version}],
        },
    }


def kubernetes(path):
    revision = "main@sha1:" + COMMIT
    if path == "/apis/kustomize.toolkit.fluxcd.io/v1/kustomizations":
        items = [flux_ready(name, revision) for name in
                 ["flux", "gateway-api-crds", "infrastructure-controllers", "infrastructure-configs", "apps"]]
    elif path == "/apis/helm.toolkit.fluxcd.io/v2/helmreleases":
        items = [helm_release("cilium", "1.20.2"), helm_release("csi-driver-nfs", "4.13.4"),
                 helm_release("local-path-provisioner", "0.0.33"), helm_release("metrics-server", "3.14.0")]
    elif path == "/apis/source.toolkit.fluxcd.io/v1/gitrepositories":
        items = [{
            "metadata": {"name": "homelab-iac"},
            "status": {"artifact": {"revision": revision, "lastUpdateTime": now(minutes_ago=4)}},
        }]
    else:
        return None
    return {"items": items}


# The HTML of glance-k8s v0.5.7, from internal/extension/templates. The icons
# are from heroicons.com, the same as in glance-k8s.
SERVER_ICON = (
    '<svg class="server-icon" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">'
    '<path stroke-linecap="round" stroke-linejoin="round" d="M21.75 17.25v-.228a4.5 4.5 0 0 0-.12-1.03l-2.268-9.64a3.375 3.375 0 0 0-3.285-2.602H7.923a3.375 3.375 0 0 0-3.285 2.602l-2.268 9.64a4.5 4.5 0 0 0-.12 1.03v.228m19.5 0a3 3 0 0 1-3 3H5.25a3 3 0 0 1-3-3m19.5 0a3 3 0 0 0-3-3H5.25a3 3 0 0 0-3 3m16.5 0h.008v.008h-.008v-.008Zm-3 0h.008v.008h-.008v-.008Z" /></svg>'
)
CHECK_ICON = (
    '<svg class="docker-container-status-icon color-positive" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">'
    '<path fill-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z" clip-rule="evenodd" /></svg>'
)
WARN_ICON = (
    '<svg class="docker-container-status-icon color-negative" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">'
    '<path fill-rule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495ZM10 5a.75.75 0 0 1 .75.75v3.5a.75.75 0 0 1-1.5 0v-3.5A.75.75 0 0 1 10 5Zm0 9a1 1 0 1 0 0-2 1 1 0 0 0 0 2Z" clip-rule="evenodd" /></svg>'
)

# name, role, uptime, CPU %, RAM %, RAM used, RAM size
K8S_NODES = [
    ("typhon-cp-1", "control-plane", "23d", 12.41, 61.20, "2.4Gi", "3.8Gi"),
    ("typhon-w-1", "", "23d", 21.07, 74.95, "5.8Gi", "7.7Gi"),
    ("typhon-w-2", "", "23d", 8.88, 66.12, "5.1Gi", "7.7Gi"),
    ("typhon-w-3", "", "6d", 46.53, 89.40, "6.9Gi", "7.7Gi"),
    ("typhon-w-4", "", "23d", 5.92, 58.03, "4.5Gi", "7.7Gi"),
]

# name, icon, host, ready, replicas
K8S_APPS = [
    ("Audiobookshelf", "audiobookshelf", "audiobooks", 1, 1),
    ("Chaptarr", "readarr", "chaptarr", 1, 1),
    ("Glance", "glance", "glance", 1, 1),
    ("Jackett", "jackett", "jackett", 1, 1),
    ("Jellyfin", "jellyfin", "jellyfin", 1, 1),
    ("Prowlarr", "prowlarr", "prowlarr", 1, 1),
    ("qBittorrent", "qbittorrent", "qbittorrent", 1, 1),
    ("Radarr", "radarr", "radarr", 1, 1),
    ("Seerr", "jellyseerr", "seerr", 0, 1),
    ("Sonarr", "sonarr", "sonarr", 1, 1),
]


def stat(label, percent, popover=""):
    bar = f'<div class="progress-bar"><div class="progress-value" style="--percent: {percent}"></div></div>'
    if popover:
        bar = f'<div data-popover-type="html"><div data-popover-html>{popover}</div>{bar}</div>'
    return (
        '<div class="flex-1"><div class="flex items-end size-h5">'
        f'<div>{label}</div><div class="color-highlight margin-left-auto text-very-compact">'
        f'{percent:.2f} <span class="color-base">%</span></div></div>{bar}</div>'
    )


def extension_nodes():
    html = ""
    for name, role, uptime, cpu, mem, used, size in K8S_NODES:
        roles = f'<div class="size-h5 text-compact">ROLES</div><div class="color-highlight">{role}</div>' if role else ""
        ram = (
            '<div class="flex"><div class="size-h5">RAM</div><div class="value-separator"></div>'
            f'<div class="color-highlight text-very-compact">{used} <span class="color-base size-h5">/</span> {size}</div></div>'
        )
        html += (
            '<div class="server"><div class="server-info"><div class="server-details">'
            f'<div class="server-name color-highlight size-h3">{name}</div><div>{uptime} uptime</div></div>'
            '<div class="shrink-0" data-popover-type="html" data-popover-margin="0.2rem" data-popover-max-width="400px">'
            '<div data-popover-html><div class="size-h5 text-compact">PLATFORM</div>'
            '<div class="color-highlight">Talos (v1.14.2)</div><div class="size-h5 text-compact">KUBLET</div>'
            f'<div class="color-highlight">v1.37.1</div>{roles}</div>'
            f'<div class="color-positive">{SERVER_ICON}</div></div></div>'
            f'<div class="server-stats">{stat("CPU", cpu)}{stat("RAM", mem, ram)}</div></div>'
        )
    return html


def extension_apps():
    html = '<ul class="dynamic-columns list-gap-20 list-with-separator">'
    for name, icon, host, ready, replicas in K8S_APPS:
        count = f'<span class="color-negative">{ready}</span>' if ready != replicas else str(ready)
        html += (
            '<li class="docker-container flex items-center gap-15">'
            '<div class="shrink-0" data-popover-type="html" data-popover-position="above" data-popover-offset="0.25" data-popover-margin="0.1rem" data-popover-max-width="400px">'
            f'<img class="docker-container-icon" src="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/{icon}.svg" loading="lazy">'
            f'<div data-popover-html><div class="flex"><div class="size-h5">{name.lower()}</div><div class="value-separator"></div>'
            f'<div class="color-highlight text-very-compact">{count} <span class="color-base">/</span> {replicas}</div></div></div></div>'
            f'<div class="min-width-0 grow"><a class="color-highlight size-title-dynamic block text-truncate" href="https://{host}.buildwithcaleb.com" target="_blank" rel="noreferrer">{name}</a></div>'
            f'<div class="margin-left-auto shrink-0">{CHECK_ICON if ready == replicas else WARN_ICON}</div></li>'
        )
    return html + "</ul>"


EXTENSIONS = {
    "nodes": ("Kubernetes Nodes", extension_nodes),
    "apps": ("Kubernetes Apps", extension_apps),
}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        url = urlparse(self.path)
        prefix, _, rest = url.path.lstrip("/").partition("/")
        if rest.startswith("glance-k8s/extension/"):
            title, render = EXTENSIONS[rest.rsplit("/", 1)[1]]
            self.send(render(), "text/html", {
                "Widget-Title": title,
                "Widget-Content-Type": "html",
                "Widget-Content-Frameless": "false",
            })
            return
        body = None
        if prefix in PROXMOX and rest == "api2/json/cluster/resources":
            kind = parse_qs(url.query).get("type", [""])[0]
            body = {"data": PROXMOX[prefix].get(kind, [])}
        elif prefix == "k8s":
            body = kubernetes("/" + rest)
        if body is None:
            body = {"status": "ok"}
        self.send(json.dumps(body), "application/json")

    def send(self, text, content_type, headers=None):
        data = text.encode()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        for name, value in (headers or {}).items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8092
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
