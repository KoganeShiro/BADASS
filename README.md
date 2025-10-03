# BADASS - BGP At Doors of Autonomous Systems is Simple

## 📋 Table of Contents
- [Project Overview](#-project-overview)
- [Documentation Structure](#-documentation-structure)
- [Project Structure](#-project-structure)
- [Technologies Used](#-technologies-used)
- [Project Parts](#-project-parts)
- [Theory & Concepts](#-theory--concepts)
- [Resources](#-resources)

## 🎯 Project Overview

**BADASS** is a networking project that explores network architectures. The project involves simulating networks using GNS3 with Docker containers, implementing VXLAN overlay networks, and deploying BGP-EVPN control plane for intelligent MAC learning and traffic distribution.

This project introduces advanced networking concepts including:
- Network simulation with GNS3
- Container-based network functions using Docker
- VXLAN (Virtual Extensible LAN) technology
- BGP-EVPN (Border Gateway Protocol - Ethernet VPN)
- Advanced routing protocols (OSPF, IS-IS, BGP)
---

## 📚 Documentation Structure

### 📖 Main Documentation Files

| File | Purpose |
|------|---------|
| **README.md** (this file) | Project overview and navigation |
| **[THEORY.md](THEORY.md)** | Complete theory reference for all concepts |
| **[P1/README.md](P1/README.md)** | Part 1 implementation guide |
| **[P2/README.md](P2/README.md)** | Part 2 implementation guide |
| **[P3/README.md](P3/README.md)** | Part 3 implementation guide |

### 📝 What Each Document Contains

**THEORY.md - Comprehensive Theory Reference:**
- Part 1 Theory: Packet routing software, BGPD, OSPFD, Zebra, BusyBox
- Part 2 Theory: VXLAN vs VLAN, switches, bridges, broadcast vs multicast
- Part 3 Theory: BGP-EVPN, route reflection, VTEP, VNI, route types
- Detailed explanations with diagrams and examples

**P1/README.md - Part 1 Implementation:**
- GNS3 and Docker setup
- Building host and router images
- Creating basic topology
- Step-by-step configuration

**P2/README.md - Part 2 Implementation:**
- VXLAN tunnel configuration
- Bridge setup
- Static VXLAN mode
- Dynamic multicast VXLAN mode
- Complete configuration scripts

**P3/README.md - Part 3 Implementation:**
- Spine-leaf topology deployment
- OSPF underlay configuration
- VTEP and host configuration
- BGP-EVPN control plane
- Route reflector setup
---

## 📁 Project Structure

```
BADASS/
├── README.md                    # This file - Global project documentation
├── THEORY.md                    # Comprehensive theory documentation (ALL CONCEPTS)
├── P1/                          # Part 1: GNS3 Configuration with Docker
│   ├── README.md                # Part 1 complete implementation guide
│   ├── P1.gns3project           # GNS3 project file
│   ├── build_images.sh          # Script to build Docker images
│   ├── _gkubina_host            # Host Docker image files
│   └── _gkubina_router          # Router Docker image files
├── P2/                          # Part 2: Discovering VXLAN
│   ├── README.md                # Part 2 complete implementation guide
│   ├── P2.gns3project           # GNS3 project file
│   ├── config.sh                # VXLAN configuration script
│   ├── router1_d.conf           # Router 1 dynamic config
│   ├── router1_s.conf           # Router 1 static config
│   ├── router2_d.conf           # Router 2 dynamic config
│   └── router2_s.conf           # Router 2 static config
├── P3/                          # Part 3: BGP-EVPN Implementation
│   ├── README.md                # Part 3 complete implementation guide
│   ├── P3.gns3project           # GNS3 project file
│   ├── config_hosts.sh          # Host configuration script
│   ├── config_routers.sh        # RR + VTEP configuration script
│   ├── router_leaf1.conf        # Leaf 1 router config
│   ├── router_leaf2.conf        # Leaf 2 router config
│   ├── router_leaf3.conf        # Leaf 3 router config
│   └── router_rr.conf           # Route reflector config
```

---

## 🛠️ Technologies Used

### Core Technologies
- **GNS3:** Network simulation platform
- **Docker:** Container runtime for network functions
- **FRRouting (FRR):** Open-source routing software suite

### Networking Protocols
- **VXLAN:** Virtual Extensible LAN (RFC 7348)
- **BGP:** Border Gateway Protocol (RFC 4271)
- **BGP-EVPN:** BGP Ethernet VPN (RFC 7432)
- **OSPF:** Open Shortest Path First
- **IS-IS:** Intermediate System to Intermediate System

---

### Software Installation
Install GNS3 and Docker on your local/virtual machine.
---

## 📚 Project Parts

### Part 1: GNS3 Configuration with Docker
**Objective:** Set up the simulation environment with containerized network functions

- Packet routing software concepts
- Basic host Docker image with BusyBox
- Router Docker image with FRRouting (BGPD, OSPFD, IS-IS)
- Simple 2-node GNS3 topology

📖 **[Read P1 Implementation Guide](P1/README.md)**

📚 **[Read P1 Theory](THEORY.md#part-1-gns3--docker-fundamentals)**

---

### Part 2: Discovering VXLAN
**Objective:** Implement network overlay using VXLAN technology

**What You'll Learn:**
- VXLAN vs VLAN differences
- Linux bridges as virtual switches
- Broadcast vs Multicast traffic
- Layer 2 over Layer 3 networking

**Deliverables:**
- Static VXLAN configuration
- Bridge configuration 
- VXLAN with VNI
- FDB (Forwarding Database) management

📖 **[Read P2 Implementation Guide](P2/README.md)**

📚 **[Read P2 Theory](THEORY.md#part-2-vxlan--network-virtualization)**

---

### Part 3: Discovering BGP with EVPN
**Objective:** Deploy advanced data center fabric with BGP-EVPN

**What You'll Learn:**
- BGP-EVPN control plane
- Route reflection principles
- VTEP (VXLAN Tunnel Endpoint) operation
- VNI (VXLAN Network Identifier)
- Type 2 vs Type 3 routes

**Deliverables:**
- Spine-leaf topology with route reflector
- BGP-EVPN control plane
- OSPF underlay network
- Automatic MAC learning (Type 2, Type 3 routes)

📖 **[Read P3 Implementation Guide](P3/README.md)**

📚 **[Read P3 Theory](THEORY.md#part-3-bgp-evpn--data-center-fabric)**

---

## 🧠 Theory & Concepts

### Complete Theory Documentation

All theoretical concepts are compiled in **[THEORY.md](THEORY.md)**.

## 📖 Resources

### Official Documentation
- [GNS3 Documentation](https://docs.gns3.com/)
- [FRRouting Documentation](https://docs.frrouting.org/)
- [Docker Documentation](https://docs.docker.com/)

### RFCs (Standards)
- [RFC 4271 - BGP-4](https://datatracker.ietf.org/doc/html/rfc4271)
- [RFC 4760 - MP-BGP](https://datatracker.ietf.org/doc/html/rfc4760)
- [RFC 7348 - VXLAN](https://datatracker.ietf.org/doc/html/rfc7348)
- [RFC 7432 - BGP MPLS-Based EVPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [RFC 4456 - BGP Route Reflection](https://datatracker.ietf.org/doc/html/rfc4456)

### Learning Resources
- [BGP Fundamentals](https://www.cloudflare.com/learning/security/glossary/what-is-bgp/)
- [VXLAN Overview](https://www.cisco.com/c/en/us/products/collateral/switches/nexus-9000-series-switches/white-paper-c11-729383.html)
- [Data Center Network Design](https://www.cisco.com/c/en/us/solutions/data-center/data-center-networking/index.html)

### Community Resources
- [GNS3 Community](https://community.gns3.com/)
- [FRRouting GitHub](https://github.com/FRRouting/frr)
