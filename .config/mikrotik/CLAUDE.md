tell me to run ssh commands

## MikroTik Setup (RB750Gr3, RouterOS 7.18.2)

- **ether1** = WAN1 (DHCP, global internet — carries WireGuard tunnel)
- **ether5** = WAN2 (DHCP, Iran ISP — Iran traffic via policy routing)
- **wg0** = WireGuard tunnel to VPN server (10.66.66.2 → 206.189.122.139:56758)
- **bridge (ether2-4)** = LAN (192.168.88.0/24)
- Iran IPs: `NoNAT` address-list (~1923 CIDRs) from [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran) (RIPE data, auto-updated daily at 03:00 via RouterOS scheduler script `update-nonat`)
- **Traffic flow:**
  - Iran destinations → ether5 directly (two-step mangle: `mark-connection iran-conn` + `mark-routing to-iran` with `in-interface-list=LAN`, matches `dst-address-list=NoNAT`)
  - All other traffic → wg0 tunnel (default route, distance 1) → ether1 → VPN server
  - WG endpoint (206.189.122.139) → ether1 directly (host route, loop prevention)
  - ether1 DHCP default route at distance 2 (fallback if WG is down/disabled)
- **FastTrack:** `connection-mark=no-mark` — excludes Iran-marked connections (FastTrack bypasses mangle, breaking policy routing)
- DNS forced to router (port 53 redirect) on LAN; router DNS (1.1.1.1/8.8.8.8) goes through WG tunnel
- `device-mode fetch=yes, scheduler=yes` — enabled via physical button confirmation
- See [TRAFFIC_FORWARDING.md](./TRAFFIC_FORWARDING.md) for full details