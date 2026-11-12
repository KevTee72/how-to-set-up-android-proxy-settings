"""
Check an HTTP proxy from your computer before entering it on an Android
device. Standard library only, no installs.

    python check_proxy.py HOST:PORT
    python check_proxy.py HOST:PORT USERNAME PASSWORD

Prints your direct IP, then the IP seen through the proxy. If the two
differ, the endpoint works and any later failure is on the device side.

This script tests HTTP proxies. For SOCKS5, use the curl commands in
curl_examples.sh.
"""

import sys
import urllib.error
import urllib.request

IP_URL = "https://api.ipify.org"
TIMEOUT = 15

HINTS = {
    407: "the proxy wants credentials, or the ones given are wrong",
    403: "the proxy refused the request, check that your IP is authorized",
    502: "the proxy could not reach the target, try again or try another exit",
    503: "the proxy is overloaded or down",
}


def fetch_ip(proxy_url=None):
    handlers = []
    if proxy_url:
        handlers.append(
            urllib.request.ProxyHandler({"http": proxy_url, "https": proxy_url})
        )
    else:
        handlers.append(urllib.request.ProxyHandler({}))
    opener = urllib.request.build_opener(*handlers)
    with opener.open(IP_URL, timeout=TIMEOUT) as resp:
        return resp.read().decode().strip()


def main(argv):
    if len(argv) not in (2, 4):
        print(__doc__)
        return 2

    endpoint = argv[1]
    if len(argv) == 4:
        proxy_url = f"http://{argv[2]}:{argv[3]}@{endpoint}"
    else:
        proxy_url = f"http://{endpoint}"

    try:
        direct = fetch_ip()
        print("Direct IP: ", direct)
    except OSError as exc:
        print("Could not reach the IP service without a proxy:", exc)
        return 1

    try:
        proxied = fetch_ip(proxy_url)
    except urllib.error.HTTPError as exc:
        print(f"Proxy answered with HTTP {exc.code}:", HINTS.get(exc.code, exc.reason))
        return 1
    except OSError as exc:
        text = str(exc)
        for code, hint in HINTS.items():
            if str(code) in text:
                print(f"Proxy answered with {code}:", hint)
                return 1
        print("Proxy connection failed (wrong host or port, or the proxy is down):", exc)
        return 1

    print("Proxied IP:", proxied)
    if proxied == direct:
        print("Both IPs match, so traffic is not going through the proxy.")
        return 1
    print("The endpoint works. Enter the same host and port on the device.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
