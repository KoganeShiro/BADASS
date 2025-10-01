# VXLAN Network Topology - P2

## Network Overview

This document describes the VXLAN network topology for Project 2, showing the connection between two routers and their respective hosts using VXLAN tunneling with VNI 10.

## Network Topology Diagram

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

## Network Configuration Details

### IP Addressing Scheme

| Device    | Interface | IP Address      | Network         | Description      |
|-----------|-----------|-----------------|-----------------|------------------|
| Router A  | eth0      | 192.168.100.1   | 192.168.100.0/24| Underlay Network |
| Router A  | eth1      | -               | Bridge br0      | LAN Interface    |
| Router B  | eth0      | 192.168.100.2   | 192.168.100.0/24| Underlay Network |
| Router B  | eth1      | -               | Bridge br0      | LAN Interface    |
| Host 1    | eth0      | 30.1.1.1/24     | 30.1.1.0/24     | Overlay Network  |
| Host 2    | eth0      | 30.1.1.2/24     | 30.1.1.0/24     | Overlay Network  |

### VXLAN Configuration

- **VXLAN Network Identifier (VNI)**: 10
- **Multicast Group**: 239.1.1.1 (for dynamic mode)
- **UDP Port**: 4789 (standard VXLAN port)
- **Bridge Interface**: br0 (on both routers)

## Detailed Connection Flow

### Physical Connections

1. **Router A ↔ Switch**: Connected via eth0 interface
2. **Router B ↔ Switch**: Connected via eth0 interface  
3. **Router A ↔ Host 1**: Connected via eth1 interface (through br0 bridge)
4. **Router B ↔ Host 2**: Connected via eth1 interface (through br0 bridge)

### VXLAN Tunnel

```
┌─────────────┐         ┌─────────────────────┐         ┌─────────────┐
│   Host 1    │────────►│      Router A       │         │   Host 2    │
│ 30.1.1.1    │         │ ┌─────────────────┐ │         │ 30.1.1.2    │
└─────────────┘         │ │      br0        │ │         └─────────────┘
                        │ │  ┌───┐  ┌────┐  │ │                ▲
                        │ │  │eth1  │vxlan10 │ │                │
                        │ │  └───┘  └────┘  │ │                │
                        │ └─────────────────┘ │                │
                        │                     │                │
                        │ ┌─────────────────┐ │                │
                        │ │      eth0       │ │                │
                        │ │ 192.168.100.1   │ │                │
                        └─┴─────────────────┴─┘                │
                                    │                          │
                        ═══════════════════════════════════════│
                        ══    VXLAN Tunnel (VNI 10)     ══════│
                        ══    192.168.100.1 → 192.168.100.2  ═│
                        ═══════════════════════════════════════│
                                    │                          │
                        ┌─────────────────────┐                │
                        │      Router B       │                │
                        │ ┌─────────────────┐ │                │
                        │ │      eth0       │ │                │
                        │ │ 192.168.100.2   │ │                │
                        │ └─────────────────┘ │                │
                        │                     │                │
                        │ ┌─────────────────┐ │                │
                        │ │      br0        │ │                │
                        │ │  ┌────┐  ┌───┐  │ │                │
                        │ │  │vxlan10 │eth1 │ │────────────────┘
                        │ │  └────┘  └───┘  │ │
                        │ └─────────────────┘ │
                        └─────────────────────┘
```

## Configuration Commands

### Router A Configuration

```bash
# 1. Configure underlay IP address
ip addr add 192.168.100.1/24 dev eth0
ip link set eth0 up

# 2. Create bridge interface
ip link add name br0 type bridge
ip link set br0 up

# 3. Add LAN interface to bridge
ip link set eth1 master br0
ip link set eth1 up

# 4. Create VXLAN interface
ip link add vxlan10 type vxlan id 10 dev eth0 local 192.168.100.1 remote 192.168.100.2 dstport 4789
ip link set vxlan10 up

# 5. Add VXLAN interface to bridge
ip link set vxlan10 master br0

# 6.Add default FDB entry
bridge fdb append 00:00:00:00:00:00 dev vxlan10 dst 192.168.100.2
```

### Router B Configuration

```bash
# 1. Configure underlay IP address
ip addr add 192.168.100.2/24 dev eth0
ip link set eth0 up

# 2. Create bridge interface
ip link add name br0 type bridge
ip link set br0 up

# 3. Add LAN interface to bridge
ip link set eth1 master br0
ip link set eth1 up

# 4. Create VXLAN interface
ip link add vxlan10 type vxlan id 10 dev eth0 local 192.168.100.2 remote 192.168.100.1 dstport 4789
ip link set vxlan10 up

# 5. Add VXLAN interface to bridge
ip link set vxlan10 master br0

# 6.Add default FDB entry
bridge fdb append 00:00:00:00:00:00 dev vxlan10 dst 192.168.100.1
```

### Host Configurations

#### Host 1
```bash
# Configure overlay network IP
ip addr add 30.1.1.1/24 dev eth0
ip link set eth0 up
```

#### Host 2
```bash
# Configure overlay network IP
ip addr add 30.1.1.2/24 dev eth0
ip link set eth0 up
```

## Data Flow Analysis

### Communication Path: Host 1 → Host 2

1. **Host 1** sends packet to **Host 2** (30.1.1.1 → 30.1.1.2)
2. Packet reaches **Router A** via eth1 interface
3. **Router A** forwards packet to **br0** bridge
4. **br0** determines packet should go through **vxlan10** interface
5. **VXLAN encapsulation** occurs:
   - Original packet wrapped in VXLAN header
   - VNI 10 added to header
   - UDP port 4789 used
   - Outer IP header: 192.168.100.1 → 192.168.100.2
6. Encapsulated packet sent through **underlay network** to **Router B**
7. **Router B** receives VXLAN packet on eth0
8. **VXLAN decapsulation** occurs:
   - VXLAN header removed
   - Original packet extracted
9. Packet forwarded through **br0** to eth1
10. **Host 2** receives original packet

## Network Verification Commands

### Check Bridge Status
```bash
# On both routers
ip link show type bridge
bridge link show
```

### Check VXLAN Interface
```bash
# On both routers
ip link show type vxlan
bridge fdb show dev vxlan10
```

### Test Connectivity
```bash
# From Host 1
ping 30.1.1.2

# From Host 2  
ping 30.1.1.1
```


## Key Features

- **Layer 2 Extension**: Extends Layer 2 domain across Layer 3 infrastructure
- **Tunnel Encapsulation**: Uses UDP encapsulation for transport
- **Bridge Integration**: Seamlessly integrates with Linux bridge for local switching
- **Scalability**: Supports up to 16 million VNIs (Virtual Network Identifiers)
- **Multicast Support**: Can use multicast for dynamic peer discovery

## Network Benefits

1. **Isolation**: Each VNI provides network isolation
2. **Flexibility**: Overlay networks independent of underlay topology
3. **Scalability**: Support for large number of virtual networks
4. **Simplicity**: Simple configuration and management
5. **Interoperability**: Standard protocol supported by many vendors