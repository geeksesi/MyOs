# Dual-WAN Policy Routing, WireGuard VPN & Iran IP Traffic

## Overview

MikroTik RB750Gr3 (RouterOS 7.18.2) configured with dual-WAN policy-based routing and WireGuard VPN. Iran-destined traffic routes via WAN2 (Iran ISP) directly, everything else tunnels through a WireGuard VPN on a VPS via WAN1.

| Interface | Role | Connection | Notes |
|-----------|------|------------|-------|
| ether1 | WAN1 | DHCP (global ISP) | Carries WireGuard tunnel |
| ether5 | WAN2 | DHCP (Iran ISP) | Iran traffic via policy routing |
| wg0 | WireGuard | Tunnel to 206.189.122.139:56758 | Default route for non-Iran traffic |
| bridge (ether2-4) | LAN | 192.168.88.0/24 | Single LAN for all clients |

## Network Topology

```
Internet (Global)          Internet (Iran ISP)
      |                          |
 [VPN Server]                    |
 206.189.122.139:56758           |
      |                          |
  [WireGuard tunnel]             |
  wg0 (10.66.66.2)              |
      |                          |
   [ether1]                  [ether5]
   WAN1 (DHCP)               WAN2 (DHCP)
      |                          |
      +--------[Router]----------+
                  |
           [bridge: ether2-4]
            192.168.88.0/24
            LAN clients

  dst = Iran IP?       → ether5 directly (mangle to-iran mark)
  dst = 206.189.122.139 → ether1 directly (loop prevention host route)
  dst = anything else   → wg0 tunnel → ether1 → VPN server
```

## How Policy Routing Works

1. **Mangle rule** in `prerouting` chain marks new connections from LAN (192.168.88.0/24) destined for `IRAN` address-list with `connection-mark=iran-conn`
2. **Second mangle rule** marks routing (`routing-mark=to-iran`) for all packets with `iran-conn` connection mark coming from LAN (`in-interface-list=LAN`)
3. **Routing table** `to-iran` has a default route pointing to ether5's DHCP gateway
4. **DHCP client script** on ether5 dynamically updates the `to-iran` route when the gateway changes
5. **Masquerade NAT** on WAN interface list handles source NAT (covers ether5)
6. **FastTrack exclusion** — FastTrack rule only applies to `connection-mark=no-mark`, so Iran-marked connections always go through the full routing path (mangle → routing mark → correct interface)

### Why Two Mangle Rules (mark-connection + mark-routing)

A single `mark-routing` rule on `connection-state=new` only marks the first SYN packet. All subsequent packets (including retransmissions) would lose the routing mark. The two-step approach:
- **mark-connection** sets a persistent connection mark (`iran-conn`) on the first packet
- **mark-routing** applies the routing mark to every packet with that connection mark

### Why `in-interface-list=LAN` on mark-routing

Without this, return traffic (SYN-ACK from Iran servers) arriving on ether5 with `iran-conn` connection mark would ALSO get the `to-iran` routing mark. This causes the return packet to be routed back out ether5 (`in:ether5 out:ether5`) instead of being forwarded to the LAN bridge. The `in-interface-list=LAN` restriction ensures only outbound LAN traffic gets the routing mark; return traffic uses the main routing table to reach the client.

### Why FastTrack Must Exclude Iran Connections

FastTrack only works with the main routing table. FastTracked packets bypass mangle entirely, so the `to-iran` routing mark is never applied. This causes established Iran connection packets (ACKs, data) to route via the main table's default (wg0) instead of ether5 — resulting in TCP retransmissions and severe slowness. Setting `connection-mark=no-mark` on the FastTrack rule ensures only non-policy-routed traffic is FastTracked.

## Iran IP Address List

- **Source:** https://github.com/Ramtiiin/iran-ip (`ip-list.rsc`)
- **Address-list name:** `IRAN`
- **Entries:** ~1,388 CIDR blocks
- **Format:** RouterOS `/ip firewall address-list` commands

### Updating the List

Since `device-mode fetch=no`, the router cannot download files directly. To update:

1. Download `ip-list.rsc` from the GitHub repo
2. Upload to router via WinBox (Files > drag & drop)
3. Run on the router:
   ```mikrotik
   /ip firewall address-list remove [find list=IRAN]
   /import file-name=ip-list.rsc
   /ip firewall address-list print count-only where list=IRAN
   ```

To enable auto-update (requires physical reboot):
```mikrotik
/system device-mode update fetch=yes
# Power cycle the router when prompted
```

After enabling fetch, create the update script and scheduler:
```mikrotik
/system script add name=update-iran-ip-list source={
:local fileName "iran-ip-list.rsc"
:local url "https://raw.githubusercontent.com/Ramtiiin/iran-ip/main/ip-list.rsc"
:log info "Iran IP Update: Starting download..."
:do {
  /tool fetch url=$url dst-path=$fileName
  :delay 2s
  /ip firewall address-list remove [find list=IRAN]
  /import file-name=$fileName
  :local count [/ip firewall address-list print count-only where list=IRAN]
  :log info ("Iran IP Update: Complete. Loaded " . $count . " entries.")
} on-error={
  :log error "Iran IP Update: Failed. Keeping existing list."
}
}

/system scheduler add name=update-iran-ip-daily interval=1d start-time=04:00:00 on-event=update-iran-ip-list
```

## Mangle Rules

```
#  Chain        Action            Match                                                   Comment
3  prerouting   mark-connection   new-conn-mark=iran-conn passthrough=yes                 Route Iran traffic via WAN2
                                  src=192.168.88.0/24 dst-list=IRAN state=new
4  prerouting   mark-routing      new-routing-mark=to-iran passthrough=no                 Route Iran-marked connections via WAN2
                                  connection-mark=iran-conn in-interface-list=LAN
5  forward      change-mss        out-interface=wg0 tcp syn clamp-to-pmtu                 Clamp MSS for WireGuard
6  output       change-mss        out-interface=wg0 tcp syn clamp-to-pmtu                 Clamp MSS for WireGuard (output)
7I forward      change-mss        out-interface=lte1 tcp syn clamp-to-pmtu                MSS clamp for USB tethering (disabled/invalid, lte1 not ready)
```

Iran connections use the two-step mark-connection + mark-routing approach. FastTrack is excluded for these connections (see Firewall Rules).

## WireGuard VPN

### Configuration

- **Interface:** wg0 (MTU 1420)
- **Tunnel IP:** 10.66.66.2/32
- **Server:** 206.189.122.139:56758
- **Allowed IPs:** 0.0.0.0/0, ::/0
- **Keepalive:** 25s
- **Performance:** Software-based on RB750Gr3, ~100-200 Mbps

### How WireGuard Routing Works

1. **Default route** via wg0 at distance 1 — all non-Iran traffic enters the tunnel
2. **Host route** for 206.189.122.139/32 via ether1 gateway — prevents routing loop (WG encapsulated packets go directly to the VPN server via ether1, not back into the tunnel)
3. **ether1 DHCP default route** pushed to distance 2 — serves as fallback if wg0 is disabled
4. **DHCP client script on ether1** keeps the host route gateway updated when ether1's DHCP lease changes
5. **wg0 is in the WAN interface list** — existing masquerade (`out-interface-list=WAN`) and firewall rule 6 (`drop WAN not DSTNATed`) automatically apply to wg0

### MSS Clamping

Two mangle rules clamp TCP MSS to PMTU for traffic going through the WG tunnel, preventing fragmentation issues:

```
#  Chain     Action      Match                                    Comment
4  forward   change-mss  out-interface=wg0 tcp syn clamp-to-pmtu  Clamp MSS for WireGuard
5  output    change-mss  out-interface=wg0 tcp syn clamp-to-pmtu  Clamp MSS for WireGuard (output)
```

### DHCP Client Script (ether1)

The DHCP client on ether1 updates the WG endpoint host route when the gateway changes:

```mikrotik
:local gwIP $"gateway-address"
:do {
  /ip route set [find comment="WG endpoint via ether1 directly"] gateway=$gwIP
  :log info "WAN1: Updated WG endpoint route gateway to $gwIP"
} on-error={
  :log warning "WAN1: Failed to update WG endpoint route"
}
```

### Fallback Behavior (No Kill Switch)

| Scenario | What happens | Internet? |
|----------|-------------|-----------|
| wg0 disabled (WinBox/CLI) | Traffic falls back to ether1 directly (distance 2) | Yes, unencrypted |
| WG server unreachable, wg0 "up" | Packets black-hole in tunnel | No (Iran via ether5 still works) |
| ether1 link down | Both WG and ether1 fallback fail | No (Iran via ether5 still works) |

**Quick restore if WG is broken but "up":** Disable wg0 in WinBox (Interfaces → wg0 → Disable). Traffic falls back to ether1.

### Disabling VPN Temporarily

In WinBox: Interfaces → wg0 → right-click → Disable. All traffic falls back to ether1 directly. Re-enable to restore the tunnel.

## Routing Tables

| Table | Default Gateway | Distance | Source |
|-------|----------------|----------|--------|
| main | wg0 | 1 | Static route (preferred) |
| main | ether1 DHCP gateway | 2 | DHCP client (fallback) |
| main | 206.189.122.139/32 → ether1 gw | 1 | Static host route (loop prevention) |
| to-iran | ether5 DHCP gateway | — | Set dynamically by DHCP client script |

### DHCP Client Script (ether5)

The DHCP client on ether5 runs this script on lease acquisition to update the `to-iran` routing table:

```mikrotik
:local gwIP $"gateway-address"
/ip route remove [find routing-table=to-iran]
/ip route add dst-address=0.0.0.0/0 gateway=$gwIP routing-table=to-iran comment="WAN2 Iran default route"
:log info "WAN2 gateway updated: $gwIP"
```

## Firewall Rules (Forward Chain)

```
#   Comment                         Action     Match
--  ------------------------------  ---------  ----------------------------------------
1   accept in ipsec policy          accept     ipsec-policy=in,ipsec
2   accept out ipsec policy         accept     ipsec-policy=out,ipsec
3   fasttrack                       fasttrack  hw-offload=yes state=established,related
                                                connection-mark=no-mark
4   accept established,related      accept     state=established,related,untracked
5   drop invalid                    drop       state=invalid
6   drop WAN not DSTNATed           drop       state=new nat-state=!dstnat in-list=WAN
```

**Note:** Rule 6 covers ether1, ether5, and wg0 since all three are in the WAN interface list. This protects against unsolicited inbound via the WG tunnel as well.

**FastTrack exclusion:** Rule 3 has `connection-mark=no-mark` to prevent FastTrack from grabbing policy-routed Iran connections. FastTrack bypasses mangle, so FastTracked packets lose their `to-iran` routing mark and get misrouted through wg0. Only unmarked (non-Iran) connections are FastTracked.

## NAT Rules

```
#  Chain    Action      Match                                         Comment
0  dstnat   redirect    udp dst-port=53                               Force DNS to router (UDP)
1  srcnat   masquerade  out-interface-list=WAN ipsec-policy=out,none  Masquerade (covers ether1, ether5, wg0)
2  dstnat   redirect    tcp dst-port=53                               Force DNS to router (TCP)
3  srcnat   masquerade  out-interface=ether5 ipsec-policy=out,none    Masquerade WAN2 - Iran
4I srcnat   masquerade  out-interface=lte1                            NAT for USB tethering (disabled/invalid)
5I srcnat   masquerade  out-interface=lte1                            NAT for USB tethering (disabled/invalid)
```

DNS redirect ensures all LAN DNS queries go through the router. The router itself uses 1.1.1.1/8.8.8.8, which now routes through the WG tunnel.

**Note:** NAT rule 3 is redundant since rule 1 already covers ether5 via the WAN interface list. Both rules match Iran-bound traffic. Consider removing rule 3 to avoid double masquerade processing.

## DHCP Configuration

| Parameter | LAN (bridge) |
|-----------|-------------|
| Pool name | default-dhcp |
| Range | 192.168.88.10-254 |
| Gateway | 192.168.88.1 |
| DNS | 192.168.88.1 (router) |
| Lease time | 10m |

## Interface Lists

| List | Members |
|------|---------|
| LAN | bridge |
| WAN | ether1, ether5, wg0 |

## Verification Commands

```mikrotik
# WireGuard status
/interface wireguard print
/interface wireguard peers print detail
# → last-handshake should be recent, tx/rx non-zero

# WG tunnel IP
/ip address print where interface=wg0

# Routing table
/ip route print
# → 0.0.0.0/0 via wg0 distance=1 (active, preferred)
# → 0.0.0.0/0 via ether1-gw distance=2 (active, not preferred)
# → 206.189.122.139/32 via ether1-gw (active)

# Test from router
/ping 10.66.66.1 count=4
/ping 1.1.1.1 count=4

# Verify non-Iran goes through WG (first hop = 10.66.66.1)
/tool traceroute 8.8.8.8

# Verify Iran goes via ether5 (first hop = ether5 gateway)
/tool traceroute 2.144.0.1

# Check ether5 DHCP client status
/ip dhcp-client print where interface=ether5

# Check to-iran routing table
/ip route print where routing-table=to-iran

# Check mangle rule counters
/ip firewall mangle print stats

# Check forward chain
/ip firewall filter print where chain=forward

# Check Iran address-list count (should be ~1388)
/ip firewall address-list print count-only where list=IRAN

# From LAN client: visit whatismyip.com → should show VPN server IP
```

## Rollback

### Remove WireGuard Only (keep dual-WAN)

```mikrotik
# Quick rollback (restore direct ether1 routing):
/ip route remove [find comment="Default route via WireGuard"]
/ip dhcp-client set [find interface=ether1] default-route-distance=1

# Full WireGuard rollback:
/ip route remove [find comment="Default route via WireGuard"]
/ip route remove [find comment="WG endpoint via ether1 directly"]
/ip firewall mangle remove [find comment~"WireGuard"]
/interface list member remove [find interface=wg0 list=WAN]
/ip address remove [find interface=wg0]
/interface wireguard peers remove [find interface=wg0]
/interface wireguard remove wg0
/ip dhcp-client set [find interface=ether1] default-route-distance=1
/ip dhcp-client set [find interface=ether1] script=""

# Or restore from backup:
/system backup load name=pre-wireguard
```

### Remove Dual-WAN (revert to single-WAN)

```mikrotik
# Remove mangle rules
/ip firewall mangle remove [find comment~"Iran"]

# Remove WAN2 masquerade
/ip firewall nat remove [find comment~"WAN2"]

# Remove to-iran routing table routes
/ip route remove [find routing-table=to-iran]
/routing table remove to-iran

# Remove DHCP client on ether5
/ip dhcp-client remove [find interface=ether5]

# Remove ether5 from WAN list
/interface list member remove [find interface=ether5]

# Or restore from backup
/system backup load name=pre-dual-wan
```

## Backups

| Backup | Description |
|--------|-------------|
| `pre-iran-filter.backup` | Before original Iran filter setup |
| `pre-iran-filter-export.rsc` | Text export before original setup |
| `post-iran-filter-complete.backup` | After original dual-LAN setup |
| `post-iran-filter-complete-export.rsc` | Text export after original setup |
| `pre-dual-wan.backup` | Before dual-WAN conversion |
| `pre-dual-wan-export.rsc` | Text export before dual-WAN conversion |
| `pre-wireguard.backup` | Before WireGuard VPN setup |
| `pre-wireguard-export.rsc` | Text export before WireGuard VPN setup |
