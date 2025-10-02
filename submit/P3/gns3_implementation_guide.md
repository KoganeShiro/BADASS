# BGP EVPN with VXLAN Implementation Guide

## Overview

This guide provides a step-by-step implementation of BGP EVPN (Ethernet VPN) with VXLAN overlay in a data center environment using GNS3. The project demonstrates automatic MAC address learning and dynamic VTEP relationships using route reflection (RR) principles.

## Network Topology

The implementation follows a spine-leaf architecture with a central route reflector:

```
                    [Route Reflector (RR)]
                       router-1
                    OSPF + BGP on loopbacks
                   eth0/     eth1/     eth2/
                      /        |        \
                 eth0/      eth0|      eth0\
              [Router-2]   [Router-3]   [Router-4]
             router-2  -3          -4
              (Leaf VTEP)  (Leaf VTEP)  (Leaf VTEP)
                   |           |           |
                 eth1        eth1        eth1
                   |           |           |
                 eth0        eth0        eth0
              [Host-1]     [Host-2]     [Host-3]
             host-1  -2          -3
```

### Physical Connections

- **Route Reflector (RR)** - `router-1`:
  - `eth0` → connected to Router-2 `eth0` (10.1.1.0/30 network)
  - `eth1` → connected to Router-3 `eth0` (10.1.1.4/30 network)
  - `eth2` → connected to Router-4 `eth0` (10.1.1.8/30 network)
  - `lo` → loopback 1.1.1.1/32 for BGP/OSPF router-id

- **Leaf Routers (VTEPs)**:
  - **Router-2** (`router-2`): 
    - `eth0` → connected to RR `eth0` (uplink)
    - `eth1` → connected to Host-1 `eth0`
    - `lo` → loopback 1.1.1.2/32 for VXLAN tunnel endpoint
  - **Router-3** (`router-3`):
    - `eth0` → connected to RR `eth1` (uplink)
    - `eth1` → connected to Host-2 `eth0`
    - `lo` → loopback 1.1.1.3/32 for VXLAN tunnel endpoint
  - **Router-4** (`router-4`):
    - `eth0` → connected to RR `eth2` (uplink)
    - `eth1` → connected to Host-3 `eth0`
    - `lo` → loopback 1.1.1.4/32 for VXLAN tunnel endpoint

- **Hosts**:
  - **Host-1** (`host-1`): `eth0` connected to Router-2 `eth1`
  - **Host-2** (`host-2`): `eth0` connected to Router-3 `eth1`  
  - **Host-3** (`host-3`): `eth0` connected to Router-4 `eth1`

### Equipment Requirements

- **Route Reflector (RR)**: Central BGP route reflector for EVPN routes (FRR container)
- **Leaf Routers**: VXLAN Tunnel Endpoints with BGP EVPN capabilities (FRR containers)
- **Hosts**: End devices in the same VXLAN segment (Alpine Linux containers)
- **Underlay Network**: OSPF for IP reachability between all routers

### Network Planning

1. **IP Address Allocation**:
   - **Loopback addresses** (for BGP peering and VXLAN source):
     - Route Reflector (RR): `1.1.1.1/32`
     - Router-2 (Leaf): `1.1.1.2/32`
     - Router-3 (Leaf): `1.1.1.3/32`
     - Router-4 (Leaf): `1.1.1.4/32`
   
   - **Point-to-point links** (underlay network):
     - RR eth0 ↔ Router-2 eth0: `10.1.1.0/30` (RR: 10.1.1.1, Router-2: 10.1.1.2)
     - RR eth1 ↔ Router-3 eth0: `10.1.1.4/30` (RR: 10.1.1.5, Router-3: 10.1.1.6)
     - RR eth2 ↔ Router-4 eth0: `10.1.1.8/30` (RR: 10.1.1.9, Router-4: 10.1.1.10)
   
   - **Host networks** (overlay - same L2 segment via VXLAN):
     - All hosts in VXLAN VNI 10: `20.1.1.0/24`
       - Host-1: 20.1.1.1/24
       - Host-2: 20.1.1.3/24
       - Host-3: 20.1.1.2/24
   
   - **VXLAN Network Identifier (VNI)**: 10

2. **BGP AS Numbers**:
   - AS 64512 for all devices (iBGP - private AS number)
   - Route reflection between RR and all leaf routers

## Implementation Steps

### Step 1: Configure Physical Interfaces

Configure IP addresses on physical interfaces for the underlay network.

#### Route Reflector (router-1):
```bash
# Configure point-to-point links
ip addr add 10.1.1.1/30 dev eth0
ip link set eth0 up

ip addr add 10.1.1.5/30 dev eth1
ip link set eth1 up

ip addr add 10.1.1.9/30 dev eth2
ip link set eth2 up

# Configure loopback for BGP router-id
ip addr add 1.1.1.1/32 dev lo
ip link set lo up
```

#### Leaf Router-2 (router-2):
```bash
# Configure uplink to RR
ip addr add 10.1.1.2/30 dev eth0
ip link set eth0 up

# Configure loopback for BGP and VXLAN source
ip addr add 1.1.1.2/32 dev lo
ip link set lo up
```

#### Leaf Router-3 (router-3):
```bash
# Configure uplink to RR
ip addr add 10.1.1.6/30 dev eth0
ip link set eth0 up

# Configure loopback for BGP and VXLAN source
ip addr add 1.1.1.3/32 dev lo
ip link set lo up
```

#### Leaf Router-4 (router-4):
```bash
# Configure uplink to RR
ip addr add 10.1.1.10/30 dev eth0
ip link set eth0 up

# Configure loopback for BGP and VXLAN source
ip addr add 1.1.1.4/32 dev lo
ip link set lo up
``` 


### Step 2: Configure OSPF Underlay

Configure OSPF on all routers to establish IP reachability between loopback addresses. This is critical for BGP peering.

#### Route Reflector OSPF Configuration (router-1):
```bash
# Enter FRR configuration mode
vtysh

# Configure OSPF
configure terminal
router ospf
 ospf router-id 1.1.1.1
 network 1.1.1.1/32 area 0
 network 10.1.1.0/30 area 0
 network 10.1.1.4/30 area 0
 network 10.1.1.8/30 area 0
exit
exit
write memory
```

**Important:** Ensure you advertise the **point-to-point link subnets** (10.1.1.0/30, 10.1.1.4/30, 10.1.1.8/30), not individual host addresses!

#### Leaf Router-2 OSPF Configuration (router-2):
```bash
vtysh
configure terminal
router ospf
 ospf router-id 1.1.1.2
 network 1.1.1.2/32 area 0
 network 10.1.1.0/30 area 0
exit
exit
write memory
```

#### Leaf Router-3 OSPF Configuration (router-3):
```bash
vtysh
configure terminal
router ospf
 ospf router-id 1.1.1.3
 network 1.1.1.3/32 area 0
 network 10.1.1.4/30 area 0
exit
exit
write memory
```

#### Leaf Router-4 OSPF Configuration (router-4):
```bash
vtysh
configure terminal
router ospf
 ospf router-id 1.1.1.4
 network 1.1.1.4/32 area 0
 network 10.1.1.8/30 area 0
exit
exit
write memory
```

#### Verify OSPF:
```bash
# Check OSPF neighbors (should see all connected routers)
vtysh -c "show ip ospf neighbor"

# Verify loopback reachability
ping 1.1.1.1
ping 1.1.1.2
ping 1.1.1.3
ping 1.1.1.4
```

### Step 3: Configure BGP EVPN

Configure BGP with EVPN address family for control plane MAC learning and VTEP discovery.

#### Route Reflector BGP Configuration (router-1):
```bash
vtysh
configure terminal
router bgp 64512
 bgp router-id 1.1.1.1
 no bgp default ipv4-unicast
 
 # Configure peer group for VTEP clients
 neighbor vtep-clients peer-group
 neighbor vtep-clients remote-as 64512
 neighbor vtep-clients update-source lo
 
 # Add leaf routers to peer group
 neighbor 1.1.1.2 peer-group vtep-clients
 neighbor 1.1.1.3 peer-group vtep-clients
 neighbor 1.1.1.4 peer-group vtep-clients
 
 # Configure EVPN address family with route reflection
 address-family l2vpn evpn
  neighbor vtep-clients activate
  neighbor vtep-clients route-reflector-client
 exit-address-family
exit
exit
write memory
```

#### Leaf Router-2 BGP Configuration (router-2):
```bash
vtysh
configure terminal
router bgp 64512
 bgp router-id 1.1.1.2
 no bgp default ipv4-unicast
 
 # Peer with route reflector using loopback
 neighbor 1.1.1.1 remote-as 64512
 neighbor 1.1.1.1 update-source lo
 
 # Enable EVPN and advertise all VNIs
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
exit
exit
write memory
```

#### Leaf Router-3 BGP Configuration (router-3):
```bash
vtysh
configure terminal
router bgp 64512
 bgp router-id 1.1.1.3
 no bgp default ipv4-unicast
 
 neighbor 1.1.1.1 remote-as 64512
 neighbor 1.1.1.1 update-source lo
 
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
exit
exit
write memory
```

#### Leaf Router-4 BGP Configuration (router-4):
```bash
vtysh
configure terminal
router bgp 64512
 bgp router-id 1.1.1.4
 no bgp default ipv4-unicast
 
 neighbor 1.1.1.1 remote-as 64512
 neighbor 1.1.1.1 update-source lo
 
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
exit
exit
write memory
```

#### Verify BGP:
```bash
# Check BGP sessions (should see all 3 peers in Established state)
vtysh -c "show bgp l2vpn evpn summary"
```




### Step 4: Configure VXLAN Overlay

Configure VXLAN interfaces on leaf routers and bridge them with host-facing interfaces.

#### Leaf Router-2 VXLAN Configuration (router-2):
```bash
# Create VXLAN interface
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.2 \
    nolearning

# Create bridge and attach VXLAN and host interface
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth1 master br10

# Bring interfaces up
ip link set vxlan10 up
ip link set br10 up
ip link set eth1 up
```

#### Leaf Router-3 VXLAN Configuration (router-3):
```bash
# Create VXLAN interface
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.3 \
    nolearning

# Create bridge and attach VXLAN and host interface
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth1 master br10

# Bring interfaces up
ip link set vxlan10 up
ip link set br10 up
ip link set eth1 up
```

#### Leaf Router-4 VXLAN Configuration (router-4):
```bash
# Create VXLAN interface
ip link add vxlan10 type vxlan \
    id 10 \
    dstport 4789 \
    local 1.1.1.4 \
    nolearning

# Create bridge and attach VXLAN and host interface
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set eth1 master br10

# Bring interfaces up
ip link set vxlan10 up
ip link set br10 up
ip link set eth1 up
```

**Key VXLAN Parameters:**
- `id 10`: VXLAN Network Identifier (VNI)
- `dstport 4789`: Standard VXLAN port
- `local <loopback-ip>`: Source IP for VXLAN tunnels
- `nolearning`: Disable kernel MAC learning (BGP EVPN handles this)

### Step 5: Configure Hosts

Configure hosts with IP addresses in the same L2 segment (VXLAN VNI 10).

#### Host-1 Configuration (host-1):
```bash
ip addr add 20.1.1.1/24 dev eth0
ip link set eth0 up
```

#### Host-2 Configuration (host-2):
```bash
ip addr add 20.1.1.3/24 dev eth0
ip link set eth0 up
```

#### Host-3 Configuration (host-3):
```bash
ip addr add 20.1.1.2/24 dev eth0
ip link set eth0 up
```

**Note**: All hosts are in the same VXLAN segment (VNI 10) and use the same subnet (20.1.1.0/24), demonstrating Layer 2 connectivity across the VXLAN overlay despite being on physically separate leaf routers.

## Verification and Testing

### 1. Verify OSPF Adjacencies

Check that all routers have formed OSPF neighbor relationships:

```bash
# On Route Reflector (should show 3 neighbors)
docker exec router-1 vtysh -c "show ip ospf neighbor"

# Expected output:
# Neighbor ID: 1.1.1.2, 1.1.1.3, 1.1.1.4 in Full state

# On any leaf router (should show 1 neighbor - the RR)
docker exec router-2 vtysh -c "show ip ospf neighbor"
```

### 2. Verify BGP EVPN Sessions

Check that BGP sessions are established:

```bash
# On Route Reflector (should show 3 peers in Established state)
docker exec router-1 vtysh -c "show bgp l2vpn evpn summary"

# Expected output:
# Neighbor    State/PfxRcd
# 1.1.1.2     Established (1-2 prefixes)
# 1.1.1.3     Established (1-2 prefixes)
# 1.1.1.4     Established (1-2 prefixes)

# On leaf router
docker exec router-2 vtysh -c "show bgp l2vpn evpn summary"
```

### 3. Check EVPN Route Types

#### Type 3 Routes (IMET - Inclusive Multicast Ethernet Tag):

These routes advertise VNI membership and establish VTEP relationships:

```bash
docker exec router-2 vtysh -c "show bgp l2vpn evpn route type 3"

# Expected: Should see 3 routes (one from each VTEP)
# [3]:[0]:[32]:[1.1.1.2] - local
# [3]:[0]:[32]:[1.1.1.3] - from Router-3
# [3]:[0]:[32]:[1.1.1.4] - from Router-4
```

#### Type 2 Routes (MAC/IP Advertisement):

These routes are learned automatically when hosts communicate:

```bash
docker exec router-2 vtysh -c "show bgp l2vpn evpn route type 2"

# These appear after hosts start sending traffic
```

### 4. Verify VXLAN and MAC Learning

Check VXLAN forwarding database:

```bash
# Check bridge FDB on leaf router
docker exec router-2 bridge fdb show dev vxlan10

# Check EVPN MAC table
docker exec router-2 vtysh -c "show evpn mac vni 10"
```

Verify VXLAN interface is properly configured:

```bash
docker exec router-2 ip -d link show vxlan10
```

### 5. Test Connectivity

Ping between hosts to verify end-to-end L2 connectivity:

```bash
# From Host-1, ping Host-2 and Host-3
docker exec host-1 ping -c 4 20.1.1.2  # Host-3
docker exec host-1 ping -c 4 20.1.1.3  # Host-2

# All pings should succeed with 0% packet loss
```

### 6. Troubleshooting Commands

If connectivity fails, check:

```bash
# Verify loopback reachability (underlay)
docker exec router-2 ping 1.1.1.1
docker exec router-2 ping 1.1.1.3
docker exec router-2 ping 1.1.1.4

# Check OSPF routes
docker exec router-2 vtysh -c "show ip route ospf"

# Check BGP EVPN routes
docker exec router-2 vtysh -c "show bgp l2vpn evpn"

# Check interface status
docker exec router-2 ip link show
docker exec router-2 ip addr show

# Check if VXLAN tunnels are working
docker exec router-2 ip -s link show vxlan10
# Look for RX/TX packets - drops indicate a problem
```

## Common Issues and Solutions

1. **OSPF neighbors not forming:**
   - Verify physical connectivity
   - Check OSPF network statements match actual interface IPs
   - Ensure interfaces are up

2. **BGP sessions not establishing:**
   - Verify OSPF is working and loopbacks are reachable
   - Check BGP router-id and neighbor IPs are correct
   - Ensure `update-source lo` is configured

3. **VXLAN packets being dropped:**
   - Verify BGP EVPN Type-3 routes are being exchanged
   - Check VXLAN interface is using correct loopback as source
   - Ensure `advertise-all-vni` is configured on leaf routers

4. **Hosts can't ping each other:**
   - Verify hosts are on same subnet and VXLAN VNI
   - Check host interfaces are added to bridge (br10)
   - Ensure eth1 on routers is up and in bridge
