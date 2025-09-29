# BADASS
 Bgp At Doors of Autonomous Systems is Simple.  The purpose of this project is to deepen your knowledge of NetPractice. You will have to simulate several networks (VXLAN+BGP-EVPN) in GNS3. 

## Some protocols

- BGP (Border Gateway Protocol)

Used between different networks (autonomous systems), e.g. between ISPs.

The protocol of the Internet — it decides how packets move across the globe.

Policy-driven: you can choose paths based on rules, not just shortest routes.

Example: Your ISP uses BGP to exchange routes with other ISPs.

- OSPF (Open Shortest Path First)

An interior gateway protocol (IGP) — used inside one organization’s network.

Builds a map of the network using link-state advertisements.

Chooses routes based on the shortest path (Dijkstra’s algorithm).

Fast convergence (reacts quickly to changes).

Example: Used within a data center or company’s internal network.

- IS-IS (Intermediate System to Intermediate System)

Another IGP, similar to OSPF, also link-state based.

Scales very well in large provider networks.

Originally designed for OSI networks, but adapted for IP.

Heavily used by ISPs and telecom operators.

