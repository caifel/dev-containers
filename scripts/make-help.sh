#!/usr/bin/env bash
set -euo pipefail

MAKEFILE="${MAKEFILE:-Makefile}"
MODE="dev"

targets="$(
  awk -v mode="$MODE" '
    BEGIN { FS = ":.*## " }
    /^# @group / {
      pending_group = $0
      sub(/^# @group /, "", pending_group)
      next
    }

    /^[a-zA-Z0-9_-]+:.*## / && $1 != "help" && $1 != "h" {
      description = $2
      if (description ~ "^\\[" mode "\\] ") {
        if (pending_group != "") {
          print "__GROUP__\t" pending_group
          pending_group = ""
        }
        sub("^\\[" mode "\\] ", "", description)
        printf "%s\t%s\n", $1, description
      }
    }
  ' "$MAKEFILE"
)"

if [ -z "$targets" ]; then
  echo "No $MODE Make targets found in $MAKEFILE."
  exit 1
fi

if [ -t 1 ]; then
  dim="$(printf '\033[2m')"
  yellow="$(printf '\033[33m')"
  blue="$(printf '\033[34m')"
  green="$(printf '\033[32m')"
  white="$(printf '\033[37m')"
  reset="$(printf '\033[0m')"
else
  dim=""
  yellow=""
  blue=""
  green=""
  white=""
  reset=""
fi

target_lines=()
while IFS= read -r line; do
  target_lines+=("$line")
done <<< "$targets"

preview_command() {
  local target="$1"

  awk -v target="$target" '
    $0 ~ "^" target ":[^#]*(##.*)?$" {
      in_target = 1
      next
    }

    in_target && /^\t/ {
      command = $0
      sub(/^\t@?/, "", command)
      print command
      exit
    }

    in_target && /^[^[:space:]].*:/ {
      exit
    }
  ' "$MAKEFILE" |
    sed \
      -e 's/$(COMPOSE)/docker compose/g' \
      -e 's/$(COMPOSE_PROD)/docker compose -f docker-compose.prod.yml/g'
}

highlight_description() {
  local text="$1"

  if [ -z "$blue" ]; then
    printf "%s" "$text"
    return
  fi

  printf "%s" "$text" |
    sed \
      -e "s/\\bworkstation\\b/${blue}workstation${reset}${white}/g" \
      -e "s/\\bws\\b/${blue}ws${reset}${white}/g" \
      -e "s/\\bdev-web\\b/${blue}dev-web${reset}${white}/g" \
      -e "s/\\bdev-api\\b/${blue}dev-api${reset}${white}/g" \
      -e "s/\\bapi-types\\b/${blue}api-types${reset}${white}/g" \
      -e "s/\\bprod-web\\b/${blue}prod-web${reset}${white}/g" \
      -e "s/\\bprod-api\\b/${blue}prod-api${reset}${white}/g" \
      -e "s/\\bSQLite\\b/${blue}SQLite${reset}${white}/g" \
      -e "s/\\bCompose\\b/${blue}Compose${reset}${white}/g"
}

echo "Available $MODE targets:"
for line in "${target_lines[@]}"; do
  target="${line%%$'\t'*}"
  description="${line#*$'\t'}"

  if [ "$target" = "__GROUP__" ]; then
    printf "%s- %s%s\n" "$dim" "$description" "$reset"
    continue
  fi

  command="$(preview_command "$target")"
  highlighted_description="$(highlight_description "$description")"
  printf "    %s%s%s > %s%s%s -> %s%s%s\n" \
    "$yellow" "$target" "$reset" \
    "$white" "$highlighted_description" "$reset" \
    "$green" "$command" "$reset"
done
