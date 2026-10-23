#!/usr/bin/env bash
# Makes the service map of README.md.
#
# The map shows each machine as a box. A Proxmox node holds the boxes of its
# VMs, and a VM holds its apps. The script writes a light and a dark version
# to .github/assets/. README.md shows the version that agrees with the theme
# of the reader.
#
# The workflow readme-services.yml runs this script after each change to it,
# and commits the result. To run it here: it needs curl, jq, and rsvg-convert.
#
# To add an app or a VM, change the lists below. The layout adapts to the
# lists. If a text does not fit in its box, the script stops with an error.
set -euo pipefail

out=${README_SERVICES_OUT:-.github/assets}
dashboard=https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons
selfhst=https://cdn.jsdelivr.net/gh/selfhst/icons
font='-apple-system,BlinkMacSystemFont,Segoe UI,Noto Sans,Helvetica,Arial,sans-serif'
# An icon larger than this goes into the map as a small PNG.
max_svg=6000

# Each logo and icon is the name of an icon of dashboard-icons, without
# ".svg". If dashboard-icons has no icon for an app, use "selfhst/<name>" for
# an icon of selfh.st, or the https URL of an SVG file. Each app is
# "<name>:<icon>". A subtitle can show a Proxmox node as
# "@<node>".

# The nodes of the pantheon cluster: the name and the hardware. The map puts
# four nodes in a row.
NODES=(
  "gaia|Dell PowerEdge R740"
  "hyperion|Dell OptiPlex Micro 7010"
  "tartarus|Dell PowerEdge R740xd"
  "theia|Dell OptiPlex Micro 7020"
)

# Each guest: the host, the name, the logo, the VMID, and the apps. The host
# is a node or a standalone host. A guest with no apps is a small chip.
GUESTS=(
  "gaia|mnemosyne|debian-linux|200|Samba:samba-server,OpenCloud:open-cloud"
  "gaia|typhon-cp-1|talos|501|"
  "gaia|typhon-w-1|talos|511|"
  "gaia|typhon-w-2|talos|512|"
  "hyperion|typhon-w-3|talos|513|"
  "hyperion|typhon-w-4|talos|514|"
  "tartarus|argus|ubuntu-linux|400|Wazuh:wazuh"
  "tartarus|daedalus|ubuntu-linux|300|Claude Code:claude-ai,opencode:opencode,Neovim:neovim"
  "atlas|Home Assistant|home-assistant|100|"
)

# The typhon cluster runs on the VMs of the nodes in TYPHON_NODES. Its box has
# a column for each group.
TYPHON="typhon|talos|Talos Kubernetes on the VMs of @gaia and @hyperion"
TYPHON_NODES=(gaia hyperion)
TYPHON_GROUPS=(
  "Platform|Flux:flux-cd,Glance:glance,Termix:termix,Faved:selfhst/faved,Its a Plan:https://cdn.jsdelivr.net/gh/croffasia/itsaplan@v1.7.0/apps/web/src/app/icon.svg"
  "Media|Jellyfin:jellyfin,Audiobookshelf:audiobookshelf,Seerr:seerr"
  "Library|Sonarr:sonarr,Radarr:radarr,Chaptarr:chaptarr"
  "Downloads|Prowlarr:prowlarr,Jackett:jackett,qBittorrent:qbittorrent"
)

# The hosts out of the cluster: the name, the logo, the subtitle, and the apps
# that run on the host itself. The box of a host also holds its guests. The
# map puts two hosts in a row.
STANDALONE=(
  "atlas|proxmox|ASRock DeskMini 110, standalone PVE node|"
  "hermes|ubuntu-linux|Dedirock VPS|Headscale:headscale,Pangolin:pangolin,Pocket ID:pocket-id,Headplane:headplane,Dockge:dockge"
)

width=878 gap=12 pad=14 row=26 head=52

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

fail() {
  printf 'readme-services.sh: %s\n' "$1" >&2
  exit 1
}

# Prints the path of a cached copy of a URL.
fetch() {
  local file
  file="$cache/$(printf '%s' "$1" | sha1sum | cut -d' ' -f1)"
  [[ -f $file ]] || curl -fsSL --retry 3 "$1" -o "$file" || fail "cannot download $1"
  printf '%s' "$file"
}

# Prints an SVG file as a data URI. A large SVG becomes a small PNG.
data_uri() {
  if (( $(wc -c < "$1") > max_svg )); then
    printf 'data:image/png;base64,%s' \
      "$(rsvg-convert -w 40 -h 40 --keep-aspect-ratio "$1" | base64 -w0)"
  else
    printf 'data:image/svg+xml;base64,%s' "$(base64 -w0 < "$1")"
  fi
}

# Prints the URL of the SVG file of an icon name.
svg_url() {
  if [[ $1 == https://* ]]; then
    printf '%s' "$1"
  elif [[ $1 == selfhst/* ]]; then
    printf '%s/svg/%s.svg' "$selfhst" "${1#selfhst/}"
  else
    printf '%s/svg/%s.svg' "$dashboard" "$1"
  fi
}

# Prints an icon. On a dark page, dashboard-icons has a "-light" icon for some
# apps. Some of these icons are not valid SVG, so the normal icon is the
# fallback. The result is cached, because the map uses some icons many times.
icon() {
  local name=$1 file key="$cache/icon-${1//\//-}$variant"
  if [[ ! -f $key ]]; then
    file=''
    # Only a name of dashboard-icons has no "/".
    if [[ -n $variant && $name != */* ]] \
        && jq -e --arg f "$name$variant.svg" '.svg | index($f)' \
        "$(fetch "$dashboard/tree.json")" > /dev/null; then
      file=$(fetch "$dashboard/svg/$name$variant.svg")
      rsvg-convert "$file" > /dev/null 2>&1 || file=''
    fi
    data_uri "${file:-$(fetch "$(svg_url "$name")")}" > "$key"
  fi
  cat "$key"
}

# Downloads each icon before the layout starts, so a wrong name stops the
# script with a clear error. tree.json of dashboard-icons is not complete, so
# the check downloads the icon itself.
check_icons() {
  local name url
  for name in "$@"; do
    url=$(svg_url "$name")
    [[ -f $cache/$(printf '%s' "$url" | sha1sum | cut -d' ' -f1) ]] && continue
    curl -fsSL --retry 3 "$url" \
      -o "$cache/$(printf '%s' "$url" | sha1sum | cut -d' ' -f1)" \
      || fail "no icon \"$name\" at $url"
  done
}

escape() {
  local s=${1//&/&amp;}
  s=${s//</&lt;}
  printf '%s' "${s//>/&gt;}"
}

# text <x> <y> <value> <color> <size> [weight] [anchor]
text() {
  printf '<text x="%s" y="%s" fill="%s" font-family="%s" font-size="%s" font-weight="%s" text-anchor="%s">%s</text>' \
    "$1" "$2" "$4" "$font" "$5" "${6:-normal}" "${7:-start}" "$(escape "$3")"
}

# image <x> <y> <size> <icon>
image() {
  printf '<image x="%s" y="%s" width="%s" height="%s" href="%s"/>' "$1" "$2" "$3" "$3" "$(icon "$4")"
}

# box <x> <y> <width> <height> <fill> <radius>
box() {
  printf '<rect x="%s.5" y="%s.5" width="%s" height="%s" rx="%s" fill="%s" stroke="%s"/>' \
    "$1" "$2" "$(( $3 - 1 ))" "$(( $4 - 1 ))" "$6" "$5" "$c_line"
}

# Prints the approximate width of a text in pixels. An SVG image cannot
# measure its text, so the layout uses this estimate. It is a little wide on
# purpose, so a text that fits here also fits in a browser.
# text_width <text> <size> [bold]
text_width() {
  awk -v s="$1" -v z="$2" -v b="${3:-0}" 'BEGIN {
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c ~ /[ijl.,:;|!]/) w += 0.27
      else if (c ~ /[frt ]/) w += 0.34
      else if (c ~ /[mw]/) w += 0.86
      else if (c ~ /[A-Z]/) w += 0.68
      else w += 0.56
    }
    printf "%d", w * z * (b ? 1.06 : 1) + 0.5
  }'
}

# Stops the script when a text is wider than the space for it.
# fits <text> <size> <bold> <space> <where>
fits() {
  local w
  w=$(text_width "$1" "$2" "$3")
  (( w <= $4 )) || fail "\"$1\" in $5 is ${w}px wide, and only $4px are free. Make it shorter."
}

count() {
  local -a list
  [[ -n $1 ]] || { printf 0; return; }
  IFS=, read -ra list <<< "$1"
  printf '%s' "${#list[@]}"
}

max() {
  printf '%s' "$(( $1 > $2 ? $1 : $2 ))"
}

# Prints the width that the widest app of a list needs, with its icon.
# app_width <apps> <font size> <icon size>
app_width() {
  local app widest=0
  local -a list
  IFS=, read -ra list <<< "$1"
  for app in "${list[@]}"; do
    widest=$(max "$widest" "$(text_width "${app%%:*}" "$2")")
  done
  printf '%s' "$(( widest + $3 + 8 ))"
}

# Prints a subtitle. Each word "@<node>" becomes the logo of Proxmox and the
# name of the node, in the color of the nodes. The other words stay together
# in one text, so the browser sets their spaces.
# subtitle <x> <y> <text> <space> <where>
subtitle() {
  local x=$1 word node plain=''
  local -a words
  read -ra words <<< "$3"
  for word in "${words[@]}" @; do
    if [[ $word != @* ]]; then
      plain+="${plain:+ }$word"
      continue
    fi
    if [[ -n $plain ]]; then
      text "$x" "$2" "$plain" "$c_muted" 12
      x=$(( x + $(text_width "$plain" 12) + 5 ))
      plain=''
    fi
    node=${word#@}
    [[ -n $node ]] || continue
    image "$x" "$(( $2 - 10 ))" 12 proxmox
    text "$(( x + 15 ))" "$2" "$node" "$c_node" 12 600
    x=$(( x + 15 + $(text_width "$node" 12 1) + 5 ))
  done
  (( x - 5 - $1 <= $4 )) || fail "the subtitle of $5 is too long. Make it shorter."
}

# The header of a large box.
# header <x> <y> <width> <name> <logo> <subtitle>
header() {
  fits "$4" 15 1 "$(( $3 - 2 * pad - 28 ))" "the box $4"
  image "$(( $1 + pad ))" "$(( $2 + pad ))" 20 "$5"
  text "$(( $1 + pad + 28 ))" "$(( $2 + pad + 15 ))" "$4" "$c_text" 15 600
  subtitle "$(( $1 + pad ))" "$(( $2 + pad + 36 ))" "$6" "$(( $3 - 2 * pad ))" "$4"
}

# apps <x> <y> <list of apps> [icon size] [font size] [row]
apps() {
  local i=0 app top size=${4:-18} font_size=${5:-13} step=${6:-$row}
  local -a list
  [[ -n $3 ]] || return 0
  IFS=, read -ra list <<< "$3"
  for app in "${list[@]}"; do
    top=$(( $2 + i * step ))
    image "$1" "$top" "$size" "${app#*:}"
    text "$(( $1 + size + 8 ))" "$(( top + size - 4 ))" "${app%%:*}" "$c_text" "$font_size"
    i=$(( i + 1 ))
  done
}

# Prints the number of columns for a list of apps in a space. The apps fill
# each column from the top, one after the other.
# app_columns <apps> <space>
app_columns() {
  local n need
  n=$(count "$1")
  need=$(( $(app_width "$1" 13 18) + 16 ))
  (( n > 0 )) || { printf 1; return; }
  printf '%s' "$(( $(max 1 "$(( ($2 + 16) / need ))") < n ? $(max 1 "$(( ($2 + 16) / need ))") : n ))"
}

# Prints the apps in columns.
# app_grid <x> <y> <width> <apps>
app_grid() {
  local cols per i
  local -a list
  [[ -n $4 ]] || return 0
  IFS=, read -ra list <<< "$4"
  cols=$(app_columns "$4" "$3")
  per=$(( (${#list[@]} + cols - 1) / cols ))
  fits "$(longest_app "$4")" 13 0 "$(( ($3 + 16) / cols - 16 - 26 ))" "the apps of a box"
  for (( i = 0; i < cols; i++ )); do
    apps "$(( $1 + i * ($3 + 16) / cols ))" "$2" "$(IFS=,; printf '%s' "${list[*]:i*per:per}")"
  done
}

# Prints the height of an app grid.
# app_grid_height <apps> <width>
app_grid_height() {
  local n cols
  n=$(count "$1")
  (( n > 0 )) || { printf 0; return; }
  cols=$(app_columns "$1" "$2")
  printf '%s' "$(( ((n + cols - 1) / cols) * row - 8 ))"
}

longest_app() {
  local app best='' bw=0 w
  local -a list
  IFS=, read -ra list <<< "$1"
  for app in "${list[@]}"; do
    w=$(text_width "${app%%:*}" 13)
    (( w > bw )) && { bw=$w; best=${app%%:*}; }
  done
  printf '%s' "$best"
}

# Prints the height of the box of a guest.
# guest_height <apps>
guest_height() {
  if [[ -z $1 ]]; then
    printf 28
  else
    printf '%s' "$(( 34 + $(count "$1") * 24 + 2 ))"
  fi
}

# guest <x> <y> <width> <name> <logo> <vmid> <apps>
guest() {
  local h app top
  local -a list
  h=$(guest_height "$7")
  fits "$4" 13 1 "$(( $3 - 31 - $(text_width "VM $6" 11) - 18 ))" "the guest $4"
  box "$1" "$2" "$3" "$h" "$c_guest" 7
  if [[ -z $7 ]]; then
    image "$(( $1 + 8 ))" "$(( $2 + 6 ))" 16 "$5"
    text "$(( $1 + 30 ))" "$(( $2 + 18 ))" "$4" "$c_text" 12 600
    text "$(( $1 + $3 - 9 ))" "$(( $2 + 18 ))" "VM $6" "$c_muted" 11 normal end
  else
    image "$(( $1 + 9 ))" "$(( $2 + 9 ))" 16 "$5"
    text "$(( $1 + 31 ))" "$(( $2 + 22 ))" "$4" "$c_text" 13 600
    text "$(( $1 + $3 - 9 ))" "$(( $2 + 22 ))" "VM $6" "$c_muted" 11 normal end
    IFS=, read -ra list <<< "$7"
    for app in "${list[@]}"; do
      fits "${app%%:*}" 12 0 "$(( $3 - 35 - 9 ))" "the guest $4"
    done
    apps "$(( $1 + 11 ))" "$(( $2 + 34 ))" "$7" 16 12 24
  fi
}

# Prints the height of the guests of a host, with the space between them.
# guests_height <host>
guests_height() {
  local g host name logo vmid items total=0 n=0
  for g in "${GUESTS[@]}"; do
    IFS='|' read -r host name logo vmid items <<< "$g"
    [[ $host == "$1" ]] || continue
    total=$(( total + $(guest_height "$items") ))
    n=$(( n + 1 ))
  done
  (( n > 1 )) && total=$(( total + (n - 1) * 8 ))
  printf '%s' "$total"
}

# Prints the guests of a host, one below the other.
# guests <x> <y> <width> <host> [empty text]
guests() {
  local g host name logo vmid items y=$2 n=0
  for g in "${GUESTS[@]}"; do
    IFS='|' read -r host name logo vmid items <<< "$g"
    [[ $host == "$4" ]] || continue
    guest "$1" "$y" "$3" "$name" "$logo" "$vmid" "$items"
    y=$(( y + $(guest_height "$items") + 8 ))
    n=$(( n + 1 ))
  done
  if (( n == 0 )) && [[ -n ${5:-} ]]; then
    text "$1" "$(( $2 + 16 ))" "$5" "$c_muted" 12
  fi
}

# The layout of the pantheon nodes: four in a row.
node_cols() { printf '%s' "$(( ${#NODES[@]} < 4 ? ${#NODES[@]} : 4 ))"; }

# Prints the height of a row of nodes.
# node_row_height <first index> <number of columns>
node_row_height() {
  local i h=16
  for (( i = $1; i < $1 + $2 && i < ${#NODES[@]}; i++ )); do
    h=$(max "$h" "$(guests_height "${NODES[$i]%%|*}")")
  done
  printf '%s' "$(( h + 56 + 10 ))"
}

# The layout of the typhon groups: as many columns as fit.
group_cols() {
  local g need=0 n=${#TYPHON_GROUPS[@]} space=$(( width - 4 * pad ))
  for g in "${TYPHON_GROUPS[@]}"; do
    need=$(max "$need" "$(app_width "${g#*|}" 13 18)")
    need=$(max "$need" "$(text_width "${g%%|*}" 11 1)")
  done
  need=$(( need + 24 ))
  printf '%s' "$(( (space / need) < n ? $(max 1 $(( space / need ))) : n ))"
}

# Prints the height of a row of typhon groups.
# group_row_height <first index> <number of columns>
group_row_height() {
  local i h=0
  for (( i = $1; i < $1 + $2 && i < ${#TYPHON_GROUPS[@]}; i++ )); do
    h=$(max "$h" "$(count "${TYPHON_GROUPS[$i]#*|}")")
  done
  printf '%s' "$(( 20 + h * row - 8 ))"
}

# Prints the height of the box of a standalone host.
# standalone_height <host> <width>
standalone_height() {
  local name logo sub items gh ah
  IFS='|' read -r name logo sub items <<< "$1"
  gh=$(guests_height "$name")
  ah=$(app_grid_height "$items" "$(( $2 - 2 * pad ))")
  printf '%s' "$(( head + pad + gh + (gh > 0 && ah > 0 ? 8 : 0) + ah + pad ))"
}

render() {
  local i j x y h name logo sub hw items title cols node_w rows_h last_row
  local typhon_y typhon_h pantheon_h gcols gw total half line_x bw
  local -a row_y

  # The heights come first, because the <svg> tag needs the total height.
  cols=$(node_cols)
  node_w=$(( (width - 2 * pad - (cols - 1) * gap) / cols ))
  y=66
  for (( i = 0; i < ${#NODES[@]}; i += cols )); do
    row_y+=("$y")
    y=$(( y + $(node_row_height "$i" "$cols") + gap ))
  done
  last_row=$(( (${#NODES[@]} - 1) / cols * cols ))
  rows_h=$(( y - gap ))

  gcols=$(group_cols)
  gw=$(( (width - 4 * pad) / gcols ))
  typhon_y=$(( rows_h + 28 ))
  typhon_h=$(( head + pad ))
  for (( i = 0; i < ${#TYPHON_GROUPS[@]}; i += gcols )); do
    (( i > 0 )) && typhon_h=$(( typhon_h + 14 ))
    typhon_h=$(( typhon_h + $(group_row_height "$i" "$gcols") ))
  done
  typhon_h=$(( typhon_h + pad ))
  pantheon_h=$(( typhon_y + typhon_h + pad ))

  half=$(( (width - gap) / 2 ))
  total=$(( pantheon_h ))
  for (( i = 0; i < ${#STANDALONE[@]}; i += 2 )); do
    bw=$(( i + 1 < ${#STANDALONE[@]} ? half : width ))
    h=$(standalone_height "${STANDALONE[$i]}" "$bw")
    (( i + 1 < ${#STANDALONE[@]} )) && h=$(max "$h" "$(standalone_height "${STANDALONE[$i+1]}" "$half")")
    total=$(( total + gap + h ))
  done

  printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img" aria-label="The service map of the homelab">' \
    "$width" "$total" "$width" "$total"

  # The pantheon cluster, with a box for each node.
  box 0 0 "$width" "$pantheon_h" "$c_card" 12
  header 0 0 "$width" pantheon proxmox "Proxmox VE cluster"
  for i in "${!NODES[@]}"; do
    IFS='|' read -r name hw <<< "${NODES[$i]}"
    x=$(( pad + (i % cols) * (node_w + gap) ))
    y=${row_y[$(( i / cols ))]}
    h=$(node_row_height "$(( i / cols * cols ))" "$cols")
    fits "$name" 14 1 "$(( node_w - 48 ))" "the node $name"
    fits "$hw" 11 0 "$(( node_w - 24 ))" "the node $name"
    box "$x" "$y" "$node_w" "$h" "$c_inner" 10
    image "$(( x + 12 ))" "$(( y + 12 ))" 18 proxmox
    text "$(( x + 36 ))" "$(( y + 26 ))" "$name" "$c_node" 14 600
    text "$(( x + 12 ))" "$(( y + 44 ))" "$hw" "$c_muted" 11
    guests "$(( x + 10 ))" "$(( y + 56 ))" "$(( node_w - 20 ))" "$name" "No guests"

    # A dashed line goes from each node of typhon in the last row to the box
    # of typhon. The subtitle of typhon names the nodes in the other rows.
    for j in "${TYPHON_NODES[@]}"; do
      if [[ $name != "$j" ]] || (( i < last_row )); then
        continue
      fi
      line_x=$(( x + node_w / 2 ))
      printf '<line x1="%s.5" y1="%s" x2="%s.5" y2="%s" stroke="%s" stroke-width="1.5" stroke-dasharray="4 4"/>' \
        "$line_x" "$(( y + h ))" "$line_x" "$typhon_y" "$c_muted"
    done
  done

  # The typhon cluster, with its groups of apps.
  IFS='|' read -r name logo sub <<< "$TYPHON"
  box "$pad" "$typhon_y" "$(( width - 2 * pad ))" "$typhon_h" "$c_inner" 10
  header "$pad" "$typhon_y" "$(( width - 2 * pad ))" "$name" "$logo" "$sub"
  y=$(( typhon_y + head + pad ))
  for (( i = 0; i < ${#TYPHON_GROUPS[@]}; i++ )); do
    if (( i > 0 && i % gcols == 0 )); then
      y=$(( y + $(group_row_height "$(( i - gcols ))" "$gcols") + 14 ))
    fi
    IFS='|' read -r title items <<< "${TYPHON_GROUPS[$i]}"
    x=$(( 2 * pad + (i % gcols) * gw ))
    text "$x" "$(( y + 8 ))" "${title^^}" "$c_muted" 11 600
    apps "$x" "$(( y + 20 ))" "$items"
  done

  # The standalone hosts, two in a row. Each box holds its guests, then its
  # apps.
  y=$(( pantheon_h + gap ))
  for (( i = 0; i < ${#STANDALONE[@]}; i += 2 )); do
    bw=$(( i + 1 < ${#STANDALONE[@]} ? half : width ))
    h=$(standalone_height "${STANDALONE[$i]}" "$bw")
    (( i + 1 < ${#STANDALONE[@]} )) && h=$(max "$h" "$(standalone_height "${STANDALONE[$i+1]}" "$half")")
    for (( j = i; j < i + 2 && j < ${#STANDALONE[@]}; j++ )); do
      x=$(( (j - i) * (half + gap) ))
      (( j > i )) && bw=$(( width - x ))
      IFS='|' read -r name logo sub items <<< "${STANDALONE[$j]}"
      box "$x" "$y" "$bw" "$h" "$c_card" 12
      header "$x" "$y" "$bw" "$name" "$logo" "$sub"
      guests "$(( x + pad ))" "$(( y + head + pad ))" "$(( bw - 2 * pad ))" "$name"
      local gh
      gh=$(guests_height "$name")
      app_grid "$(( x + pad ))" "$(( y + head + pad + gh + (gh > 0 ? 8 : 0) ))" "$(( bw - 2 * pad ))" "$items"
    done
    y=$(( y + h + gap ))
  done

  printf '</svg>\n'
}

# Collects each icon name, and checks that dashboard-icons has it.
all_icons() {
  local g host name logo vmid items title app
  local -a list
  printf '%s\n' proxmox
  for g in "${GUESTS[@]}"; do
    IFS='|' read -r host name logo vmid items <<< "$g"
    printf '%s\n' "$logo"
    [[ -n $items ]] || continue
    IFS=, read -ra list <<< "$items"
    for app in "${list[@]}"; do printf '%s\n' "${app#*:}"; done
  done
  for g in "$TYPHON" "${STANDALONE[@]}"; do
    IFS='|' read -r name logo title items <<< "$g"
    printf '%s\n' "$logo"
    [[ -n ${items:-} ]] || continue
    IFS=, read -ra list <<< "$items"
    for app in "${list[@]}"; do printf '%s\n' "${app#*:}"; done
  done
  for g in "${TYPHON_GROUPS[@]}"; do
    IFS=, read -ra list <<< "${g#*|}"
    for app in "${list[@]}"; do printf '%s\n' "${app#*:}"; done
  done
}

mapfile -t icons < <(all_icons | sort -u)
check_icons "${icons[@]}"

mkdir -p "$out"

# Each theme: the icon variant, then the colors of the outer boxes, the inner
# boxes, the guests, the lines, the text, the muted text, and the Proxmox nodes.
# The script writes each file only when the whole map is complete.
for theme in light dark; do
  if [[ $theme == light ]]; then
    variant='' c_card='#f6f8fa' c_inner='#ffffff' c_guest='#f6f8fa' c_line='#d0d7de'
    c_text='#1f2328' c_muted='#59636e' c_node='#c75d00'
  else
    variant='-light' c_card='#161b22' c_inner='#0d1117' c_guest='#161b22' c_line='#30363d'
    c_text='#e6edf3' c_muted='#9198a1' c_node='#ff8a1f'
  fi
  render > "$cache/services-$theme.svg"
done
mv "$cache/services-light.svg" "$cache/services-dark.svg" "$out/"
