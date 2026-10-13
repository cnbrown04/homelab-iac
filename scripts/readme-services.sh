#!/usr/bin/env bash
# Makes the services graphic of README.md.
#
# The graphic shows a card for each host, with its apps. The script writes a
# light and a dark version to .github/assets/. README.md shows the version that
# agrees with the theme of the reader.
#
# Run it from the root of the repository. It needs curl, jq, and rsvg-convert.
# To add an app, add it to HOSTS or TYPHON_GROUPS, then run the script.
set -euo pipefail

out=.github/assets
dashboard=https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons
font='-apple-system,BlinkMacSystemFont,Segoe UI,Noto Sans,Helvetica,Arial,sans-serif'
# An icon larger than this goes into the graphic as a small PNG.
max_svg=6000

# Each host: the name, the logo of its OS, the role, and the apps. A logo is an
# icon of dashboard-icons.
# In a role, "@<node>" shows a Proxmox node with its logo. The role can be empty.
# Each app is "<name>:<icon of dashboard-icons>".
HOSTS=(
  "atlas|proxmox|Standalone PVE node|Home Assistant:home-assistant"
  "hermes|ubuntu-linux|Dedirock VPS|Headscale:headscale,Pangolin:pangolin,Pocket ID:pocket-id,Headplane:headplane,Dockge:dockge"
  "mnemosyne|debian-linux|VM on @gaia|Samba:samba-server,OpenCloud:open-cloud"
  "argus|ubuntu-linux|VM on @tartarus|Wazuh:wazuh"
  "daedalus|ubuntu-linux|VM on @tartarus|Claude Code:claude-ai,opencode:opencode,Neovim:neovim"
)

# The typhon cluster has a wide card, with a column for each group.
TYPHON="typhon|talos|Talos Kubernetes on @gaia and @hyperion"
TYPHON_GROUPS=(
  "Platform|Flux:flux-cd,Glance:glance,Termix:termix"
  "Media|Jellyfin:jellyfin,Audiobookshelf:audiobookshelf,Seerr:seerr"
  "Library|Sonarr:sonarr,Radarr:radarr,Chaptarr:chaptarr"
  "Downloads|Prowlarr:prowlarr,Jackett:jackett,qBittorrent:qbittorrent"
)


gap=12 pad=14 row=26 head=52
card_w=166
width=$(( ${#HOSTS[@]} * card_w + (${#HOSTS[@]} - 1) * gap ))

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

# Prints the path of a cached copy of a URL.
fetch() {
  local file
  file="$cache/$(printf '%s' "$1" | sha1sum | cut -d' ' -f1)"
  [[ -f $file ]] || curl -fsSL "$1" -o "$file"
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

# Prints the icon of an app. On a dark page, dashboard-icons has a "-light"
# icon for some apps. Some of these icons are not valid SVG, so the normal
# icon is the fallback.
app_icon() {
  local name=$1 variant=$2 file
  if [[ -n $variant ]] && jq -e --arg f "$name$variant.svg" '.svg | index($f)' \
      "$(fetch "$dashboard/tree.json")" > /dev/null; then
    file=$(fetch "$dashboard/svg/$name$variant.svg")
    if rsvg-convert "$file" > /dev/null 2>&1; then
      data_uri "$file"
      return
    fi
  fi
  data_uri "$(fetch "$dashboard/svg/$name.svg")"
}

escape() {
  local s=${1//&/&amp;}
  s=${s//</&lt;}
  printf '%s' "${s//>/&gt;}"
}

# text <x> <y> <value> <color> <size> [weight]
text() {
  printf '<text x="%s" y="%s" fill="%s" font-family="%s" font-size="%s" font-weight="%s">%s</text>' \
    "$1" "$2" "$4" "$font" "$5" "${6:-normal}" "$(escape "$3")"
}

# image <x> <y> <size> <href>
image() {
  printf '<image x="%s" y="%s" width="%s" height="%s" href="%s"/>' "$1" "$2" "$3" "$3" "$4"
}

# card <x> <y> <width> <height>
card() {
  printf '<rect x="%s.5" y="%s.5" width="%s" height="%s" rx="10" fill="%s" stroke="%s"/>' \
    "$1" "$2" "$(( $3 - 1 ))" "$4" "$c_card" "$c_line"
}

# Prints the approximate width of a text in pixels. An SVG image cannot
# measure its text, so this estimate puts the Proxmox logos in the subtitles.
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

# Prints a subtitle. Each word "@<node>" becomes the logo of Proxmox and the
# name of the node, in the color of the nodes. The other words stay together
# in one text, so the browser sets their spaces.
# subtitle <x> <y> <role>
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
    image "$x" "$(( $2 - 10 ))" 12 "$(app_icon proxmox "$variant")"
    text "$(( x + 15 ))" "$2" "$node" "$c_node" 12 600
    x=$(( x + 15 + $(text_width "$node" 12 1) + 5 ))
  done
}

# header <x> <y> <name> <logo> <role>
header() {
  image "$(( $1 + pad ))" "$(( $2 + pad ))" 20 "$(app_icon "$4" "$variant")"
  text "$(( $1 + pad + 28 ))" "$(( $2 + pad + 15 ))" "$3" "$c_text" 15 600
  if [[ -n $5 ]]; then
    subtitle "$(( $1 + pad ))" "$(( $2 + pad + 36 ))" "$5"
  fi
}

# apps <x> <y> <list of apps>
apps() {
  local i=0 app top
  local -a list
  IFS=, read -ra list <<< "$3"
  for app in "${list[@]}"; do
    top=$(( $2 + i * row ))
    image "$1" "$top" 18 "$(app_icon "${app#*:}" "$variant")"
    text "$(( $1 + 26 ))" "$(( top + 14 ))" "${app%%:*}" "$c_text" 13
    i=$(( i + 1 ))
  done
}

count() {
  local -a list
  IFS=, read -ra list <<< "$1"
  printf '%s' "${#list[@]}"
}

render() {
  local i x y name logo role items title tallest=0 rows=0 height typhon column total
  for i in "${HOSTS[@]}"; do
    (( $(count "${i##*|}") > tallest )) && tallest=$(count "${i##*|}")
  done
  for i in "${TYPHON_GROUPS[@]}"; do
    (( $(count "${i#*|}") > rows )) && rows=$(count "${i#*|}")
  done
  height=$(( head + pad + tallest * row + pad - 8 ))
  y=$(( height + gap ))
  typhon=$(( head + pad + 20 + rows * row + pad - 8 ))
  total=$(( y + typhon + 1 ))
  printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img" aria-label="The services of the homelab">' \
    "$width" "$total" "$width" "$total"

  for i in "${!HOSTS[@]}"; do
    IFS='|' read -r name logo role items <<< "${HOSTS[$i]}"
    x=$(( i * (card_w + gap) ))
    card "$x" 0 "$card_w" "$height"
    header "$x" 0 "$name" "$logo" "$role"
    apps "$(( x + pad ))" "$(( head + pad ))" "$items"
  done

  IFS='|' read -r name logo role <<< "$TYPHON"
  card 0 "$y" "$width" "$typhon"
  header 0 "$y" "$name" "$logo" "$role"
  column=$(( (width - 2 * pad) / ${#TYPHON_GROUPS[@]} ))
  for i in "${!TYPHON_GROUPS[@]}"; do
    IFS='|' read -r title items <<< "${TYPHON_GROUPS[$i]}"
    x=$(( pad + i * column ))
    text "$x" "$(( y + head + pad + 8 ))" "${title^^}" "$c_muted" 11 600
    apps "$x" "$(( y + head + pad + 20 ))" "$items"
  done
  printf '</svg>\n'
}

mkdir -p "$out"

# Each theme: the icon variant, then the colors of the card, the line, the
# text, the muted text, and the Proxmox nodes.
for theme in light dark; do
  if [[ $theme == light ]]; then
    variant='' c_card='#f6f8fa' c_line='#d0d7de' c_text='#1f2328' c_muted='#59636e' c_node='#c75d00'
  else
    variant='-light' c_card='#161b22' c_line='#30363d' c_text='#e6edf3' c_muted='#9198a1' c_node='#ff8a1f'
  fi
  render > "$out/services-$theme.svg"
done
