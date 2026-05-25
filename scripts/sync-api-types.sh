#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
usage: sync-api-types.sh [--check]

Refresh the API-backed web types from the dev API Swagger schema.

From the host, the script starts dev-api and dev-web if they are not
already running, waits for dev-api Swagger through the Docker network,
then generates or checks web/src/lib/api/generated/schema.ts.

From inside ws, where Docker CLI is not available, it expects dev-api
to already be running and generates directly into /alp/web.

  --check  Verify generated types are up to date without overwriting.
EOF
}

check_only=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      check_only=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

script_dir="$(cd "$(dirname "$0")" && pwd)"
ops_dir="$(cd "$script_dir/.." && pwd)"
schema_url="http://dev-api:4000/swagger/json"
web_dir="${WEB_DIR:-/alp/web}"

cd "$ops_dir"

if [ "$check_only" = true ]; then
  mode="check"
else
  mode="write"
fi

generate_from_current_container() {
  cd "$web_dir"

  bun install

  spec=/tmp/ajedrezlapaz-openapi.json
  generated=/tmp/ajedrezlapaz-schema.ts
  out="$web_dir/src/lib/api/generated/schema.ts"

  SPEC_URL="$schema_url" SPEC_OUT="$spec" bun -e '
const url = process.env.SPEC_URL;
const out = process.env.SPEC_OUT;
console.log("Fetching " + url + " ...");
const response = await fetch(url);
if (!response.ok) {
  console.error("Failed to fetch spec: " + response.status + " " + response.statusText);
  process.exit(1);
}
await Bun.write(out, await response.text());
'

  {
    printf '%s\n' '// Auto-generated from /swagger/json. Do not edit.'
    printf '%s\n' "// Source: $schema_url"
    printf '%s\n' "// Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '\n\n'
    bun run openapi-typescript "$spec"
  } > "$generated"

  if [ "$mode" = check ]; then
    if [ ! -f "$out" ]; then
      printf '%s\n' 'Generated types file does not exist. Run make api-types first.' >&2
      exit 1
    fi

    current_norm=/tmp/ajedrezlapaz-schema-current-normalized.ts
    generated_norm=/tmp/ajedrezlapaz-schema-generated-normalized.ts
    sed 's/^\/\/ Generated: .*$/\/\/ Generated: <timestamp>/' "$out" > "$current_norm"
    sed 's/^\/\/ Generated: .*$/\/\/ Generated: <timestamp>/' "$generated" > "$generated_norm"

    if cmp -s "$current_norm" "$generated_norm"; then
      printf '%s\n' 'Types are up to date.'
      exit 0
    fi

    printf '%s\n' 'Types are stale. Run make api-types to regenerate.' >&2
    exit 1
  fi

  mv "$generated" "$out"
  printf 'Types written to %s\n' "$out"
}

if ! command -v docker >/dev/null 2>&1; then
  printf '%s\n' 'Docker CLI not found; generating from the current container.'
  printf '%s\n' 'This expects dev-api to already be running on the Docker network.'
  generate_from_current_container
  exit 0
fi

docker compose up -d dev-api dev-web

docker compose exec -T dev-web sh -lc '
set -eu

schema_url="http://dev-api:4000/swagger/json"
attempts="${WAIT_FOR_HTTP_ATTEMPTS:-60}"
delay="${WAIT_FOR_HTTP_DELAY:-1}"
i=1

while [ "$i" -le "$attempts" ]; do
  if URL="$schema_url" bun -e "const r = await fetch(process.env.URL); process.exit(r.ok ? 0 : 1)" >/dev/null 2>&1; then
    printf "dev-api Swagger is reachable: %s\n" "$schema_url"
    exit 0
  fi

  sleep "$delay"
  i=$((i + 1))
done

printf "Timed out waiting for dev-api Swagger: %s\n" "$schema_url" >&2
exit 1
'

docker compose exec -T dev-web sh -lc "
set -eu

bun install

spec=/tmp/ajedrezlapaz-openapi.json
generated=/tmp/ajedrezlapaz-schema.ts
out=/alp/web/src/lib/api/generated/schema.ts
schema_url='$schema_url'
mode='$mode'

SPEC_URL=\$schema_url SPEC_OUT=\$spec bun -e '
const url = process.env.SPEC_URL;
const out = process.env.SPEC_OUT;
console.log(\"Fetching \" + url + \" ...\");
const response = await fetch(url);
if (!response.ok) {
  console.error(\"Failed to fetch spec: \" + response.status + \" \" + response.statusText);
  process.exit(1);
}
await Bun.write(out, await response.text());
' 

{
  printf '%s\n' '// Auto-generated from /swagger/json. Do not edit.'
  printf '%s\n' \"// Source: \$schema_url\"
  printf '%s\n' \"// Generated: \$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  printf '\n\n'
  bun run openapi-typescript \"\$spec\"
} > \"\$generated\"

if [ \"\$mode\" = check ]; then
  if [ ! -f \"\$out\" ]; then
    printf '%s\n' 'Generated types file does not exist. Run make api-types first.' >&2
    exit 1
  fi

  current_norm=/tmp/ajedrezlapaz-schema-current-normalized.ts
  generated_norm=/tmp/ajedrezlapaz-schema-generated-normalized.ts
  sed 's/^\/\/ Generated: .*$/\/\/ Generated: <timestamp>/' \"\$out\" > \"\$current_norm\"
  sed 's/^\/\/ Generated: .*$/\/\/ Generated: <timestamp>/' \"\$generated\" > \"\$generated_norm\"

  if cmp -s \"\$current_norm\" \"\$generated_norm\"; then
    printf '%s\n' 'Types are up to date.'
    exit 0
  fi

  printf '%s\n' 'Types are stale. Run make api-types to regenerate.' >&2
  exit 1
fi

mv \"\$generated\" \"\$out\"
printf 'Types written to %s\n' \"\$out\"
"
