#!/usr/bin/env bash
# Launch an Android Studio virtual device with every TCP connection sent
# through an HTTP proxy.
#
#   PROXY_USER=USERNAME PROXY_PASS=PASSWORD ./emulator_proxy.sh Pixel_8_API_34
#
# Optional: PROXY_HOST and PROXY_PORT (defaults below). Leave PROXY_USER
# unset for a proxy that authorizes your IP address.
#
# List the virtual devices you have with: emulator -list-avds
#
# Limits of this flag: HTTPS passes through as an opaque tunnel, and UDP
# is not redirected, so turn off QUIC and DNS over HTTPS in the app
# under test.

set -euo pipefail

avd="${1:-}"
if [ -z "$avd" ]; then
  echo "usage: $0 AVD_NAME" >&2
  exit 2
fi

command -v emulator >/dev/null 2>&1 || { echo "emulator not found on PATH" >&2; exit 1; }

host="${PROXY_HOST:-proxy-us.proxy-cheap.com}"
port="${PROXY_PORT:-5959}"

if [ -n "${PROXY_USER:-}" ]; then
  proxy="http://${PROXY_USER}:${PROXY_PASS:-}@${host}:${port}"
else
  proxy="http://${host}:${port}"
fi

exec emulator -avd "$avd" -http-proxy "$proxy"
