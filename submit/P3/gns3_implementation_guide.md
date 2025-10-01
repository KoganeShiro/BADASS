# BGP EVPN with VXLAN Implementation Guide

## Overview

This guide provides a step-by-step implementation of BGP EVPN (Ethernet VPN) with VXLAN overlay in a data center environment using GNS3. The project demonstrates automatic MAC address learning and dynamic VTEP relationships using route reflection (RR) principles.

## Network Topology

The implementation follows a spine-leaf architecture with a central route reflector:

```
                    [Route Reflector (RR)]
                    OSPF + BGP on loopbacks
                   eth0/     eth1/     eth2/
                      /        |        \
                  e0/        e1|       e2 \
              [Router-1]   [Router-2]   [Router-3]
              (Leaf VTEP)  (Leaf VTEP)  (Leaf VTEP)
                   |           |           |
                  eth1        eth0        eth0
                   |           |           |
                 eth1        eth0         eht0
              [Host-1]     [Host-2]     [Host-3]
```

### Physical Connections

- **Route Reflector (RR)**:
  - `eth0` → connected to Router-1 `e0`
  - `eth1` → connected to Router-2 `e1`
  - `eth2` → connected to Router-3 `e2`
  - `lo0` → loopback for BGP/OSPF router-id

- **Leaf Routers (VTEPs)**:
  - **Router-1**: 
    - `e0` → connected to RR `eth0` (uplink)
    - `eth1` → connected to Host-1 `eth1`
    - `lo0` → loopback for VXLAN tunnel endpoint
  - **Router-2**:
    - `e1` → connected to RR `eth1` (uplink)
    - `eth0` → connected to Host-2 `eth0`
    - `lo0` → loopback for VXLAN tunnel endpoint
  - **Router-3**:
    - `e2` → connected to RR `eth2` (uplink)
    - `eth0` → connected to Host-3 `eth0`
    - `lo0` → loopback for VXLAN tunnel endpoint

- **Hosts**:
  - **Host-1**: `eth1` connected to Router-1 `eth1`
  - **Host-2**: `eth0` connected to Router-2 `eth0`  
  - **Host-3**: `eth0` connected to Router-3 `eth0`

### Equipment Requirements

- **Route Reflector (RR)**: Central BGP route reflector for EVPN routes (FRR container)
- **Leaf Routers**: VXLAN Tunnel Endpoints with BGP EVPN capabilities (FRR containers)
- **Hosts**: End devices in the same VXLAN segment (Alpine Linux containers)
- **Underlay Network**: OSPF for IP reachability between all routers

### Network Planning

1. **IP Address Allocation**:
   - **Loopback addresses**:
     - Route Reflector: 1.1.1.100/32
     - Router-1: 1.1.1.1/32
     - Router-2: 1.1.1.2/32  
     - Router-3: 1.1.1.3/32
   - **Point-to-point links** (RR to Routers):
     - RR eth0 ↔ Router-1: 10.0.1.0/30
     - RR eth1 ↔ Router-2: 10.0.2.0/30
     - RR eth2 ↔ Router-3: 10.0.3.0/30
   - **Host networks**:
     - Router-1 eth0 ↔ Host-1: 192.168.10.0/24
     - Router-2 eth0 ↔ Host-2: 192.168.20.0/24
     - Router-3 eth0 ↔ Host-3: 192.168.30.0/24
   - **VXLAN Network Identifier (VNI)**: 10

2. **BGP AS Numbers**:
   - AS 65000 for all devices (iBGP)
   - Route reflection between RR and all leaf routers


### Underlay Network Configuration (OSPF)

Configure OSPF on all devices to establish IP reachability:

#### Route Reflector OSPF Configuration:
```bash
# /etc/frr/ospfd.conf
router ospf
 ospf router-id 1.1.1.100
 network 1.1.1.100/32 area 0    # Loopback
 network 10.0.1.0/30 area 0     # Link to Router-1
 network 10.0.2.0/30 area 0     # Link to Router-2 
 network 10.0.3.0/30 area 0     # Link to Router-3
```

#### Leaf Router OSPF Configuration:
```bash
# Router-1 /etc/frr/ospfd.conf
router ospf
 ospf router-id 1.1.1.1
 network 1.1.1.1/32 area 0      # Loopback
 network 10.0.1.0/30 area 0     # Link to RR

# Router-2 /etc/frr/ospfd.conf  
router ospf
 ospf router-id 1.1.1.2
 network 1.1.1.2/32 area 0      # Loopback
 network 10.0.2.0/30 area 0     # Link to RR

# Router-3 /etc/frr/ospfd.conf
router ospf
 ospf router-id 1.1.1.3
 network 1.1.1.3/32 area 0      # Loopback
 network 10.0.3.0/30 area 0     # Link to RR
```

### BGP EVPN Configuration

#### Route Reflector BGP Configuration:
```bash
# /etc/frr/bgpd.conf
router bgp 65000
 bgp router-id 1.1.1.100
 no bgp default ipv4-unicast
 
 # Configure route reflection for EVPN address family
 neighbor vtep-clients peer-group
 neighbor vtep-clients remote-as 65000
 neighbor vtep-clients update-source lo0
 neighbor vtep-clients route-reflector-client
 
 # Add leaf router neighbors
 neighbor 1.1.1.1 peer-group vtep-clients  # Router-1
 neighbor 1.1.1.2 peer-group vtep-clients  # Router-2
 neighbor 1.1.1.3 peer-group vtep-clients  # Router-3
 
 address-family l2vpn evpn
  neighbor vtep-clients activate
  neighbor vtep-clients route-reflector-client
 exit-address-family
```

#### Leaf Router BGP Configuration (Example for Router-1):
```bash
# Router-1 /etc/frr/bgpd.conf
router bgp 65000
 bgp router-id 1.1.1.1
 no bgp default ipv4-unicast
 
 # Configure BGP neighbor to route reflector
 neighbor 1.1.1.100 remote-as 65000
 neighbor 1.1.1.100 update-source lo0
 
 address-family l2vpn evpn
  neighbor 1.1.1.100 activate
  advertise-all-vni
 exit-address-family
```

### VXLAN Configuration

#### Configure VXLAN Interface on Leaf Routers:
```bash
# Router-1 VXLAN configuration
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.1 \
    nolearning

# Create bridge and add interfaces
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth0 master br10  # Host-facing interface (connected to Host-1)

# Bring interfaces up
ip link set vxlan10 up
ip link set br10 up
```

```bash
# Router-2 VXLAN configuration  
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.2 \
    nolearning

ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth0 master br10  # Host-facing interface (connected to Host-2)
ip link set vxlan10 up
ip link set br10 up
```

```bash
# Router-3 VXLAN configuration
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.3 \
    nolearning

ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth0 master br10  # Host-facing interface (connected to Host-3)
ip link set vxlan10 up
ip link set br10 up
```

#### Enable FRR EVPN for VXLAN:
```bash
# /etc/frr/zebra.conf
interface vxlan10
 no shutdown
exit

# Enable BGP EVPN for the VNI
vni 10
 exit-vni
```

### Host Configuration

Configure hosts with basic networking in the same VXLAN segment:

```bash
# Host-1 (connected to Router-1 via eth0)
ip addr add 192.168.100.1/24 dev eth0
ip link set eth0 up

# Host-2 (connected to Router-2 via eth0)  
ip addr add 192.168.100.2/24 dev eth0
ip link set eth0 up

# Host-3 (connected to Router-3 via eth0)
ip addr add 192.168.100.3/24 dev eth0
ip link set eth0 up
```

**Note**: All hosts are in the same VXLAN segment (VNI 10) and use the same subnet (192.168.100.0/24) to demonstrate L2 connectivity across the VXLAN overlay.

## Verification and Testing

### 1. Verify OSPF Adjacencies
```bash
# On any VTEP or RR
vtysh -c "show ip ospf neighbor"
```

### 2. Verify BGP EVPN Sessions
```bash
# On route reflector
vtysh -c "show bgp l2vpn evpn summary"

# On VTEPs
vtysh -c "show bgp l2vpn evpn"
```

### 3. Check EVPN Route Types

#### Type 3 Routes (Inclusive Multicast Ethernet Tag Route):
```bash
vtysh -c "show bgp l2vpn evpn route type 3"
```
These routes are advertised by each VTEP to signal VNI membership.

#### Type 2 Routes (MAC/IP Advertisement Route):
```bash
vtysh -c "show bgp l2vpn evpn route type 2"
```
These routes appear automatically when hosts become active and their MAC addresses are learned.

### 4. Verify MAC Learning
```bash
# Check bridge MAC table
bridge fdb show dev vxlan10

# Check EVPN MAC entries
vtysh -c "show evpn mac vni 10"
```

### 5. Connectivity Testing
```bash
# From host_wil-1, ping other hosts
ping 192.168.10.2  # Should reach host_wil-2
ping 192.168.10.3  # Should reach host_wil-3
```
