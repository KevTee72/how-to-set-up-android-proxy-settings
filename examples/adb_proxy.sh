#!/usr/bin/env bash
# Android proxy settings over ADB: set, show, clear, or purge the global
# HTTP proxy on a connected device or emulator.
#
#   ./adb_proxy.sh set 203.0.113.10:8080
#   ./adb_proxy.sh show
#   ./adb_proxy.sh clear
#   ./adb_proxy.sh purge
#
# Target one device when several are attached:
#   ANDROID_SERIAL=emulator-5554 ./adb_proxy.sh show
#
# The global proxy takes host:port only. It cannot store a username or
# password, so point it at a proxy that authorizes your IP address, or at
# a local forwarding proxy that adds the credentials.

set -euo pipefail

usage() {
  echo "usage: $0 set HOST:PORT | show | clear | purge" >&2
  exit 2
}

command -v adb >/dev/null 2>&1 || { echo "adb not found on PATH" >&2; exit 1; }

cmd="${1:-}"

case "$cmd" in
  set)
    target="${2:-}"
    if ! [[ "$target" =~ ^[A-Za-z0-9._-]+:[0-9]{1,5}$ ]]; then
      echo "expected HOST:PORT, got '${target}'" >&2
      exit 2
    fi
    adb shell settings put global http_proxy "$target"
    echo "global http_proxy set to $(adb shell settings get global http_proxy | tr -d '\r')"
    ;;
  show)
    adb shell settings get global http_proxy | tr -d '\r'
    ;;
  clear)
    # Takes effect right away, no reboot needed.
    adb shell settings put global http_proxy :0
    echo "global http_proxy cleared"
    ;;
  purge)
    # Removes the setting and the keys Android derives from it.
    adb shell settings delete global http_proxy
    adb shell settings delete global global_http_proxy_host
    adb shell settings delete global global_http_proxy_port
    adb shell settings delete global global_http_proxy_exclusion_list
    echo "proxy keys deleted, reboot the device to finish: adb reboot"
    ;;
  *)
    usage
    ;;
esac
