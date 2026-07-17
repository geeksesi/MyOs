# Dual-WAN Policy Routing & Iran IP Traffic Splitting

## Overview

MikroTik RB750Gr3 (RouterOS 7.20.8) configured with dual-WAN policy-based routing. Iran-destined traffic routes via WAN2 (Iran ISP) directly, everything else goes via WAN1 (global ISP) directly.

| Interface | Role | Connection | Notes |
|-----------|------|------------|-------|
| ether1 | WAN1 | DHCP (global ISP) | Default route for non-Iran traffic |
| ether5 | WAN2 | DHCP (Iran ISP) | Iran traffic via policy routing |
| bridge (ether2-4) | LAN | 192.168.88.0/24 | Single LAN for all clients |

## Network Topology

```
Internet (Global)          Internet (Iran ISP)
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
  dst = anything else  → ether1 directly (DHCP default route)
```

## How Policy Routing Works

1. **Mangle rule** in `prerouting` chain marks new connections from LAN (192.168.88.0/24) destined for `NoNAT` address-list with `connection-mark=iran-conn`
2. **Second mangle rule** marks routing (`routing-mark=to-iran`) for all packets with `iran-conn` connection mark coming from LAN (`in-interface-list=LAN`)
3. **Third mangle rule** in `output` chain marks the router's own Iran-destined traffic with `routing-mark=to-iran`
4. **Routing table** `to-iran` has a default route pointing to ether5's DHCP gateway
5. **DHCP client script** on ether5 dynamically updates the `to-iran` route when the gateway changes
6. **Masquerade NAT** on WAN interface list handles source NAT (covers ether1 and ether5)
7. **FastTrack exclusion** — FastTrack rule only applies to `connection-mark=no-mark`, so Iran-marked connections always go through the full routing path (mangle → routing mark → correct interface)

### Why Two Mangle Rules (mark-connection + mark-routing)

A single `mark-routing` rule on `connection-state=new` only marks the first SYN packet. All subsequent packets (including retransmissions) would lose the routing mark. The two-step approach:
- **mark-connection** sets a persistent connection mark (`iran-conn`) on the first packet
- **mark-routing** applies the routing mark to every packet with that connection mark

### Why `in-interface-list=LAN` on mark-routing

Without this, return traffic (SYN-ACK from Iran servers) arriving on ether5 with `iran-conn` connection mark would ALSO get the `to-iran` routing mark. This causes the return packet to be routed back out ether5 (`in:ether5 out:ether5`) instead of being forwarded to the LAN bridge. The `in-interface-list=LAN` restriction ensures only outbound LAN traffic gets the routing mark; return traffic uses the main routing table to reach the client.

### Why FastTrack Must Exclude Iran Connections

FastTrack only works with the main routing table. FastTracked packets bypass mangle entirely, so the `to-iran` routing mark is never applied. This causes established Iran connection packets (ACKs, data) to route via the main table's default (ether1) instead of ether5 — resulting in TCP retransmissions and severe slowness. Setting `connection-mark=no-mark` on the FastTrack rule ensures only non-policy-routed traffic is FastTracked.

## Iran IP Address List

- **Address-list name:** `NoNAT`
- **Entries:** ~1923 CIDR blocks
- **Source:** [MrAriaNet/Get-IP-Iran](https://github.com/MrAriaNet/Get-IP-Iran) (RIPE data)
- **Auto-update:** Daily at 03:00 via RouterOS scheduler script `update-nonat`
- `device-mode fetch=yes` — enabled via physical button confirmation

## Mangle Rules

```
#  Chain        Action            Match                                                   Comment
0  prerouting   mark-connection   new-conn-mark=iran-conn passthrough=yes                 Route Iran traffic via WAN2
                                  src=192.168.88.0/24 dst-list=NoNAT state=new
1  prerouting   mark-routing      new-routing-mark=to-iran passthrough=no                 Route Iran-marked connections via WAN2
                                  connection-mark=iran-conn in-interface-list=LAN
2I forward      change-mss        out-interface=lte1 tcp syn clamp-to-pmtu                MSS clamp for USB tethering (invalid, lte1 not ready)
3  output       mark-routing      new-routing-mark=to-iran passthrough=no                 Route router own traffic to Iran IPs via WAN2
                                  dst-address-list=NoNAT
```

## Routing Tables

| Table | Default Gateway | Distance | Source |
|-------|----------------|----------|--------|
| main | ether1 DHCP gateway | 1 | DHCP client (default) |
| to-iran | ether5 DHCP gateway | 1 | Set dynamically by DHCP client script |

### DHCP Client Script (ether5)

The DHCP client on ether5 runs this script on lease acquisition to update the `to-iran` routing table:

```mikrotik
:local gwIP $"gateway-address"
/ip route remove [find routing-table=to-iran]
/ip route add dst-address=0.0.0.0/0 gateway=$gwIP routing-table=to-iran comment="WAN2 Iran default route"
:log info "WAN2 gateway updated: $gwIP"
```

### DHCP Client (ether1)

Standard DHCP client, default-route-distance=1. No custom script.

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

**FastTrack exclusion:** Rule 3 has `connection-mark=no-mark` to prevent FastTrack from grabbing policy-routed Iran connections. FastTrack bypasses mangle, so FastTracked packets lose their `to-iran` routing mark and get misrouted through ether1. Only unmarked (non-Iran) connections are FastTracked.

## NAT Rules

```
#  Chain    Action      Match                                         Comment
0  dstnat   redirect    udp dst-port=53                               Force DNS to router (UDP)
1  srcnat   masquerade  out-interface-list=WAN ipsec-policy=out,none  Masquerade (covers ether1, ether5)
2  dstnat   redirect    tcp dst-port=53                               Force DNS to router (TCP)
3  srcnat   masquerade  out-interface=ether5 ipsec-policy=out,none    Masquerade WAN2 - Iran
4I srcnat   masquerade  out-interface=lte1                            NAT for USB tethering (disabled/invalid)
5I srcnat   masquerade  out-interface=lte1                            NAT for USB tethering (disabled/invalid)
```

DNS redirect ensures all LAN DNS queries go through the router. The router itself uses 1.1.1.1/8.8.8.8, which routes via ether1.

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
| WAN | ether1, ether5 |

## Verification Commands

```mikrotik
# Routing table
/ip route print
# → 0.0.0.0/0 via ether1-gw distance=1 (active, preferred)

# Check to-iran routing table
/ip route print where routing-table=to-iran

# Verify Iran goes via ether5 (first hop = ether5 gateway)
/tool traceroute 2.144.0.1

# Verify non-Iran goes via ether1
/tool traceroute 8.8.8.8

# Check ether5 DHCP client status
/ip dhcp-client print where interface=ether5

# Check mangle rule counters
/ip firewall mangle print stats

# Check forward chain
/ip firewall filter print where chain=forward

# Check Iran address-list count
/ip firewall address-list print count-only where list=NoNAT
```

## Rollback

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
| `pre-wg-removal.backup` | Before WireGuard removal (2026-03-23) |
