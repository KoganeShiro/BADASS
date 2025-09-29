# BADASS
 Bgp At Doors of Autonomous Systems is Simple.  The purpose of this project is to deepen your knowledge of NetPractice. You will have to simulate several networks (VXLAN+BGP-EVPN) in GNS3. 

## Some protocols

- BGP (Border Gateway Protocol)

Used between different networks (autonomous systems), e.g. between ISPs.

The protocol of the Internet — it decides how packets move across the globe.

Policy-driven: you can choose paths based on rules, not just shortest routes.

Example: ISP use BGP to exchange routes with other ISPs.

- OSPF (Open Shortest Path First)

An interior gateway protocol (IGP) — used inside one organization’s network.

Builds a map of the network using link-state advertisements.

Chooses routes based on the shortest path (Dijkstra’s algorithm).

Fast convergence (reacts quickly to changes).

Example: Used within a data center or company’s internal network.

When Router1 brings up eth1 and OSPF is enabled on that interface (network 10.1.1.0/24 area 0), it starts sending OSPF Hello packets to the multicast address 224.0.0.5.

Any other router on the subnet running OSPF (Router2, Router3) also sends Hellos.

When they see each other’s Hellos, they form OSPF adjacencies.

After that, they exchange Link State Advertisements (LSAs) to describe the networks they know.

Result: Router1 learns dynamically about all routers and networks in the OSPF domain.


- IS-IS (Intermediate System to Intermediate System)

Another IGP, similar to OSPF, also link-state based.

Scales very well in large provider networks.

Originally designed for OSI networks, but adapted for IP.

Example: Heavily used by ISPs and telecom operators.

When Router1 has IS-IS enabled (ip router isis CORE under the interface), it sends IS-IS Hello packets (IIHs) as Ethernet frames to the multicast MAC address reserved for IS-IS (01:80:C2:00:00:14).

Other routers (Router2, Router3) on the same subnet do the same.

Upon receiving Hellos, Router1 forms IS-IS adjacencies.

They exchange Link State PDUs (LSPs), which contain topology and reachability info.

Result: Router1 learns about all routers and networks in the IS-IS domain.



🧠 Big Picture

OSPF and IS-IS are dynamic: Router1 doesn’t need static configuration of Router2/Router3’s addresses. It just knows, “I’m running this protocol on this interface, so I’ll talk to whoever else is here.”

Router1 maintains a routing database (separate for OSPF and IS-IS) and passes the final routes into the kernel routing table via Zebra.
