#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
usage: smoke-test.sh [--api-url URL]

Runs a quick smoke test against the API to verify the stack is healthy.

Checks:
  1. API root endpoint (metadata)
  2. Database connectivity (/health)
  3. Swagger JSON (/swagger/json)
  4. Authentication (login, session cookie, /auth/me)
  5. CSRF token flow (GET /auth/csrf-token)

Exit code 0 on success, 1 on any failure.
EOF
}

api_url="http://localhost:4000"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --api-url)
      api_url="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown flag: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

COOKIE_JAR="$(mktemp /tmp/smoke-cookies.XXXXXX)"
CSRF_TOKEN=""
PASS=0
FAIL=0

check() {
  local label="$1"
  local status="$2"
  local detail="${3:-}"

  if [ "$status" -ge 200 ] && [ "$status" -lt 300 ]; then
    PASS=$((PASS + 1))
    printf '  ✓ %s (HTTP %s)\n' "$label" "$status"
  else
    FAIL=$((FAIL + 1))
    printf '  ✗ %s (HTTP %s)\n' "$label" "$status"
    if [ -n "$detail" ]; then
      printf '    %s\n' "$detail" | head -5
    fi
  fi
}

http_get() {
  local path="$1"
  local extra_args="${2:-}"
  # shellcheck disable=SC2086
  curl -s -o /dev/null -w "%{http_code}" -b "$COOKIE_JAR" -c "$COOKIE_JAR" $extra_args "$api_url$path"
}

http_get_body() {
  local path="$1"
  local extra_args="${2:-}"
  # shellcheck disable=SC2086
  curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" $extra_args "$api_url$path"
}

printf '\nSmoke-testing API at %s...\n\n' "$api_url"

# 1. Root
check "GET /" "$(http_get "/")"

# 2. Health (DB connectivity)
status=$(http_get "/health")
body=$(http_get_body "/health")
check "GET /health" "$status" "$body"

# 3. Swagger JSON
check "GET /swagger/json" "$(http_get "/swagger/json")"

# 4. Login
status=$(http_get "/auth/login" "-X POST -H 'Content-Type: application/json' -d '{\"email\":\"admin@ajedrezlapaz.com\",\"password\":\"admin123\"}'")
check "POST /auth/login" "$status"

# 5. Get current user (requires session cookie from login)
body=$(http_get_body "/auth/me")
status=$(http_get "/auth/me")
if [ "$status" = "200" ]; then
  user_name=$(printf '%s' "$body" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
  check "GET /auth/me" "$status" "user=$user_name"
else
  check "GET /auth/me" "$status" "$body"
fi

# 6. CSRF token
csrf_body=$(http_get_body "/auth/csrf-token")
status=$(http_get "/auth/csrf-token")
if [ "$status" = "200" ]; then
  CSRF_TOKEN=$(printf '%s' "$csrf_body" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
  if [ -n "$CSRF_TOKEN" ]; then
    PASS=$((PASS + 1))
    printf '  ✓ GET /auth/csrf-token (token received)\n'
  else
    FAIL=$((FAIL + 1))
    printf '  ✗ GET /auth/csrf-token (no token in response)\n'
  fi
else
  check "GET /auth/csrf-token" "$status"
fi

# 7. Logout
check "POST /auth/logout" "$(http_get "/auth/logout" "-X POST -H 'Content-Type: application/json'")"

rm -f "$COOKIE_JAR"

printf '\n═══════════════════════════════════════\n'
printf '  Smoke test results: %s pass, %s fail\n' "$PASS" "$FAIL"
printf '═══════════════════════════════════════\n\n'

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
