// Sample PAC file for the "Proxy Auto-Config" mode in Android WiFi settings.
// Host it at a URL the phone can reach (plain HTTP on your local network
// is fine) and paste that URL into the PAC field.
//
// Android calls FindProxyForURL for each request and uses the returned
// proxy. Replace 203.0.113.10:8080 with your own proxy host and port.

function FindProxyForURL(url, host) {
  // Local names and private ranges connect directly.
  if (isPlainHostName(host) ||
      host === "localhost" ||
      isInNet(host, "10.0.0.0", "255.0.0.0") ||
      isInNet(host, "172.16.0.0", "255.240.0.0") ||
      isInNet(host, "192.168.0.0", "255.255.0.0")) {
    return "DIRECT";
  }

  // Send only the hosts you are testing through the proxy.
  if (dnsDomainIs(host, ".example.com") || host === "example.com") {
    return "PROXY 203.0.113.10:8080";
  }

  // Everything else connects directly. Swap this line for the PROXY
  // line above to send all remaining traffic through the proxy.
  return "DIRECT";
}
