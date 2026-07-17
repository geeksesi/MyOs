tell me to run ssh commands

## MikroTik Setup (RB750Gr3, RouterOS 7.20.8)

- **ether1** = WAN1 (DHCP, global internet — default route)
- **ether5** = WAN2 (DHCP, Iran ISP — Iran traffic via policy routing)
- **bridge (ether2-4)** = LAN (192.168.88.0/24)
- Iran IPs: `NoNAT` address-list (~1923 CIDRs) from [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran) (RIPE data, auto-updated daily at 03:00 via RouterOS scheduler script `update-nonat`)
- **Traffic flow:**
  - Iran destinations → ether5 directly (two-step mangle: `mark-connection iran-conn` + `mark-routing to-iran` with `in-interface-list=LAN`, matches `dst-address-list=NoNAT`)
  - All other traffic → ether1 directly (DHCP default route, distance 1)
- **FastTrack:** `connection-mark=no-mark` — excludes Iran-marked connections (FastTrack bypasses mangle, breaking policy routing)
- DNS forced to router (port 53 redirect) on LAN; router DNS uses 1.1.1.1/8.8.8.8
- `device-mode fetch=yes, scheduler=yes` — enabled via physical button confirmation
- See [TRAFFIC_FORWARDING.md](./TRAFFIC_FORWARDING.md) for full details
