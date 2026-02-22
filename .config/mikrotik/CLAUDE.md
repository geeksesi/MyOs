tell me to run ssh commands

## MikroTik Setup (RB750Gr3, RouterOS 7.18.2)

- **ether1** = WAN1 (DHCP, global internet — carries WireGuard tunnel)
- **ether5** = WAN2 (DHCP, Iran ISP — Iran traffic via policy routing)
- **wg0** = WireGuard tunnel to VPN server (10.66.66.2 → 206.189.122.139:56758)
- **bridge (ether2-4)** = LAN (192.168.88.0/24)
- Iran IPs: `IRAN` address-list (~1388 CIDRs) from [Ramtiiin/iran-ip](https://github.com/Ramtiiin/iran-ip)
- **Traffic flow:**
  - Iran destinations → ether5 directly (mangle `to-iran` routing mark)
  - All other traffic → wg0 tunnel (default route, distance 1) → ether1 → VPN server
  - WG endpoint (206.189.122.139) → ether1 directly (host route, loop prevention)
  - ether1 DHCP default route at distance 2 (fallback if WG is down/disabled)
- DNS forced to router (port 53 redirect) on LAN; router DNS (1.1.1.1/8.8.8.8) goes through WG tunnel
- `device-mode fetch=no` — auto-update requires enabling fetch + physical reboot
- See [TRAFFIC_FORWARDING.md](./TRAFFIC_FORWARDING.md) for full details