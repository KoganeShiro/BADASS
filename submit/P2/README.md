# Part 2: Discovering VXLAN

## 📋 Overview
Part 2 introduces VXLAN (Virtual Extensible LAN) technology, enabling Layer 2 network extension over Layer 3 infrastructure. This part demonstrates how to create overlay networks that allow hosts in different physical locations to communicate as if they were on the same local network.

---

## 💡 Why VXLAN?

### The Problem VXLAN Solves

**Traditional VLANs have limitations:**
- **Limited scale:** Only 4,096 VLANs possible (12-bit VLAN ID)
- **Geographic restrictions:** VLANs can't easily span across data centers
- **Physical dependency:** Requires Layer 2 adjacency between switches

**Real-world scenario:**
Imagine you have:
- Data Center in New York with servers 🏢
- Data Center in London with servers 🏢
- Both need to be in the **same virtual network** (same broadcast domain)
- But they're connected only via **IP routing** (Layer 3)

❌ **Traditional VLANs:** Can't do this!  
✅ **VXLAN:** Makes it possible!

### Why Use VXLAN?

| Benefit | Description | Example |
|---------|-------------|---------|
| **🌍 Geographic Flexibility** | Connect networks across cities/countries | VM migration between data centers |
| **📈 Massive Scale** | 16 million virtual networks (24-bit VNI) | Multi-tenant cloud environments |
| **🔌 Works Over IP** | Uses existing IP infrastructure | No need for special Layer 2 connections |
| **☁️ Cloud-Ready** | Essential for modern cloud/container platforms | Kubernetes, Docker, OpenStack |
| **🔒 Isolation** | Separate virtual networks for different customers | Multi-tenant data centers |

### Why It's Important to Know

**For Modern Networking:**
- **Cloud Computing:** AWS, Azure, GCP all use VXLAN-like technologies
- **Data Centers:** Standard for multi-tenant environments
- **Container Orchestration:** Kubernetes CNI plugins use VXLAN
- **SD-WAN:** Software-defined networks rely on overlay technologies

---

## 🏗️ Architecture

### Network Topology

```
                              ┌─────────────┐
                              │   Switch    │
                              │             │
                              └──────┬──────┘
                                     │
                     ┌───────────────┼───────────────┐
                     │               │               │
                     │ eth0          │          eth0 │
              ┌──────▼─────┐                 ┌──────▼─────┐
              │  Router A  │◄────────────────┤  Router B  │
              │192.168.100.1│   VXLAN Tunnel │192.168.100.2│
              │            │    (VNI 10)     │            │
              │    br0     │                 │    br0     │
              └──────┬─────┘                 └──────┬─────┘
                     │ eth1                         │ eth1
                     │                              │
              ┌──────▼─────┐                 ┌──────▼─────┐
              │   Host 1   │                 │   Host 2   │
              │30.1.1.1/24 │                 │30.1.1.2/24 │
              │            │                 │            │
              └────────────┘                 └────────────┘
```

### Component Details

| Component | Role | Interfaces | IP Addresses |
|-----------|------|------------|--------------|
| **Router A** | (Site 1) | eth0 (underlay), eth1 (local), br0 (bridge) | eth0: 192.168.100.1/24 |
| **Router B** | (Site 2) | eth0 (underlay), eth1 (local), br0 (bridge) | eth0: 192.168.100.2/24 |
| **Host 1** | End device  | eth0 | 30.1.1.1/24 |
| **Host 2** | End device  | eth0 | 30.1.1.2/24 |
| **Switch** | L2 connectivity | Multiple ports | Underlay network switch |

---

## 🛠️ Implementation Steps

### Step 1: Environment Setup

This project assumes you have completed Part 1 and have:
- GNS3 installed and configured
- Docker images built (host and router)
- Basic understanding of Docker and GNS3 workflow

See [Part 1 README](../P1/README.md) for environment setup details.

---

### Step 2: Create GNS3 Topology

#### Topology Setup in GNS3

1. **Create New Project:**
   - File → New blank project
   - Name: "P2"
   - Location: Choose workspace

2. **Add Devices:**
   - 1x Switch (Ethernet switch from GNS3 built-in devices)
   - 2x Router containers (your Docker router image)
   - 2x Host containers (your Docker host image)

3. **Connect Devices:**
   - Router A eth0 ↔ Switch port 1
   - Router B eth0 ↔ Switch port 2
   - Router A eth1 ↔ Host 1 eth0
   - Router B eth1 ↔ Host 2 eth0

4. **Start All Devices:**
   - Right-click → Start all
   - Wait for containers to initialize

---

### Step 3: Configure Network
For that you can use the `config_static.sh` script provided in the P2 directory. This script will set up the VXLAN tunnel, bridge interfaces, and assign IP addresses to the hosts.
Basically, it will:
- Create the VXLAN interface on both routers
- Create the bridge interfaces
- Assign IP addresses to the hosts

In doing so, it establishes the necessary configurations to enable VXLAN tunneling between Router A and Router B, allowing Host 1 and Host 2 to communicate over the overlay network.

---

### VXLAN Encapsulation

VXLAN wraps the original Layer 2 frame in multiple headers:

```
Original Frame:
┌────────────────────────────────────────┐
│ Original Ethernet Frame (L2)           │
└────────────────────────────────────────┘

VXLAN Encapsulated Packet:
┌────────────────────────────────────────┐
│ Outer Ethernet Header                  │ ← Physical network
├────────────────────────────────────────┤
│ Outer IP Header                        │ ← Underlay (192.168.100.x)
├────────────────────────────────────────┤
│ UDP Header (dst port 4789)             │ ← VXLAN transport
├────────────────────────────────────────┤
│ VXLAN Header (VNI: 10)                 │ ← Virtual network ID
├────────────────────────────────────────┤
│ Original Ethernet Frame                │ ← Overlay (30.1.1.x)
└────────────────────────────────────────┘
```

### Bridge Operation

The Linux bridge (br0) acts as a virtual switch:

```
         ┌──────────────────────────┐
         │      Bridge (br0)        │
         │   (MAC Learning Table)   │
         └──────┬──────────┬────────┘
                │          │
         ┌──────▼────┐  ┌──▼─────────┐
         │   eth1    │  │  vxlan10   │
         │  (Local)  │  │  (Tunnel)  │
         └──────┬────┘  └──┬─────────┘
                │          │
           Local Host   Remote Host
           (Host 1)     (Host 2)
```

### Static VXLAN Mode

This implementation uses **static VXLAN** configuration:
- Manual specification of remote
- Fixed tunnel endpoints
- Simpler than multicast mode
- Suitable for learning and small deployments

### Dynamic VXLAN Mode
In dynamic mode, VXLAN uses multicast to discover remote routers:
- Requires multicast support in the underlay network
- Routers join a multicast group to learn about other routers

Multicast is a method of communication where data is sent from one sender to multiple receivers simultaneously. In a multicast network, a single data stream is transmitted to a specific group of interested receivers, rather than to all devices on the network (broadcast) or to a single device (unicast).

Differences between Broadcast and Multicast:
- Broadcast sends data to all devices on a network segment.
- Multicast sends data to a specific group of devices.

---

## 🐛 Troubleshooting

### Issue: Host-1 Cannot Ping Host-2

**Step 1: Verify Underlay**
```bash
# On Router-1
ping 192.168.100.2

# If fails: Check underlay interfaces and routing
```

**Step 2: Check VXLAN Interface**
```bash
# On Router-1
ip -d link show vxlan10

# Verify:
# - Interface is UP
# - VNI is 10
# - local and remote IPs correct
# - dstport is 4789
```

**Step 3: Check Bridge**
```bash
# On Router-1
bridge link show br br0

# Should show:
# - eth1 in bridge
# - vxlan10 in bridge
# - Both interfaces UP
```

**Step 4: Check FDB**
```bash
# On Router-1
bridge fdb show dev vxlan10

# Should have default entry:
# 00:00:00:00:00:00 dst 192.168.100.2
```
___

## 🧠 Key Concepts Learned

1. **VXLAN Fundamentals:**
   - How VXLAN provides Layer 2 over Layer 3
   - Encapsulation format and overhead
   - VNI concept and purpose

2. **Bridge Networking:**
   - How Linux bridges work
   - MAC learning and forwarding
   - Bridge integration with VXLAN

3. **Tunnel Configuration:**
   - Creating VXLAN interfaces
   - Configuring tunnel endpoints
   - Managing FDB entries

4. **Network Layers:**
   - Separation of underlay and overlay
   - IP addressing in both layers
   - Traffic flow analysis
---

## 📚 Additional Resources

### VXLAN Specification
- [RFC 7348 - Virtual eXtensible Local Area Network (VXLAN)](https://datatracker.ietf.org/doc/html/rfc7348)

### Linux Networking
- [Linux Bridge Documentation](https://wiki.linuxfoundation.org/networking/bridge)
- [iproute2 Documentation](https://wiki.linuxfoundation.org/networking/iproute2)

### Tutorials
- [VXLAN Tutorial - Red Hat](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking)
- [Linux Bridge Tutorial](https://developers.redhat.com/articles/2022/04/06/introduction-linux-bridging-commands-and-features)

---

📖 **Continue to [Part 3: Discovering BGP with EVPN](../P3/README.md)**
