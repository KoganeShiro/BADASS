# BADASS - Comprehensive Theory Documentation

## 📚 Table of Contents

- [Part 1: GNS3 & Docker Fundamentals](#part-1-gns3--docker-fundamentals)
  - [Packet Routing Software](#packet-routing-software)
  - [BGPD Service](#bgpd-service)
  - [OSPFD Service](#ospfd-service)
  - [Routing Engine (Zebra)](#routing-engine-zebra)
  - [BusyBox](#busybox)
- [Part 2: VXLAN & Network Virtualization](#part-2-vxlan--network-virtualization)
  - [VXLAN vs VLAN](#vxlan-vs-vlan)
  - [Switch](#switch)
  - [Bridge](#bridge)
  - [Broadcast vs Multicast](#broadcast-vs-multicast)
- [Part 3: BGP-EVPN & Data Center Fabric](#part-3-bgp-evpn--data-center-fabric)
  - [BGP-EVPN](#bgp-evpn)
  - [Route Reflection](#route-reflection)
  - [VTEP (VXLAN Tunnel Endpoint)](#vtep-vxlan-tunnel-endpoint)
  - [VNI (VXLAN Network Identifier)](#vni-vxlan-network-identifier)
  - [Type 2 vs Type 3 Routes](#type-2-vs-type-3-routes)

---

## Part 1: GNS3 & Docker Fundamentals

### Packet Routing Software

**Definition:**
Packet routing software is a specialized application that determines the best path for data packets to travel from source to destination across networks. It implements routing protocols and maintains routing tables to make intelligent forwarding decisions.

**Key Functions:**
- **Routing Table Management:** Maintains a database of network routes
- **Path Selection:** Uses algorithms (like Dijkstra's SPF) to find optimal paths
- **Packet Forwarding:** Moves packets between network interfaces based on routing decisions
- **Protocol Implementation:** Supports multiple routing protocols (OSPF, BGP, IS-IS, RIP)

**In This Project:**
We use **FRRouting (FRR)**, an open-source routing software suite that provides:
- Multiple protocol support in a single package
- Command-line interface
- Integration with Linux networking stack
- Lightweight and containerizable

**Example Use Case:**
```bash
# FRR allows us to run multiple routing protocols simultaneously
router bgp 64512        # BGP for inter-AS routing
router ospf             # OSPF for intra-AS routing
```

---

### BGPD Service

**Definition:**
BGPD (Border Gateway Protocol Daemon) is the component of FRRouting that implements the BGP protocol. BGP is the routing protocol that makes the Internet work by exchanging routing information between autonomous systems.

**Why BGP Matters:**
- **Scalability:** Can handle hundreds of thousands of routes
- **Policy-Based Routing:** Allows fine-grained control over route selection
- **Inter-Domain Routing:** Connects different networks and autonomous systems
- **Path Vector Protocol:** Makes decisions based on paths, policies, and rule sets

**BGP Characteristics:**
- **Protocol:** TCP port 179
- **Neighbor Relationships:** Manually configured, not auto-discovered
- **Types:**
  - **eBGP:** External BGP between different autonomous systems
  - **iBGP:** Internal BGP within the same autonomous system

**In This Project:**
We use BGP in Part 3 for:
- Establishing neighbor relationships between VTEPs
- Distributing EVPN routes (MAC/IP information)
- Implementing route reflection to reduce full-mesh requirements

**Configuration Example:**
```bash
router bgp 64512
 bgp router-id 1.1.1.1
 neighbor 1.1.1.2 remote-as 64512        # iBGP peer
 address-family l2vpn evpn               # Enable EVPN address family
  neighbor 1.1.1.2 activate              # Activate EVPN for this neighbor
 exit-address-family
```

**BGP States:**
1. **Idle:** Initial state
2. **Connect:** Attempting TCP connection
3. **Active:** TCP connection established
4. **OpenSent:** OPEN message sent
5. **OpenConfirm:** OPEN message received
6. **Established:** Neighbors are exchanging routing information

---

### OSPFD Service

**Definition:**
OSPFD (Open Shortest Path First Daemon) implements the OSPF routing protocol, a link-state interior gateway protocol (IGP) used for routing within a single autonomous system.

**Why OSPF Matters:**
- **Fast Convergence:** Quickly adapts to network topology changes
- **Link-State Protocol:** Each router has complete topology map
- **Hierarchical Design:** Uses areas to segment large networks
- **Metric:** Uses cost based on interface bandwidth

**OSPF Characteristics:**
- **Protocol:** IP protocol 89 (not TCP/UDP)
- **Algorithm:** Dijkstra's Shortest Path First (SPF)
- **Hello Packets:** Discovers and maintains neighbor relationships (every 10s)
- **LSAs (Link State Advertisements):** Distribute topology information

**In This Project:**
OSPF serves as the **underlay network** in Part 3:
- Provides IP reachability between VTEPs
- Ensures loopback addresses are reachable
- Creates foundation for BGP-EVPN overlay

**Configuration Example:**
```bash
router ospf
 ospf router-id 1.1.1.1
 network 1.1.1.1/32 area 0      # Advertise loopback
 network 10.1.1.0/30 area 0     # Advertise point-to-point links
```

**OSPF Areas:**
- **Area 0 (Backbone):** Core area, all other areas must connect to it
- **Standard Areas:** Normal areas containing inter-area routes
- **Stub Areas:** Don't receive external routes

**OSPF vs BGP:**
| Feature | OSPF | BGP |
|---------|------|-----|
| Type | Link-State IGP | Path Vector EGP |
| Scope | Within AS | Between AS |
| Convergence | Fast | Slower |
| Scalability | Medium | Very High |
| Metric | Cost (bandwidth) | Policies, AS-path |

---

### Routing Engine (Zebra)

**Definition:**
Zebra is the core routing manager in FRRouting that acts as an abstraction layer between routing protocols and the kernel routing table. It's the "central brain" that coordinates all routing daemons.

**Architecture:**

```
┌─────────────────────────────────────────────┐
│           Application Layer                 │
│    (BGPD, OSPFD, IS-IS, RIPd, etc.)         │
└──────────────┬──────────────────────────────┘
               │ ZAPI (Zebra API)
┌──────────────▼──────────────────────────────┐
│            ZEBRA Daemon                     │
│  - Route Selection                          │
│  - FIB Management                           │
│  - Interface Management                     │
└──────────────┬──────────────────────────────┘
               │ Netlink
┌──────────────▼──────────────────────────────┐
│         Linux Kernel                        │
│    - Routing Table (FIB)                    │
│    - Network Interfaces                     │
└─────────────────────────────────────────────┘
```

**Key Functions:**
1. **Route Arbitration:** Chooses best routes when multiple protocols offer paths
2. **FIB Management:** Installs/removes routes in kernel routing table
3. **Interface Management:** Monitors interface state changes
4. **Protocol Coordination:** Provides common API for all routing protocols

**Administrative Distance (Route Preference):**
When multiple protocols provide the same route, Zebra uses administrative distance:
- **Connected:** 0 (directly connected interfaces)
- **Static:** 1
- **OSPF:** 110
- **IS-IS:** 115
- **RIP:** 120
- **BGP:** 200 (lowest priority, but most scalable)

**In This Project:**
Zebra automatically:
- Manages routes learned from OSPF (underlay)
- Installs BGP routes into kernel
- Handles interface state changes
- Coordinates between all FRR daemons

**Configuration:**
Zebra typically requires minimal configuration:
```bash
# Usually just specify interfaces
interface eth0
 ip address 10.1.1.1/30
!
interface lo
 ip address 1.1.1.1/32
```

---

### BusyBox

**Definition:**
BusyBox is a software suite that combines tiny versions of many common UNIX utilities into a single small executable. It's often called "The Swiss Army Knife of Embedded Linux."

**Why BusyBox in Docker:**
- **Size:** Single executable ~1-2 MB vs hundreds of MB for full distributions
- **Functionality:** Provides ~400 common commands
- **Efficiency:** Perfect for container environments
- **Simplicity:** Minimal dependencies

**Common Commands in BusyBox:**
```bash
# Networking
ping, ifconfig, route, netstat, telnet, wget

# File Operations  
ls, cp, mv, rm, cat, grep, sed, awk

# System
ps, top, kill, mount, df, free

# Text Processing
vi, less, head, tail, sort, uniq
```

**In This Project:**
BusyBox is used in the **host containers** (Part 1) to:
- Keep container size minimal
- Provide basic networking tools (ping, ifconfig)
- Allow simple connectivity testing
- Reduce resource consumption

**BusyBox vs Full Linux:**
| Aspect | BusyBox | Full Linux |
|--------|---------|------------|
| Size | ~1-2 MB | ~100-500 MB |
| Commands | ~400 | ~2000+ |
| Features | Essential only | Full-featured |
| Use Case | Embedded, Containers | Desktop, Servers |

**Dockerfile Example:**
```dockerfile
FROM alpine:latest
# Alpine uses BusyBox by default

# Install additional networking tools
RUN apk add --no-cache iproute2 busybox-extras

CMD ["/bin/sh"]
```

**Limitations:**
- Reduced functionality in each command
- No bash (only ash/sh shell)
- Limited GNU extensions
- Simpler options for many utilities

---

## Part 2: VXLAN & Network Virtualization

### VXLAN vs VLAN

**VLAN (Virtual Local Area Network):**

**Definition:**
VLAN is a Layer 2 technology that logically segments a physical network into multiple isolated broadcast domains.

**Characteristics:**
- **Identifier:** 12-bit VLAN ID (4,096 VLANs maximum)
- **Encapsulation:** 802.1Q tag (4 bytes added to Ethernet frame)
- **Scope:** Limited to Layer 2 domain
- **Scalability:** Maximum 4,094 usable VLANs (1 and 4095 reserved)

**VLAN Frame:**
```
┌──────────┬─────┬────────┬──────────┬──────┬─────┐
│ Dst MAC  │ Src │ 802.1Q │ EtherType│ Data │ FCS │
│ (6 bytes)│ MAC │ Tag    │ (2 bytes)│      │     │
│          │(6B) │ (4B)   │          │      │     │
└──────────┴─────┴────────┴──────────┴──────┴─────┘
              ↑
         VLAN ID (12 bits)
```

**VXLAN (Virtual Extensible LAN):**

**Definition:**
VXLAN is a Layer 2 overlay network technology that encapsulates Layer 2 Ethernet frames within Layer 3 UDP packets, enabling network virtualization at scale.

**Characteristics:**
- **Identifier:** 24-bit VNI (16 million networks)
- **Encapsulation:** MAC-in-UDP (50 bytes overhead)
- **Scope:** Works across Layer 3 networks
- **Scalability:** 16,777,216 virtual networks

**VXLAN Packet Structure:**
```
┌──────────────────────────────────────────────────────────┐
│                    Outer Ethernet Header                 │
│  Dst MAC (VTEP) | Src MAC (VTEP) | EtherType (0x0800)    │
├──────────────────────────────────────────────────────────┤
│                      Outer IP Header                     │
│  Src IP (VTEP) | Dst IP (VTEP) | Protocol (17 = UDP)     │
├──────────────────────────────────────────────────────────┤
│                      Outer UDP Header                    │
│  Src Port (Random) | Dst Port (4789 - VXLAN)             │
├──────────────────────────────────────────────────────────┤
│                       VXLAN Header                       │
│  Flags | Reserved | VNI (24-bit) | Reserved              │
├──────────────────────────────────────────────────────────┤
│                   Original Ethernet Frame                │
│  Inner Dst MAC | Inner Src MAC | Payload                 │
└──────────────────────────────────────────────────────────┘
```

**Key Differences:**

| Feature | VLAN | VXLAN |
|---------|------|-------|
| **Layer** | Layer 2 only | Layer 2 over Layer 3 |
| **Scale** | 4,096 VLANs | 16 million VNs |
| **Scope** | Single L2 domain | Across L3 networks |
| **Encapsulation** | 802.1Q tag | MAC-in-UDP |
| **Overhead** | 4 bytes | 50 bytes |
| **Geographic Reach** | Limited | Data center scale |
| **Multi-tenancy** | Limited | Excellent |

**Why VXLAN is Superior for Data Centers:**

1. **Scalability:** 16M networks vs 4K VLANs
2. **Flexibility:** Works over existing IP infrastructure
3. **Multi-tenancy:** Isolated networks for different customers
4. **Cloud-Ready:** Enables network virtualization in cloud environments
5. **Geographic Distribution:** Extends L2 across data centers

**In This Project:**
Part 2 demonstrates VXLAN by:
- Creating VXLAN tunnels between hosts
- Using VNI 10 to identify virtual network
- Bridging VXLAN interface with local interface
- Testing Layer 2 connectivity over Layer 3 network

---

### Switch

**Definition:**
A network switch is a Layer 2 device that forwards Ethernet frames between devices on the same network based on MAC addresses.

**How Switches Work:**

1. **Learning:** When a frame arrives, the switch learns the source MAC address and the port it came from
2. **Forwarding:** Switch looks up destination MAC in forwarding table
3. **Flooding:** If destination unknown, frame is sent to all ports except source
4. **Aging:** MAC addresses are removed after timeout (default: 300s)

**MAC Address Table (CAM Table):**
```
MAC Address         Port    VLAN    Age
00:11:22:33:44:55   1       10      45s
AA:BB:CC:DD:EE:FF   2       10      120s
11:22:33:44:55:66   3       20      30s
```

**Switch Functions:**
- **Unicast:** Forwards to specific port
- **Broadcast:** Sends to all ports in VLAN
- **Multicast:** Sends to specific group of ports

**Switch Types:**

1. **Unmanaged Switch:**
   - Plug-and-play
   - No configuration
   - Fixed operation

2. **Managed Switch:**
   - VLAN support
   - Port mirroring
   - QoS features
   - Remote management

3. **Layer 3 Switch:**
   - Routing capabilities
   - Inter-VLAN routing
   - Higher performance

**In This Project:**
Physical switches are simulated, but the **bridge** (br0) acts as a virtual switch:
- Connects local interface (eth1) with VXLAN tunnel
- Maintains MAC address forwarding table
- Forwards frames between local and remote networks

**Virtual Switch Behavior:**
```bash
# Bridge acts as switch, connecting:
# - eth1 (local network)
# - vxlan10 (tunnel to remote site)

ip link add name br0 type bridge
ip link set eth1 master br0      # Add local interface
ip link set vxlan10 master br0   # Add VXLAN tunnel
```

---

### Bridge

**Definition:**
A Linux bridge is a virtual Layer 2 device that connects multiple network interfaces, operating like a software-based network switch. It forwards traffic between interfaces based on MAC addresses.

**Bridge vs Switch:**
- **Bridge:** Software implementation (kernel module)
- **Switch:** Hardware implementation (ASIC)
- **Functionality:** Essentially the same at Layer 2

**Bridge Components:**

```
┌────────────────────────────────────────────┐
│            Linux Bridge (br0)              │
│                                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   eth1   │  │ vxlan10  │  │   eth2   │  │
│  └────┬─────┘  └─────┬────┘  └─────┬────┘  │
└───────┼──────────────┼─────────────┼───────┘
        │              │             │
     Local         VXLAN          Other
     Network       Tunnel         Interface
```

**Bridge Operations:**

1. **Learning:**
```bash
# Bridge learns MAC addresses automatically
bridge fdb show br br0
```

2. **Forwarding:**
```bash
# Forwards frames based on destination MAC
# Floods if destination unknown
```

3. **Filtering:**
```bash
# Can filter based on MAC/VLAN
bridge vlan add vid 10 dev eth1
```

**In This Project (Part 2):**

We create a bridge to connect:
- **eth1:** Local network interface (to hosts)
- **vxlan10:** VXLAN tunnel interface (to remote site)

**Configuration Steps:**
```bash
# 1. Create bridge
ip link add name br0 type bridge
ip link set br0 up

# 2. Add local interface
ip link set eth1 master br0
ip link set eth1 up

# 3. Add VXLAN interface
ip link set vxlan10 master br0
ip link set vxlan10 up
```

**Bridge Forwarding Database (FDB):**
```bash
# View FDB entries
bridge fdb show dev vxlan10

# Output example:
00:00:00:00:00:00 dst 192.168.100.2 self permanent
52:54:00:12:34:56 dst 192.168.100.2 self
```

**FDB Entry Types:**
- **Dynamic:** Learned automatically (aged out)
- **Static:** Manually configured (permanent)
- **Permanent:** System-created (never aged)

**Bridge vs Router:**
| Feature | Bridge | Router |
|---------|--------|--------|
| Layer | Layer 2 | Layer 3 |
| Forwarding | MAC address | IP address |
| Broadcasts | Forwards | Blocks |
| Subnets | Single subnet | Multiple subnets |

---

### Broadcast vs Multicast

**Broadcast:**

**Definition:**
A one-to-all communication method where a single packet is sent to every device on the network segment.

**Characteristics:**
- **Destination:** All devices in broadcast domain
- **MAC Address:** FF:FF:FF:FF:FF:FF
- **IP Address:** Network broadcast address (e.g., 192.168.1.255)
- **Efficiency:** Low (wastes bandwidth)

**Example:**
```
┌─────────┐
│ Sender  │
└────┬────┘
     │ Broadcast (FF:FF:FF:FF:FF:FF)
     ├──────────┬──────────┬──────────┐
     ▼          ▼          ▼          ▼
┌─────────┐┌─────────┐┌─────────┐┌─────────┐
│ Host 1  ││ Host 2  ││ Host 3  ││ Host 4  │
│ Receives││ Receives││ Receives││ Receives│
└─────────┘└─────────┘└─────────┘└─────────┘
```

**Use Cases:**
- ARP requests (finding MAC from IP)
- DHCP discovery
- Network announcements

**Problems:**
- **Bandwidth waste:** All devices process packet
- **Scalability issues:** Grows with network size
- **Security concerns:** Information visible to all

**Multicast:**

**Definition:**
A one-to-many communication method where a single packet is sent to a specific group of interested devices.

**Characteristics:**
- **Destination:** Only subscribed group members
- **MAC Address:** 01:00:5E:xx:xx:xx (IPv4 multicast)
- **IP Address:** 224.0.0.0 to 239.255.255.255
- **Efficiency:** High (targeted delivery)

**Example:**
```
┌─────────┐
│ Sender  │
└────┬────┘
     │ Multicast (01:00:5E:01:01:01)
     ├──────────┬──────────┐
     ▼          ▼          │
┌─────────┐┌─────────┐     │       ┌─────────┐
│ Host 1  ││ Host 2  │     │       │ Host 4  │
│(Subscrib││(Subscrib│     └────X──│(Not in  │
│  ed)    ││  ed)    │             │  group) │
└─────────┘└─────────┘             └─────────┘
     ▲          ▲
     └──────────┘
   Multicast Group
```

**Multicast Groups:**
- **Registration:** Hosts join with IGMP (Internet Group Management Protocol)
- **Group Address:** Each group has unique multicast IP
- **Membership:** Dynamic (hosts can join/leave)

**Common Multicast Addresses:**
- **224.0.0.1:** All hosts on subnet
- **224.0.0.2:** All routers on subnet
- **224.0.0.5:** OSPF routers
- **224.0.0.9:** RIPv2 routers
- **239.x.x.x:** Organization-local scope

**VXLAN and Multicast:**

In VXLAN dynamic mode (not used in this project), multicast is used for:
- **VTEP Discovery:** Finding other VTEPs in the network
- **BUM Traffic:** Broadcast, Unknown unicast, Multicast forwarding

**Configuration Example:**
```bash
# VXLAN with multicast group
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  group 239.1.1.1 \      # Multicast group
  dstport 4789
```

**Comparison:**

| Feature | Broadcast | Multicast |
|---------|-----------|-----------|
| **Scope** | All devices | Group members only |
| **Efficiency** | Low | High |
| **Scalability** | Poor | Good |
| **Registration** | Not needed | IGMP join |
| **Bandwidth** | Wastes bandwidth | Optimized |
| **Examples** | ARP, DHCP | IPTV, Routing protocols |

**In This Project:**
Part 2 uses **unicast VXLAN** (static mode):
- Each VXLAN tunnel has specific remote IP
- No multicast group needed
- Manual FDB entries for forwarding
- Simpler configuration for learning

**Why Static over Multicast:**
- **Simplicity:** Easier to understand and configure
- **Control:** Explicit tunnel endpoints
- **No IGMP:** Doesn't require multicast routing
- **Predictable:** No auto-discovery complexity

---

## Part 3: BGP-EVPN & Data Center Fabric

### BGP-EVPN

**Definition:**
BGP-EVPN (Border Gateway Protocol Ethernet VPN) is a standards-based control plane for VXLAN that uses BGP to distribute MAC and IP address reachability information across the network fabric.

**Why BGP-EVPN?**

Traditional VXLAN has challenges:
- **Flooding:** BUM traffic requires multicast or head-end replication
- **Learning:** MAC addresses learned via data plane flooding
- **Scale:** Inefficient for large deployments

BGP-EVPN solves these by:
- **Control Plane Learning:** MAC/IP learned via BGP, not flooding
- **Reduced Flooding:** Only necessary BUM traffic
- **Scalability:** BGP proven to scale to millions of routes
- **Multi-tenancy:** VRF support for tenant isolation

**BGP-EVPN Architecture:**

```
┌─────────────────────────────────────────────────────┐
│              BGP-EVPN Control Plane                 │
│   (MAC/IP Routes, VTEP Discovery, ARP Suppression)  │
└───────────┬─────────────────────────────┬───────────┘
            │                             │
┌───────────▼──────┐           ┌──────────▼──────────┐
│     VTEP 1       │           │      VTEP 2         │
│  (1.1.1.2)       │           │   (1.1.1.3)         │
└───────────┬──────┘           └──────────┬──────────┘
            │                             │
┌───────────▼─────────────────────────────▼───────────┐
│              VXLAN Data Plane                       │
│         (Encapsulated L2 over L3 Network)           │
└─────────────────────────────────────────────────────┘
```

**BGP-EVPN Components:**

1. **Address Family:** L2VPN EVPN
```bash
router bgp 64512
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
 exit-address-family
```

2. **Route Types:** Various EVPN route types (see Type 2/3 below)

3. **Route Targets:** Control route distribution
```bash
vni 10
 rd 1.1.1.2:10
 route-target import 64512:10
 route-target export 64512:10
```

**EVPN Route Distinguisher (RD):**
- Makes routes unique across VNIs
- Format: ASN:nn or IP:nn
- Example: 1.1.1.2:10

**EVPN Route Target (RT):**
- Controls route import/export
- Enables multi-tenancy
- Example: 64512:10

**BGP-EVPN Benefits:**

1. **MAC Learning in Control Plane:**
   - No data plane flooding
   - Faster convergence
   - Better scale

2. **ARP Suppression:**
   - VTEP responds to ARP locally
   - Reduces broadcast traffic
   - Improves performance

3. **Host Mobility:**
   - MAC moves detected via BGP
   - Automatic update across fabric
   - Minimizes disruption

4. **Multi-tenancy:**
   - VNI-based isolation
   - Route target filtering
   - Separate routing tables

**In This Project:**
Part 3 implements BGP-EVPN with:
- Route reflector for scalability
- Type 2 routes for MAC/IP advertisement
- Type 3 routes for VTEP discovery
- OSPF underlay for IP reachability

**Configuration Example:**
```bash
# Enable EVPN on VTEP
router bgp 64512
 neighbor 1.1.1.1 remote-as 64512
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni         # Advertise all local VNIs
 exit-address-family
```

---

### Route Reflection

**The Problem: iBGP Full Mesh**

In traditional iBGP, every router must peer with every other router (full mesh):

```
Number of iBGP sessions = n(n-1)/2

For 4 routers: 4(3)/2 = 6 sessions
For 10 routers: 10(9)/2 = 45 sessions  
For 100 routers: 100(99)/2 = 4,950 sessions ❌
```

**Full Mesh Diagram:**
```
        R1 ───────── R2
        │  ╲      ╱  │
        │    ╲  ╱    │
        │     ╳      │
        │    ╱  ╲    │
        │  ╱      ╲  │
        R3 ───────── R4

All routers must peer with all others!
```

**The Solution: Route Reflection**

Route Reflection breaks the full-mesh requirement by designating certain routers as **Route Reflectors (RR)** that reflect routes between clients.

**Route Reflector Hierarchy:**

```
                  ┌──────────────┐
                  │Route Reflector│
                  │  (RR)        │
                  │  1.1.1.1     │
                  └───────┬──────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐   ┌─────▼─────┐   ┌───▼───────┐
    │  Client 1 │   │  Client 2 │   │  Client 3 │
    │  VTEP-2   │   │  VTEP-3   │   │  VTEP-4   │
    │ 1.1.1.2   │   │ 1.1.1.3   │   │ 1.1.1.4   │
    └───────────┘   └───────────┘   └───────────┘

Clients only peer with RR (3 sessions vs 6!)
```

**Route Reflector Roles:**

1. **Route Reflector (RR):**
   - Receives routes from clients
   - Reflects routes to other clients
   - Maintains full BGP mesh with other RRs

2. **Route Reflector Client:**
   - Peers only with RR
   - Receives reflected routes
   - Doesn't need to know about other clients

3. **Non-Client Peer:**
   - Full mesh with RRs
   - For redundancy/scale

**Route Reflection Rules:**

1. **Route from client → Reflect to:**
   - All other clients
   - All non-client peers

2. **Route from non-client peer → Reflect to:**
   - All clients only

3. **Route from eBGP peer → Reflect to:**
   - All clients
   - All non-client peers

**Configuration:**

**On Route Reflector (router-1):**
```bash
router bgp 64512
 bgp router-id 1.1.1.1
 neighbor vtep-clients peer-group
 neighbor vtep-clients remote-as 64512
 neighbor 1.1.1.2 peer-group vtep-clients
 neighbor 1.1.1.3 peer-group vtep-clients
 neighbor 1.1.1.4 peer-group vtep-clients
 !
 address-family l2vpn evpn
  neighbor vtep-clients activate
  neighbor vtep-clients route-reflector-client  # Key!
 exit-address-family
```

**On Client (VTEP-2):**
```bash
router bgp 64512
 bgp router-id 1.1.1.2
 neighbor 1.1.1.1 remote-as 64512    # Only peer with RR
 !
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
```

**BGP Attributes for Loop Prevention:**

- **Originator ID:** Original router that advertised route
- **Cluster List:** List of RRs the route passed through

**Scalability Comparison:**

| Topology | 4 Routers | 10 Routers | 100 Routers |
|----------|-----------|------------|-------------|
| Full Mesh | 6 sessions | 45 | 4,950 |
| Route Reflection | 3 sessions | 9 | 99 |

**In This Project:**
- **router-1:** Acts as route reflector
- **VTEP-2, VTEP-3, VTEP-4:** Route reflector clients
- Reduces complexity from 6 to 3 BGP sessions
- Demonstrates scalable data center design

---

### VTEP (VXLAN Tunnel Endpoint)

**Definition:**
A VTEP (VXLAN Tunnel Endpoint) is a device that performs VXLAN encapsulation and decapsulation. It's the entry and exit point for VXLAN tunnels.

**VTEP Functions:**

1. **Encapsulation:**
   - Receives original Ethernet frame
   - Adds VXLAN header (with VNI)
   - Adds UDP header (port 4789)
   - Adds outer IP header (VTEP IPs)
   - Adds outer Ethernet header

2. **Decapsulation:**
   - Receives VXLAN packet
   - Removes outer headers
   - Extracts original frame
   - Forwards to local destination

**VTEP Architecture:**

```
┌─────────────────────────────────────────────────────┐
│                    VTEP Device                      │
│                                                     │
│  ┌────────────────────────────────────────────┐     │
│  │          Control Plane (BGP-EVPN)          │     │
│  │  - Learn remote MAC addresses              │     │
│  │  - Exchange reachability info              │     │
│  └───────────────┬────────────────────────────┘     │
│                  │                                  │
│  ┌───────────────▼────────────────────────────┐     │
│  │           Data Plane (VXLAN)               │     │
│  │  - Encapsulation/Decapsulation             │     │
│  │  - Forwarding table (MAC→VTEP mapping)     │     │
│  └───────┬──────────────────────────┬─────────┘     │
│          │                          │               │
└──────────┼──────────────────────────┼───────────────┘
           │                          │
      ┌────▼────┐              ┌─────▼──────┐
      │ Local   │              │  Tunnel    │
      │ Network │              │  Interface │
      │(eth1)   │              │  (vxlan10) │
      └─────────┘              └────────────┘
```

**VTEP Types:**

1. **Hardware VTEP:**
   - Physical switches (Cisco Nexus, Arista, etc.)
   - ASIC-based forwarding
   - High performance
   - Expensive

2. **Software VTEP:**
   - Linux kernel VXLAN
   - Hypervisor-based (Open vSwitch)
   - Flexible
   - Cost-effective

**In This Project:**
We use **software VTEPs** implemented with Linux:
- Each VTEP has unique loopback IP (1.1.1.x)
- OSPF provides reachability between VTEPs
- BGP-EVPN distributes MAC/IP information
- VXLAN interface (vxlan10) performs encap/decap

**VTEP Configuration Example:**
```bash
# 1. Create VXLAN interface
ip link add vxlan10 type vxlan \
  id 10 \                        # VNI
  local 1.1.1.2 \                # Local VTEP IP (loopback)
  dstport 4789 \                 # VXLAN UDP port
  nolearning                     # Disable MAC learning (use BGP)

# 2. Add to bridge
ip link set vxlan10 master br0
ip link set vxlan10 up

# 3. Configure BGP-EVPN (in FRR)
router bgp 64512
 address-family l2vpn evpn
  advertise-all-vni              # Advertise VNI 10
 exit-address-family
```

**VTEP Forwarding Table:**

When BGP-EVPN is used, VTEP maintains:
```bash
# MAC to VTEP mapping
MAC Address         VNI   Remote VTEP   Type
aa:bb:cc:dd:ee:01   10    1.1.1.3       BGP-EVPN
aa:bb:cc:dd:ee:02   10    1.1.1.4       BGP-EVPN

# View with:
bridge fdb show dev vxlan10
```

**VTEP Communication Flow:**

1. **Local host sends frame:**
   - Host-1 → VTEP-2 (local)

2. **VTEP-2 lookup:**
   - Checks MAC table
   - Finds destination MAC belongs to VTEP-3

3. **Encapsulation:**
   - Original frame wrapped in VXLAN
   - Outer IP: 1.1.1.2 → 1.1.1.3

4. **Underlay routing:**
   - OSPF routes packet through network

5. **VTEP-3 receives:**
   - Decapsulates packet
   - Forwards original frame to Host-2

---

### VNI (VXLAN Network Identifier)

**Definition:**
VNI (VXLAN Network Identifier) is a 24-bit identifier in the VXLAN header that uniquely identifies a virtual network segment, similar to how VLAN IDs identify VLANs.

**VNI Characteristics:**

- **Size:** 24 bits
- **Range:** 0 to 16,777,215 (16 million virtual networks)
- **Purpose:** Network segmentation and isolation
- **Scope:** Global across VXLAN fabric

**VNI Header Position:**

```
VXLAN Header (8 bytes):
┌────────┬──────────┬─────────────────────┬──────────┐
│ Flags  │ Reserved │    VNI (24-bit)     │ Reserved │
│ (8bit) │ (24bit)  │                     │ (8bit)   │
└────────┴──────────┴─────────────────────┴──────────┘
   0x08                    VNI = 10
```

**VNI vs VLAN:**

| Feature | VLAN ID | VNI |
|---------|---------|-----|
| **Size** | 12 bits | 24 bits |
| **Range** | 4,096 | 16,777,216 |
| **Scope** | L2 domain | Across L3 |
| **Standard** | 802.1Q | RFC 7348 |
| **Overhead** | 4 bytes | 50 bytes |

**VNI Use Cases:**

1. **Multi-Tenancy:**
```
VNI 10 → Tenant A (Production)
VNI 20 → Tenant B (Development)
VNI 30 → Tenant C (Testing)
```

2. **Service Segmentation:**
```
VNI 100 → Web Tier
VNI 200 → Application Tier
VNI 300 → Database Tier
```

3. **Geographic Separation:**
```
VNI 1000 → Data Center 1
VNI 2000 → Data Center 2
VNI 3000 → Data Center 3
```

**VNI Configuration:**

**Method 1: Single VNI (Used in this project)**
```bash
# Create VXLAN with VNI 10
ip link add vxlan10 type vxlan id 10 \
  local 1.1.1.2 \
  dstport 4789
```

**Method 2: Multiple VNIs**
```bash
# VNI 10
ip link add vxlan10 type vxlan id 10 local 1.1.1.2 dstport 4789
ip link set vxlan10 master br10

# VNI 20
ip link add vxlan20 type vxlan id 20 local 1.1.1.2 dstport 4789
ip link set vxlan20 master br20
```

**Method 3: VLAN-VNI Mapping (Advanced)**
```bash
# Map VLAN IDs to VNIs
vlan 10 → VNI 10000
vlan 20 → VNI 20000
```

**VNI in BGP-EVPN:**

BGP-EVPN uses VNI for:
- **Route Distribution:** Routes tagged with VNI
- **Filtering:** Import/export based on VNI
- **Isolation:** Traffic separation

**FRR Configuration:**
```bash
# Advertise VNI
router bgp 64512
 address-family l2vpn evpn
  advertise-all-vni       # Advertise all local VNIs
 exit-address-family

# Or specific VNI
vni 10
 rd 1.1.1.2:10           # Route Distinguisher
 route-target import 64512:10
 route-target export 64512:10
```

**VNI in Routing Tables:**

```bash
# View EVPN VNIs
show evpn vni

# Output:
VNI        Type VxLAN IF        # MACs   # ARPs   # Remote VTEPs  Tenant VRF
10         L2   vxlan10         2        2        2                default

# View VNI details
show evpn vni 10 detail

# Output:
VNI: 10
 Type: L2
 Tenant VRF: default
 Local Vtep Ip: 1.1.1.2
 Remote Vteps:
  1.1.1.3
  1.1.1.4
```

**In This Project:**
- **VNI 10:** Used for all project parts
- **Single VNI:** Simplifies configuration
- **L2 Segment:** Hosts in same virtual network
- **EVPN Distribution:** VNI 10 routes exchanged via BGP

---

### Type 2 vs Type 3 Routes

BGP-EVPN uses different route types to distribute various kinds of information across the network.

---

#### Type 2 Routes: MAC/IP Advertisement

**Definition:**
Type 2 routes advertise MAC addresses (and optionally IP addresses) along with their associated VNI and VTEP location.

**Purpose:**
- **MAC Learning:** VTEPs learn remote MAC addresses via BGP
- **ARP Suppression:** IP-to-MAC binding distributed
- **Unicast Forwarding:** Enables direct VTEP-to-VTEP communication
- **Eliminates Flooding:** No need to flood for MAC learning

**Type 2 Route Components:**

```
┌────────────────────────────────────────────────────┐
│           BGP-EVPN Type 2 Route                    │
├────────────────────────────────────────────────────┤
│ Route Distinguisher (RD):  1.1.1.2:10              │
│ VNI:                       10                      │
│ MAC Address:               aa:bb:cc:dd:ee:01       │
│ IP Address (optional):     30.1.1.1                │
│ Next Hop (VTEP IP):        1.1.1.2                 │
│ Route Target:              64512:10                │
└────────────────────────────────────────────────────┘
```

**What Type 2 Tells You:**
> "MAC address aa:bb:cc:dd:ee:01 (with IP 30.1.1.1) is reachable via VTEP 1.1.1.2 in VNI 10"

**Type 2 Route Advertisement:**

```
Host-1 (30.1.1.1, MAC: aa:bb:cc:dd:ee:01)
     │
     │ Connected to
     ▼
VTEP-2 (1.1.1.2) ─────BGP Type 2 Route─────→ Route Reflector
                                                      │
                      ┌───────────────────────────────┤
                      │                               │
                      ▼                               ▼
                  VTEP-3                          VTEP-4
                (1.1.1.3)                       (1.1.1.4)

All VTEPs now know:
"To reach MAC aa:bb:cc:dd:ee:01, send to VTEP 1.1.1.2"
```

**Type 2 in Practice:**

1. **Host connects to VTEP:**
   - Host-1 (30.1.1.1) sends first packet
   - VTEP-2 learns MAC locally

2. **VTEP advertises via BGP:**
   - Creates Type 2 route
   - Sends to route reflector
   - Contains MAC, IP, VNI, VTEP info

3. **Other VTEPs receive route:**
   - Install in forwarding table
   - Future packets to this MAC sent directly
   - No flooding needed

**View Type 2 Routes:**
```bash
# On any VTEP
vtysh -c "show bgp l2vpn evpn"

# Example output:
*> [2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]
    1.1.1.2                            0 64512 i
    RT:64512:10 ET:8
    
*> [2]:[0]:[0]:[48]:[aa:bb:cc:dd:ee:01]:[32]:[30.1.1.1]
    1.1.1.2                            0 64512 i
    RT:64512:10 ET:8
```

**Type 2 Benefits:**
- ✅ No MAC flooding
- ✅ Faster convergence
- ✅ Better scalability
- ✅ Integrated ARP suppression
- ✅ Host mobility support

---

#### Type 3 Routes: Inclusive Multicast Ethernet Tag

**Definition:**
Type 3 routes advertise VTEP membership in a VNI, enabling VTEP discovery and BUM (Broadcast, Unknown unicast, Multicast) traffic handling.

**Purpose:**
- **VTEP Discovery:** VTEPs learn about other VTEPs in same VNI
- **BUM Traffic:** Enables broadcast/multicast forwarding
- **Tunnel Establishment:** Creates tunnels between VTEPs
- **Overlay Membership:** Indicates participation in VNI

**Type 3 Route Components:**

```
┌────────────────────────────────────────────────────┐
│           BGP-EVPN Type 3 Route                    │
├────────────────────────────────────────────────────┤
│ Route Distinguisher (RD):  1.1.1.2:10              │
│ VNI:                       10                      │
│ Originating Router IP:     1.1.1.2                 │
│ Route Target:              64512:10                │
└────────────────────────────────────────────────────┘
```

**What Type 3 Tells You:**
> "VTEP 1.1.1.2 is active and participating in VNI 10. Use this IP for BUM traffic."

**Type 3 Route Advertisement:**

```
VTEP-2 (1.1.1.2) ─────BGP Type 3 Route─────→ Route Reflector
                    "I'm in VNI 10!"                │
                                    ┌───────────────┴───────────────┐
                                    │                               │
                                    ▼                               ▼
                                VTEP-3                          VTEP-4
                              (1.1.1.3)                       (1.1.1.4)

All VTEPs know:
- VTEP-2 (1.1.1.2) is in VNI 10
- VTEP-3 (1.1.1.3) is in VNI 10
- VTEP-4 (1.1.1.4) is in VNI 10
→ Establish tunnels between all
```

**Type 3 in Practice:**

1. **VTEP comes online:**
   - Configures VNI 10
   - Creates VXLAN interface

2. **Advertises Type 3 route:**
   - "I'm VTEP 1.1.1.2, I'm in VNI 10"
   - Sent via BGP to route reflector
   - Distributed to all other VTEPs

3. **Other VTEPs receive:**
   - Learn about new VTEP
   - Establish VXLAN tunnel
   - Add to BUM replication list

**View Type 3 Routes:**
```bash
# On any VTEP
vtysh -c "show bgp l2vpn evpn type multicast"

# Example output:
*> [3]:[0]:[32]:[1.1.1.2]
    1.1.1.2                            0 64512 i
    RT:64512:10 ET:8
    
*> [3]:[0]:[32]:[1.1.1.3]
    1.1.1.3                            0 64512 i
    RT:64512:10 ET:8
    
*> [3]:[0]:[32]:[1.1.1.4]
    1.1.1.4                            0 64512 i
    RT:64512:10 ET:8
```

**Type 3 and BUM Traffic:**

When broadcast/multicast is sent:
1. Local VTEP receives BUM frame
2. Checks Type 3 routes for VNI
3. Replicates to all remote VTEPs in list
4. Each remote VTEP decapsulates and floods locally

---

#### Type 2 vs Type 3 Comparison

| Feature | Type 2 Route | Type 3 Route |
|---------|-------------|-------------|
| **Purpose** | MAC/IP advertisement | VTEP discovery |
| **Contains** | MAC, IP, VNI, VTEP | VNI, VTEP IP |
| **Frequency** | Per host/MAC | Per VTEP per VNI |
| **Updates** | When MAC learned/moved | When VTEP joins VNI |
| **Use** | Unicast forwarding | BUM traffic, discovery |
| **Quantity** | Many (per host) | Few (per VTEP) |

**Example Scenario:**

```
Data Center with 3 VTEPs, 6 hosts, VNI 10:

Type 3 Routes:
├─ VTEP-2 (1.1.1.2) in VNI 10    } 3 routes total
├─ VTEP-3 (1.1.1.3) in VNI 10    } (one per VTEP)
└─ VTEP-4 (1.1.1.4) in VNI 10    }

Type 2 Routes:
├─ Host-1 (MAC:aa:bb:cc:dd:ee:01, IP:30.1.1.1) at VTEP-2  }
├─ Host-2 (MAC:aa:bb:cc:dd:ee:02, IP:30.1.1.2) at VTEP-2  }
├─ Host-3 (MAC:aa:bb:cc:dd:ee:03, IP:30.1.1.3) at VTEP-3  } 6 routes
├─ Host-4 (MAC:aa:bb:cc:dd:ee:04, IP:30.1.1.4) at VTEP-3  } (one per host)
├─ Host-5 (MAC:aa:bb:cc:dd:ee:05, IP:30.1.1.5) at VTEP-4  }
└─ Host-6 (MAC:aa:bb:cc:dd:ee:06, IP:30.1.1.6) at VTEP-4  }
```

**In This Project:**

You should see:
- **3 Type 3 routes:** One from each VTEP (router-2, router-3, router-4)
- **Multiple Type 2 routes:** One for each host's MAC address
- **Verification commands:**
```bash
show bgp l2vpn evpn type multicast    # Type 3
show bgp l2vpn evpn type macip        # Type 2
show evpn mac vni 10                  # All MACs in VNI
```

---

## 📖 Additional Resources

- [FRRouting Documentation](https://docs.frrouting.org/)
- [RFC 7348 - VXLAN](https://datatracker.ietf.org/doc/html/rfc7348)
- [RFC 7432 - BGP MPLS-Based EVPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [RFC 4271 - BGP-4](https://datatracker.ietf.org/doc/html/rfc4271)
- [RFC 2328 - OSPF Version 2](https://datatracker.ietf.org/doc/html/rfc2328)

