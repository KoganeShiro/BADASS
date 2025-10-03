# Part 3: Discovering BGP with EVPN

## 📋 Overview
Part 3 introduces BGP-EVPN (Border Gateway Protocol - Ethernet VPN), the modern control plane for data center networks. This part demonstrates how to automate VXLAN tunnel management and MAC address learning using BGP, eliminating manual configuration and enabling scalable multi-site connectivity.

---

## 💡 Why BGP-EVPN?

### The Problem BGP-EVPN Solves

Imagine you have:
- 100 data center racks (leaf switches) 🏢
- Each rack needs to talk to all other racks
- With static VXLAN: 100 × 99 = **9,900 manual tunnel configurations!** 😱

❌ **Static VXLAN:** Not practical for large deployments!  
✅ **BGP-EVPN:** Automatic discovery and configuration!

### Why Use BGP-EVPN?

| Benefit | Description | Example |
|---------|-------------|---------|
| **🤖 Automation** | VTEPs discover each other automatically | Zero-touch provisioning |
| **📈 Scalability** | Add new sites without touching existing config | Data center expansion |
| **🔄 Dynamic MAC Learning** | MACs advertised via BGP (control plane) | No data plane flooding |
| **🏢 Multi-Tenancy** | Separate virtual networks with route targets | Cloud provider isolation |
| **🔀 Load Balancing** | ECMP across multiple paths | Better resource utilization |

### Why It's Important to Know

**For Modern Data Centers:**
- **Cloud Providers:** AWS VPC, Azure VNet use similar technology
- **Enterprise DC:** Standard for leaf-spine architectures
- **Network Virtualization:** VMware NSX, Cisco ACI rely on EVPN
- **SD-WAN:** Control plane for overlay networks

---

## 🏗️ Architecture

### Network Topology

```
                    ┌──────────────────────┐
                    │    Route Reflector   │
                    │     router-1         │
                    │   (Spine Router)     │
                    │ Loopback: 1.1.1.1/32 │
                    └─────────┬────────────┘
          10.1.1.1/30    10.1.1.5/30    10.1.1.9/30
                              │
              ┌───────────────┼───────────────┐
              │               │               │
 eth0 10.1.1.2/30    10.1.1.6/30    10.1.1.10/30
      ┌───────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
      │   VTEP-2     │ │   VTEP-3   │ │   VTEP-4   │
      │  router-2    │ │  router-3  │ │  router-4  │
      │ (Leaf Node)  │ │ (Leaf Node)│ │ (Leaf Node)│
      │ Loopback:    │ │ Loopback:  │ │ Loopback:  │
      │  1.1.1.2/32  │ │  1.1.1.3/32│ │  1.1.1.4/32│
      └───────┬──────┘ └─────┬──────┘ └─────┬──────┘
              │               │               │
              │ eth1          │ eth1          │ eth1
        ┌─────▼────┐   ┌─────▼─────┐  ┌─────▼─────┐
        │  Host-1  │   │  Host-2   │  │  Host-3   │
        │ 20.1.1.1 │   │  20.1.1.3 │  │  20.1.1.2 │
        └──────────┘   └───────────┘  └───────────┘

         All hosts on same overlay network (VNI 10)
```

### Component Details

| Component | Role | Interfaces | IP Addresses |
|-----------|------|------------|--------------|
| **router-1** | Route Reflector (Spine) | eth0, eth1, eth2, lo | eth0: 10.1.1.1/30, eth1: 10.1.1.5/30, eth2: 10.1.1.9/30, lo: 1.1.1.1/32 |
| **router-2** | VTEP (Leaf Site 1) | eth0, eth1, lo, br10 | eth0: 10.1.1.2/30, lo: 1.1.1.2/32 |
| **router-3** | VTEP (Leaf Site 2) | eth0, eth1, lo, br10 | eth0: 10.1.1.6/30, lo: 1.1.1.3/32 |
| **router-4** | VTEP (Leaf Site 3) | eth0, eth1, lo, br10 | eth0: 10.1.1.10/30, lo: 1.1.1.4/32 |
| **host-1** | End device | eth0 | 20.1.1.1/24 |
| **host-2** | End device | eth0 | 20.1.1.3/24 |
| **host-3** | End device | eth0 | 20.1.1.2/24 |

### Key Differences from Part 2

| Aspect | Part 2 (Static VXLAN) | Part 3 (BGP-EVPN) |
|--------|------------------------|-------------------|
| **VTEP Discovery** | Manual remote IP config | Automatic via BGP Type 3 routes |
| **MAC Learning** | Data plane (flooding) | Control plane (BGP Type 2 routes) |
| **Scalability** | 2 sites | 3+ sites easily |
| **Control Protocol** | None | BGP with EVPN address family |
| **Underlay Protocol** | Static routes | OSPF for loopback reachability |

---

## 🛠️ Implementation Steps

### Step 1: Environment Setup

This project assumes you have completed Parts 1 and 2:
- GNS3 installed and configured
- Docker images built (host and router with FRRouting)
- Understanding of VXLAN concepts from Part 2

---

### Step 2: Create GNS3 Topology

#### Topology Setup in GNS3

1. **Create New Project:**
   - File → New blank project
   - Name: "P3"
   - Location: Choose workspace

2. **Add Devices:**
   - 4x Router containers (your Docker router image with FRRouting)
   - 3x Host containers (your Docker host image)

3. **Connect Devices:**
   - router-1 eth0 ↔ router-2 eth0 (underlay link 1)
   - router-1 eth1 ↔ router-3 eth0 (underlay link 2)
   - router-1 eth2 ↔ router-4 eth0 (underlay link 3)
   - router-2 eth1 ↔ host-1 eth0
   - router-3 eth1 ↔ host-2 eth0
   - router-4 eth1 ↔ host-3 eth0

4. **Start All Devices:**
   - Right-click → Start all
   - Wait for containers to initialize

---

### Step 3: Configure Network

The configuration of routing-services (BGP and OSPF) is persistant and already configured in the GNS3 project. Interfaces can be configured with configuration scripts: config_routers.sh and config_hosts.sh are provided in the P3 directory.

The configuration involves three layers:

1. **Physical Interfaces & Loopbacks** (Underlay)
2. **OSPF** (Underlay routing)
3. **BGP-EVPN** (Control plane)
4. **VXLAN** (Data plane)

- Configure IP addresses on all interfaces
- Set up OSPF for loopback reachability
- Configure BGP with EVPN address family
- Create VXLAN interfaces with dynamic learning
- Establish route reflection topology

---

## 🧠 Key Concepts

### What is BGP-EVPN?

**BGP-EVPN (Border Gateway Protocol - Ethernet VPN)** is like having a smart postal system that automatically learns routes:

```
📮 Static VXLAN (Part 2):
   Manual address book with fixed routes
   You specify: "Send to 192.168.100.2"

📮 Dynamic Multicast VXLAN:
   Broadcast group announcement
   "Anyone in group 239.1.1.1, here's my packet!"
   
📮 BGP-EVPN (Part 3):
   Smart system that automatically updates address book
   when new locations join or MACs move
   "I'll tell everyone exactly what they need to know"
```

**Evolution of VXLAN:**

| Mode | Discovery Method | Scalability | Complexity |
|------|-----------------|-------------|------------|
| **Static** | Manual config | Low (2-3 sites) | Simple |
| **Multicast** | Multicast groups | Medium (10-50 sites) | Medium |
| **BGP-EVPN** | BGP control plane | High (1000+ sites) | Advanced |

**Why BGP-EVPN wins:**
- **Static VXLAN:** ❌ Manual = not scalable
- **Multicast VXLAN:** ⚠️ Requires multicast in underlay (many networks don't support it)
- **BGP-EVPN:** ✅ Uses standard BGP (works everywhere!)

### Route Reflector - The Hub

Think of the Route Reflector as a **central message board** in an office:

```
        ┌────────────────────────┐
        │  Route Reflector (RR)  │
        │   "Message Board"      │
        └───────┬────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
Employee 1  Employee 2  Employee 3
(router-2)  (router-3)  (router-4)

Instead of telling everyone individually:
❌ Employee 1 → tells → Employee 2
❌ Employee 1 → tells → Employee 3
❌ Employee 2 → tells → Employee 1
   ... 6 conversations!

With message board:
✅ Employee 1 → posts to board → Everyone sees it
   ... 1 message reaches everyone!
```

**Benefits:**
- Employees (VTEPs) only talk to the board (RR)
- Board distributes messages to everyone
- Scales from 3 to 300+ employees easily

### EVPN Route Types

BGP-EVPN uses special route types to share information:

#### Type 2 Routes: MAC/IP Advertisement

```
"Hey everyone! I found a device!"

┌─────────────────────────────────────┐
│ Type 2 Route from router-2:        │
│                                     │
│ MAC: aa:bb:cc:dd:ee:01             │
│ IP: 20.1.1.1                       │
│ Located at VTEP: 1.1.1.2           │
│ VNI: 10                            │
└─────────────────────────────────────┘

Now everyone knows:
- To reach MAC aa:bb:cc:dd:ee:01
- Send VXLAN packet to VTEP 1.1.1.2
```

#### Type 3 Routes: VTEP Discovery

```
"Hello! I'm a VTEP, here's my address!"

┌─────────────────────────────────────┐
│ Type 3 Route from router-2:        │
│                                     │
│ I am VTEP: 1.1.1.2                 │
│ I support VNI: 10                  │
│ Send me traffic for VNI 10         │
└─────────────────────────────────────┘

Now everyone knows:
- router-2 is a VTEP at 1.1.1.2
- It handles VNI 10 (VXLAN ID)
- Can establish VXLAN tunnels to it
```

### Control Plane vs Data Plane

**Part 2 (Static VXLAN):** Data plane learning
```
1. Host-1 sends ARP (broadcast)
2. VXLAN floods to all VTEPs
3. VTEPs learn MACs from data packets
4. Problem: Lots of flooding! 📢📢📢
```

**Part 3 (BGP-EVPN):** Control plane learning
```
1. Host-1 sends frame
2. router-2 learns MAC locally
3. router-2 sends BGP Type 2 route
4. All VTEPs learn via control plane
5. No flooding needed! ✅
```

### Underlay vs Overlay

```
┌────────────────────────────────────┐
│     OVERLAY (Virtual Network)      │
│  20.1.1.0/24 - VNI 10             │
│  Hosts think they're on one switch │
└──────────────┬─────────────────────┘
               │
               │ BGP-EVPN
               │ (Control Plane)
               │
┌──────────────▼─────────────────────┐
│     UNDERLAY (Physical Network)    │
│  10.1.1.0/30, 1.1.1.x loopbacks   │
│  OSPF routes, IP connectivity      │
└────────────────────────────────────┘

Underlay = "The highway system"
Overlay = "The delivery addresses"
BGP-EVPN = "The GPS navigation"
```

### Why OSPF in the Underlay?

**OSPF provides:**
- Automatic route discovery between routers
- Fast convergence (< 1 second)
- Loopback reachability (needed for BGP peering)

**Without OSPF:**
❌ Manual static routes on every router  
❌ Can't reach loopback addresses  
❌ BGP sessions won't establish

**With OSPF:**
✅ Automatic routing  
✅ All loopbacks reachable  
✅ BGP can peer using loopbacks

---

## 🐛 Troubleshooting

### Issue: BGP Neighbors Not Establishing

**Step 1: Check Underlay (OSPF)**
```bash
# On any router
vtysh -c "show ip ospf neighbor"

# Expected: Should see neighbors in "Full" state
# If not: Check OSPF configuration and interface IPs
```

**Step 2: Test Loopback Reachability**
```bash
# On router-2, ping route reflector loopback
ping 1.1.1.1 -c 4

# Expected: SUCCESS
# If fails: OSPF not working correctly
```

**Step 3: Check BGP Configuration**
```bash
vtysh -c "show bgp summary"

# Look for:
# - Correct neighbor IPs (loopbacks)
# - State should be "Established"
# - Not "Active" or "Connect"
```

### Issue: No Type 3 Routes

**Symptoms:**
- BGP established but VTEPs can't discover each other
- No VXLAN tunnels formed

**Check EVPN Address Family**
```bash
vtysh -c "show bgp l2vpn evpn summary"

# Neighbors should be activated for L2VPN EVPN
```

## 📚 Additional Resources

### BGP-EVPN Specifications
- [RFC 7432 - BGP MPLS-Based Ethernet VPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [RFC 8365 - EVPN Overlay for VXLAN](https://datatracker.ietf.org/doc/html/rfc8365)

### FRRouting Documentation
- [FRR BGP EVPN Guide](http://docs.frrouting.org/en/latest/evpn.html)
- [FRR OSPF Configuration](http://docs.frrouting.org/en/latest/ospfd.html)

### Learning Resources
- [Data Center Fabrics - Cisco](https://www.cisco.com/c/en/us/solutions/data-center-virtualization/what-is-a-data-center-fabric.html)
- [EVPN Tutorial - Juniper](https://www.juniper.net/documentation/us/en/software/junos/evpn-vxlan/)

---

### Configuration Layers Summary

**Layer 1: Physical Interfaces**
- Point-to-point links between spine and leaves
- Loopback interfaces on all routers

**Layer 2: OSPF Underlay**
- Advertise loopback addresses
- Advertise point-to-point link subnets
- Provides reachability for BGP peering

**Layer 3: BGP-EVPN Control Plane**
- Route reflector configuration on router-1
- VTEP clients peer with route reflector
- L2VPN EVPN address family enabled
- `advertise-all-vni` on leaf routers

**Layer 4: VXLAN Data Plane**
- VXLAN interfaces with `nolearning` flag
- Bridges connecting eth1 and vxlan10
- VNI 10 for all hosts

---

## 🧠 Advanced Concepts

### Route Reflection Flow

```
Host-1 sends packet to Host-2:

1. Host-1 → VTEP-2 (router-2)
   ├─ VTEP-2 learns Host-1 MAC locally
   └─ Advertises Type 2 route via BGP

2. VTEP-2 → Route Reflector (router-1)
   ├─ Type 2 route: MAC aa:bb:cc:dd:ee:01 @ 1.1.1.2
   └─ BGP UPDATE message

3. Route Reflector → VTEP-3 & VTEP-4
   ├─ Reflects Type 2 route to all clients
   └─ Clients install MAC → VTEP mapping

4. Future packets to Host-1:
   ├─ VTEP-3 & VTEP-4 know MAC is at 1.1.1.2
   └─ Direct VXLAN encapsulation to 1.1.1.2
```

### BGP-EVPN Route Attributes

```bash
# Type 2 Route Attributes:
[2]:[ESI]:[EthTag]:[MACl

### Step 6: Verify EVPN Operation

#### Check EVPN VNI Status

```bash
# On any VTEP (router-2, router-3, or router-4)
vtysh -c "show evpn vni"

# Expected output:
# VNI        Type VxLAN IF        # MACs   # ARPs   # Remote VTEPs
# 10         L2   vxlan10         1        1        2
```

#### Check Type 3 Routes (VTEP Discovery)

```bash
# On any VTEP
vtysh -c "show bgp l2vpn evpn route type multicast"

# Expected: 3 Type 3 routes (one from each VTEP)
# Example output:
# *> [3]:[0]:[32]:[1.1.1.2]
#     1.1.1.2                            0 64512 i
#     RT:64512:10
#
# *> [3]:[0]:[32]:[1.1.1.3]
#     1.1.1.3                            0 64512 i
#     RT:64512:10
#
# *> [3]:[0]:[32]:[1.1.1.4]
#     1.1.1.4                            0 64512 i
#     RT:64512:10
```

**Type 3 Route Explanation:**
- **[3]:** Route type 3 (Inclusive Multicast Ethernet Tag)
- **[32]:** IP prefix length
- **[1.1.1.x]:** VTEP loopback IP
- **RT:64512:10:** Route target for VNI 10

#### Test Connectivity

```bash
# On host-1
ping 20.1.1.3 -c 4  # Ping host-2
ping 20.1.1.2 -c 4  # Ping host-3

# Expected: SUCCESS on both
```

#### Check Type 2 Routes (MAC/IP Advertisement)

```bash
# On any VTEP, after hosts have communicated
vtysh -c "show bgp l2vpn evpn route type macip"

# Expected: Type 2 routes for each host
# Example:
# *> [2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]
#     1.1.1.2                            0 64512 i
#     RT:64512:10 ET:8
#
# *> [2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]:[32]:[20.1.1.1]
#     1.1.1.2                            0 64512 i
#     RT:64512:10 ET:8
```

**Type 2 Route Explanation:**
- **[2]:** Route type 2 (MAC/IP Advertisement)
- **[48]:** MAC address length in bits
- **[aa:bb:cc:dd:ee:01]:** Host MAC address
- **[32]:[20.1.1.1]:** Optional IP address
- **1.1.1.2:** VTEP where MAC is learned

#### Check MAC Table on VTEPs

```bash
# On router-2
vtysh -c "show evpn mac vni 10"

# Expected output:
# Number of MACs (local and remote) known for this VNI: 3
# MAC               Type   Intf/Remote VTEP      VLAN
# aa:bb:cc:dd:ee:01 local  eth1
# aa:bb:cc:dd:ee:02 remote 1.1.1.3
# aa:bb:cc:dd:ee:03 remote 1.1.1.4
```
---

## 🐛 Troubleshooting

### Issue: BGP Neighbors Not Establishing

**Symptoms:**
```bash
vtysh -c "show bgp summary"
# Neighbor shows "Active" or "Connect" state
```

**Troubleshooting Steps:**

1. **Check Underlay Connectivity:**
```bash
# Can loopbacks reach each other?
ping 1.1.1.1  # From any VTEP

# If fails, check OSPF
vtysh -c "show ip ospf neighbor"
vtysh -c "show ip route"
```

2. **Verify BGP Configuration:**
```bash
vtysh -c "show run bgp"

# Check:
# - Correct remote-as (64512)
# - Correct neighbor IPs (loopbacks)
# - update-source lo configured
```

3. **Check BGP Logs:**
```bash
vtysh -c "show bgp neighbors 1.1.1.1"

# Look for connection errors
tail -f /var/log/frr/bgpd.log
```

4. **Firewall/ACLs:**
```bash
# BGP uses TCP port 179
iptables -L
```

### Issue: No Type 3 Routes

**Symptoms:**
```bash
vtysh -c "show bgp l2vpn evpn route type multicast"
# No routes or missing routes
```

**Solutions:**

1. **Check EVPN Address Family:**
```bash
vtysh -c "show bgp l2vpn evpn summary"

# Should show:
# - Neighbor activated for L2VPN EVPN
# - State: Established
```

2. **Verify VNI Configuration:**
```bash
vtysh -c "show evpn vni"

# VNI 10 should be listed
# If not, check VXLAN interface:
ip -d link show vxlan10
```

3. **Check advertise-all-vni:**
```bash
vtysh

show run bgp
# Look for: advertise-all-vni under l2vpn evpn

# If missing, add it:
configure terminal
router bgp 64512
 address-family l2vpn evpn
  advertise-all-vni
 exit-address-family
exit
write memory
```

### Issue: No Type 2 Routes (MAC Learning)

**Symptoms:**
- Hosts can't communicate
- No MAC/IP routes in BGP

**Solutions:**

1. **Generate Traffic:**
```bash
# On host-1
ping 30.1.1.2

# MACs are learned when traffic flows
```

2. **Check Local MAC Table:**
```bash
# On VTEP connected to host-1
vtysh -c "show evpn mac vni 10"

# Should show local MAC
# If not, check bridge:
bridge fdb show br br10
```

3. **Verify BGP Advertisement:**
```bash
# On local VTEP
vtysh -c "show bgp l2vpn evpn route type macip"

# Should advertise local MAC
```

4. **Check nolearning Flag:**
```bash
ip -d link show vxlan10

# Should show: nolearning
# If data plane learning is on, BGP won't work correctly
```

---

## 🧠 Advanced Concepts

### Route Reflection Flow

```
Host-1 sends packet to Host-2:

1. Host-1 → VTEP-2 (router-2)
   ├─ VTEP-2 learns Host-1 MAC locally
   └─ Advertises Type 2 route via BGP

2. VTEP-2 → Route Reflector (router-1)
   ├─ Type 2 route: MAC aa:bb:cc:dd:ee:01 @ 1.1.1.2
   └─ BGP UPDATE message

3. Route Reflector → VTEP-3 & VTEP-4
   ├─ Reflects Type 2 route to all clients
   └─ Clients install MAC → VTEP mapping

4. Future packets to Host-1:
   ├─ VTEP-3 & VTEP-4 know MAC is at 1.1.1.2
   └─ Direct VXLAN encapsulation to 1.1.1.2
```

### BGP-EVPN Route Attributes

```bash
# Type 2 Route Attributes:
[2]:[ESI]:[EthTag]:[MAClen]:[MAC]:[IPlen]:[IP]
[2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]:[32]:[30.1.1.1]
     │   │   │        │                │       │
     │   │   │        │                │       └─ IP address
     │   │   │        │                └───────── IP length (bits)
     │   │   │        └────────────────────────── MAC address
     │   │   └─────────────────────────────────── MAC length (bits)
     │   └─────────────────────────────────────── Ethernet Tag
     └─────────────────────────────────────────── Ethernet Segment ID

# Type 3 Route Attributes:
[3]:[ESI]:[EthTag]:[IPlen]:[OriginatorIP]
[3]:[0]:[0]:[32]:[1.1.1.2]
     │   │   │        │
     │   │   │        └───────────────────────── VTEP IP
   en]:[MAC]:[IPlen]:[IP]
[2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]:[32]:[30.1.1.1]
     │   │   │        │                │       │
     │   │   │        │                │       └─ IP address
     │   │   │        │                └───────── IP length (bits)
     │   │   │        └────────────────────────── MAC address
     │   │   └─────────────────────────────────── MAC length (bits)
     │   └─────────────────────────────────────── Ethernet Tag
     └─────────────────────────────────────────── Ethernet Segment ID

# Type 3 Route Attributes:
[3]:[ESI]:[EthTag]:[IPlen]:[OriginatorIP]
[3]:[0]:[0]:[32]:[1.1.1.2]
     │   │   │        │
     │   │   │        └───────────────────────── VTEP IP
     │   │   └────────────────────────────────── IP length
     │   └────────────────────────────────────── Ethernet Tag
     └────────────────────────────────────────── Ethernet Segment ID
```

### Data Plane vs Control Plane Learning

**Traditional VXLAN (Part 2):**
```
MAC Learning = Data Plane (flooding)
BUM Traffic = Flooded to all VTEPs
Scalability = Limited
```

**BGP-EVPN (Part 3):**
```
MAC Learning = Control Plane (BGP)
BUM Traffic = Minimal (only necessary traffic)
Scalability = Excellent (BGP proven to millions of routes)
```

---

## 🎓 Learning Outcomes

1. **Data Center Architecture:**
   - Spine-leaf topology design
   - Benefits of Clos networks
   - Scalability considerations

2. **BGP-EVPN:**
   - Control plane for VXLAN
   - Route types (Type 2, Type 3)
   - MAC/IP advertisement

3. **Route Reflection:**
   - Scaling iBGP deployments
   - Route reflector hierarchy
   - Client-RR relationships

4. **OSPF Underlay:**
   - Loopback reachability
   - Fast convergence
   - Integration with BGP overlay

5. **Advanced Troubleshooting:**
   - BGP debugging
   - EVPN route analysis
   - Control/data plane separation

---

## 📚 Additional Resources

### RFCs
- [RFC 7432 - BGP MPLS-Based EVPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [RFC 4456 - BGP Route Reflection](https://datatracker.ietf.org/doc/html/rfc4456)
- [RFC 2328 - OSPF Version 2](https://datatracker.ietf.org/doc/html/rfc2328)

### Documentation
- [FRRouting BGP-EVPN](https://docs.frrouting.org/en/latest/evpn.html)
- [Cumulus Networks EVPN Guide](https://docs.nvidia.com/networking-ethernet-software/cumulus-linux/Network-Virtualization/Ethernet-Virtual-Private-Network-EVPN/)

### Articles
- [EVPN: The Next Generation of Network Virtualization](https://www.juniper.net/documentation/us/en/software/junos/evpn-vxlan/topics/concept/evpn-overview.html)
- [Understanding Route Reflection](https://www.cisco.com/c/en/us/support/docs/ip/border-gateway-protocol-bgp/13788-route-reflectors.html)

---

**For detailed theory on BGP-EVPN concepts, see [THEORY.md](../THEORY.md#part-3-bgp-evpn--data-center-fabric).**

**For global project overview, see [Main README](../README.md).**
