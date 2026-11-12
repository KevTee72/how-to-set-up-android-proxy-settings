# How to Set Up Android Proxy Settings

<p align="center">
  <a href="https://www.proxy-cheap.com/">
  </a>
</p>

Most guides to [Android proxy settings](https://www.proxy-cheap.com/blog/how-to-set-up-android-proxy-settings) show the WiFi form and stop there. That form covers one case: an HTTP proxy with no password, on one network. An Android proxy can sit in five different places on the device, and each place accepts a different mix of protocols and credentials. Picking the wrong one is why a setup that looks correct still sends app traffic straight out.

This repo is organized around that choice. The capability matrix comes first, then the exact steps for each of the five places, then SOCKS5, free proxy lists, verification, and fixes. Commands and scripts live in [examples/](examples/). Proxy-Cheap is used as the reference provider because its dashboard hands you the four values every method needs (host, port, protocol, and a username with a password), and the steps work the same with any provider that gives you those.

## Table of contents

- [Where a proxy on Android can live](#where-a-proxy-on-android-can-live)
- [Capability matrix](#capability-matrix)
- [Before you touch the phone](#before-you-touch-the-phone)
- [WiFi proxy settings](#wifi-proxy-settings)
- [APN proxy for mobile data](#apn-proxy-for-mobile-data)
- [Per app routing through a local VPN](#per-app-routing-through-a-local-vpn)
- [Android emulator proxy](#android-emulator-proxy)
- [Global proxy over ADB](#global-proxy-over-adb)
- [Android SOCKS5 proxy setup](#android-socks5-proxy-setup)
- [Free proxy server list for Android: what to expect](#free-proxy-server-list-for-android-what-to-expect)
- [Verify that traffic uses the proxy](#verify-that-traffic-uses-the-proxy)
- [Fixes for common failures](#fixes-for-common-failures)
- [Which proxy type fits which Android job](#which-proxy-type-fits-which-android-job)
- [FAQ](#faq)

---

## Where a proxy on Android can live

| Place | What it covers | How you reach it |
|---|---|---|
| WiFi network entry | One saved WiFi network | Settings app |
| APN | Mobile data on one access point | Settings app, SIM section |
| Local VPN routing app | The apps you select, on any network | An app you install |
| Emulator launch flag | Every TCP connection leaving a virtual device | Command line or emulator settings |
| Global HTTP proxy | The whole device, every network | ADB only, no screen for it |

The first two are per network, which means the setting stays behind when the phone moves from WiFi to mobile data. The last three follow the device.

One rule applies to all five. Android offers the proxy to apps, and each app decides whether to use it. Chrome, WebView, and apps built on OkHttp or HttpURLConnection normally do. Apps that ship their own network stack often do not, and that is the usual explanation for "the browser shows the proxy IP but my app does not".

## Capability matrix

This is the table to read before choosing a method.

| Method | HTTP and HTTPS | SOCKS5 | Username and password | Needs root | Survives a network change |
|---|---|---|---|---|---|
| WiFi settings | Yes | No | No fields for them | No | No |
| APN | Yes | No | Not for the proxy (see below) | No | No |
| Local VPN routing app | Yes | Yes | Yes | No | Yes |
| Emulator `-http-proxy` | Yes | No | Yes, in the URL | No | Yes |
| ADB global proxy | Yes | No | No | No | Yes |

Reading it top to bottom gives you three practical conclusions:

1. Paid proxies with credentials do not fit the WiFi form. Either authorize your IP address in the provider dashboard so no credentials are needed, or use a routing app.
2. SOCKS5 has exactly one home on a physical device, the routing app.
3. For test automation, ADB and the emulator flag are the only methods that do not involve tapping through screens.

## Before you touch the phone

Collect four things: the proxy host, the port, the protocol, and how you authenticate (credentials or an authorized IP).

Then test the endpoint from your computer. A typo is far quicker to catch in a terminal than in a phone form that gives no error message at all.

```bash
curl -x http://proxy-us.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org
```

`proxy-us.proxy-cheap.com:5959` is the US gateway for Proxy-Cheap rotating residential plans. Static plans use the dedicated IP and port shown next to each proxy in the dashboard. If the command prints an IP that is not your own, the endpoint works and anything that fails later is a device side problem. [examples/check_proxy.py](examples/check_proxy.py) runs the same test and explains the common error codes.

On a work phone enrolled in device management, ask the administrator first. Managed WiFi profiles can push their own proxy and overwrite yours.

## WiFi proxy settings

Menu names below are from stock Android on a Pixel.

1. Open **Settings**, then **Network & internet**, then **Internet**. On Android 10 and 11 the third entry is named for WiFi instead of **Internet**.
2. Tap the gear icon next to the network you are connected to.
3. Tap the pencil icon at the top right, then expand **Advanced options**.
4. Open the **Proxy** dropdown and choose **Manual**.
5. Enter the host in **Proxy hostname** and the port in **Proxy port**.
6. Optional: list hosts that should connect directly in the exclusion field, separated by commas. `localhost,10.0.2.2` is a typical value for local development.
7. Tap **Save**.

On Samsung phones the path begins at **Settings**, then **Connections**. The field names inside the form are the same.

The dropdown has a second mode, `Proxy Auto-Config`, which takes the URL of a PAC file instead of a host and port. A PAC file is a short JavaScript function that picks a proxy per request, so one URL can send some hosts through the proxy and others direct. A working sample is in [examples/proxy.pac](examples/proxy.pac).

Three limits to know:

- The setting belongs to that saved network. Forget the network, or set **Proxy** back to **None**, and it is gone.
- There is nowhere to type a username or password. Chrome will show a sign in prompt when the proxy asks for credentials. Most native apps will not, and their requests fail with a 407.
- The form accepts HTTP proxies only.

The clean way around the credential limit is IP authorization. Proxy-Cheap supports it on static plans, including [static residential proxies](https://www.proxy-cheap.com/services/static-residential-proxies): add the public IP of your WiFi connection in the dashboard and the proxy stops asking for a password. Rotating residential plans authenticate by username and password only, so pair those with a routing app.

## APN proxy for mobile data

1. Open **Settings**, then **Network & internet**, then **SIMs**, and tap the active SIM.
2. Tap **Access Point Names**.
3. Open the three dot menu, choose **New APN**, and copy every field from the current APN into it. Editing a copy keeps the original intact if something goes wrong.
4. Fill in **Proxy** and **Port**.
5. Save from the three dot menu, select the new APN, then switch mobile data off and on.

Many guides tell you to put proxy credentials in the APN **Username** and **Password** fields. Those fields, along with **Authentication type** (PAP or CHAP), sign the phone in to the carrier's access point. They are not sent to the HTTP proxy. Treat an APN proxy as a method without proxy credentials.

That creates a second problem. A phone on mobile data usually shares its public IP with other subscribers through carrier grade NAT, and the IP changes as the phone moves, so IP authorization is unreliable there too. Add the fact that some carriers lock APN editing or ignore the proxy fields, and the APN method ends up useful mainly on private or lab SIMs. For normal mobile data, use a routing app.

## Per app routing through a local VPN

Routing apps register themselves as a VPN on the device, catch the traffic of the apps you choose, and forward it to your proxy. No root is needed, and this is the only method that handles credentials and SOCKS5 on a physical phone.

Apps in this category include Drony, Postern, SocksDroid, v2rayNG, and NekoBox. ProxyDroid does the same job with iptables rules instead of a VPN, which requires root. The setup is the same shape in all of them:

1. Create a profile with the host, port, protocol, username, and password.
2. Select which apps the profile applies to.
3. Connect and accept the VPN permission dialog. A key icon in the status bar confirms it is active.

The tradeoff is trust. The routing app sees everything it forwards, so prefer open source projects with recent releases, and check that the store listing is still maintained before installing.

## Android emulator proxy

An Android Studio virtual device has two separate proxy settings, and they do different jobs.

The launch flag works below Android, so it catches every TCP connection, including apps that ignore system settings:

```bash
emulator -avd Pixel_8_API_34 -http-proxy http://USERNAME:PASSWORD@proxy-us.proxy-cheap.com:5959
```

The same values can be entered in the emulator window: open the three dot button on the toolbar, then **Settings**, then **Proxy**.

Two limits come with it. HTTPS passes through as an opaque tunnel, so you cannot read request contents at this layer. UDP is not redirected at all, so turn off QUIC and DNS over HTTPS in the app under test. Google documents the flag in the [emulator networking guide](https://developer.android.com/studio/run/emulator-networking).

The second setting is the ordinary WiFi form inside the virtual device, set exactly as on a phone. Use that one when you want to inspect traffic with a debugging proxy such as mitmproxy, Charles, or Proxyman on your workstation.

Emulator fleets in CI open a lot of connections and rarely need a residential identity, which makes [datacenter proxies](https://www.proxy-cheap.com/services/datacenter-proxies) the usual match on cost.

## Global proxy over ADB

This is a system setting with no screen in the Settings app. It applies on every network and it is one line to set:

```bash
adb shell settings put global http_proxy 203.0.113.10:8080
adb shell settings get global http_proxy
adb shell settings put global http_proxy :0
```

The first line sets the proxy, the second reads it back, and the third clears it without a reboot. [examples/adb_proxy.sh](examples/adb_proxy.sh) wraps these in `set`, `show`, `clear`, and `purge` commands, where `purge` also deletes the leftover host and port keys.

No supported ADB command stores proxy credentials. In CI the workable patterns are a proxy that authorizes the build runner's IP, or a small forwarding proxy on the runner that adds credentials and exposes a plain endpoint to the device. Whichever you choose, clear the setting at the end of every job. A device that returns to the pool still pointing at a proxy is a slow bug to track down.

## Android SOCKS5 proxy setup

Android has no native SOCKS5 support in its settings. The WiFi form and the APN fields both speak HTTP. An Android SOCKS5 proxy therefore needs one of two things:

- A routing app from the section above with the profile protocol set to SOCKS5. This is the general answer and it covers every app you select.
- An app with its own proxy settings. Telegram, for example, lets you enter a SOCKS5 server that applies inside that app only.

SOCKS5 is worth the extra step when the traffic is not plain web traffic, because it carries any TCP connection and can carry UDP. Proxy-Cheap offers [SOCKS5 proxies](https://www.proxy-cheap.com/services/socks5-proxies) alongside HTTP, and the dashboard shows the protocol each proxy is set to. In a routing app profile, choose the matching protocol in the dropdown and enter the same host, port, and credentials.

One detail decides whether DNS lookups also go through the proxy. In a routing app, enable remote DNS so the proxy resolves hostnames. From a terminal, the same distinction is `--socks5` (your machine resolves) against `--socks5-hostname` (the proxy resolves):

```bash
curl --socks5-hostname proxy-us.proxy-cheap.com:5959 -U USERNAME:PASSWORD https://api.ipify.org
```

## Free proxy server list for Android: what to expect

People search for a free proxy server list for Android for a reason that the capability matrix makes obvious. Open proxies need no password, so they are the only kind that drops straight into the WiFi form. The convenience is real. The cost shows up elsewhere:

- **Lifespan.** Open proxies on public lists are frequently dead within hours, so a list goes stale faster than you can type entries into a phone.
- **Visibility.** The operator is unknown and can read any request that is not encrypted, and can log the hostnames of the ones that are.
- **Certificates.** Some ask you to install a certificate. Never do that for a proxy you do not control, because it lets the operator read HTTPS traffic as well.
- **Shared reputation.** Thousands of people use the same address, so sites that score IP reputation tend to answer with CAPTCHAs or errors.

A free endpoint is acceptable for one thing: checking that the settings form works on your device, with a browser, signed in to nothing. Run the address through [examples/check_proxy.py](examples/check_proxy.py) first so you do not spend ten minutes debugging a phone when the proxy itself was down.

For anything that involves an account, a test suite, or other people's data, a paid endpoint on pay as you go billing is the cheaper option once you count the time. That is also the reason this repo does not publish a proxy list of its own. It would be out of date before the commit landed.

## Verify that traffic uses the proxy

Check in this order, because each step isolates a different layer:

1. **Browser.** Open `https://api.ipify.org` in Chrome on the device. The IP shown should be the proxy's address.
2. **DNS.** Run the extended test on `dnsleaktest.com`. Resolvers that belong to your own internet provider mean lookups are leaving outside the proxy.
3. **The app itself.** Trigger a request in the app you care about and confirm it in your debugging proxy's log, or in the provider's usage stats.

If step 1 passes and step 3 fails, the configuration is correct and that app is ignoring the system proxy. Move it to a routing app or the emulator flag.

## Fixes for common failures

| Symptom | Likely cause | Fix |
|---|---|---|
| Browser uses the proxy, an app does not | The app has its own network stack, or uses QUIC | Routing app, or the emulator launch flag |
| 407 Proxy Authentication Required | The proxy wants credentials the method cannot send | Authorize your IP in the dashboard, or switch to a routing app |
| `ERR_TUNNEL_CONNECTION_FAILED` in Chrome | Wrong host or port, or your IP is not authorized | Repeat the curl test from your computer |
| TLS errors while inspecting traffic | Apps targeting Android 7.0 and later do not trust user installed certificates | Add a debug only trust rule, see [examples/network_security_config.xml](examples/network_security_config.xml) |
| Proxy gone after reconnecting | The WiFi setting is tied to one saved network | Set it again, or use the ADB global proxy |
| IP authorization fails on mobile data | Carrier grade NAT and changing addresses | Username and password through a routing app |

Apps with certificate pinning reject any inspecting proxy no matter how the certificate is installed. For your own app, turn pinning off in debug builds. Google's [network security configuration reference](https://developer.android.com/privacy-and-security/security-config) covers both the trust rule and pinning.

## Which proxy type fits which Android job

| Job | First choice | Why |
|---|---|---|
| App QA on real devices | [Mobile proxies](https://www.proxy-cheap.com/services/mobile-proxies) | Carrier IPs match what production users of a mobile app have |
| App QA on emulators and CI fleets | Datacenter | High throughput at the lowest cost per IP |
| Checking how mobile ads render per country | [Rotating residential proxies](https://www.proxy-cheap.com/services/rotating-residential-proxies) | Wide country coverage with a fresh IP per request |
| Long sessions and packet inspection during development | [ISP proxies](https://www.proxy-cheap.com/services/isp-proxies) | One fixed IP for the whole session |
| Privacy on a personal phone | SOCKS5 through a routing app | Covers every selected app, credentials included |

Two habits hold across all of these. On mobile data, authenticate with a username and password. For sessions that stay signed in, use a static IP, because a rotation in the middle of a session tends to trigger a fresh sign in check.

## FAQ

### Does Android support SOCKS5 without extra apps?

No. The WiFi and APN settings accept HTTP proxies only. SOCKS5 needs a routing app, or an app such as Telegram that has its own proxy settings.

### Can I set an Android proxy without root?

Yes. The WiFi form, APN fields, routing apps, the emulator flag, and ADB all work on an unrooted device. Root is only needed for ProxyDroid and for installing a certificate into the system store.

### How do I turn the proxy off?

On WiFi, set **Proxy** to **None** in the network's advanced options. On mobile data, switch back to the original APN. Over ADB, run `adb shell settings put global http_proxy :0`. In a routing app, disconnect the VPN.

### Why does my phone forget the proxy?

The WiFi setting is saved per network. Joining a different network, or forgetting and joining the same one again, starts with no proxy. The ADB global setting and routing apps do not have this behavior.

### Does a proxy on Android cover every app?

No. It covers apps that read the system proxy. Routing apps and the emulator launch flag work at a lower level and catch apps that skip the system setting.

### Is a proxy the same as a VPN on Android?

No. A VPN tunnels all device traffic at the network layer. A proxy forwards the connections of apps that agree to use it. Routing apps combine the two by using Android's VPN interface to hand selected apps to a proxy.

### Is it legal to use a proxy on Android?

Using a proxy for your own traffic, your own apps, and publicly available content is generally lawful. What you do through it still has to follow the law and each site's terms. Proxy-Cheap covers the topic in more depth in its article on [whether proxies are legal](https://www.proxy-cheap.com/blog/are-proxies-legal). This is not legal advice.

## License

MIT

---

*This is a personal documentation repo, not an official Proxy-Cheap or Android project. Menu names vary between manufacturers and Android versions, so confirm them on your own device. Steps and scripts use standard Android and proxy configuration and work with any provider that gives you a host, a port, and credentials. Verify gateway addresses and product availability on the live product page before relying on them.*
