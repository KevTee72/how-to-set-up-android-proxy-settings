#!/usr/bin/env bash
# Test a proxy endpoint from your computer before typing it into a phone.
# Replace USERNAME and PASSWORD with the values from your provider dashboard.
# If these work and the phone does not, the problem is on the device side.

# Your own IP, no proxy, for comparison
curl https://api.ipify.org; echo

# HTTP proxy with credentials (rotating residential gateway, US)
curl -x http://proxy-us.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org; echo

# EU gateway
curl -x http://proxy-eu.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org; echo

# SOCKS5, hostname resolved by your machine
curl --socks5 proxy-us.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org; echo

# SOCKS5, hostname resolved by the proxy (the "remote DNS" option in routing apps)
curl --socks5-hostname proxy-us.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org; echo

# Static plan with IP authorization: no credentials, use the dedicated
# IP and port shown next to the proxy in the dashboard
curl -x http://203.0.113.10:8080 https://api.ipify.org; echo
