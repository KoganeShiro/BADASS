# BADASS 

## Part 2: Discovering a VXLAN.
You now have a functional basis to start setting up your first VXLAN (RFC 7348) network,
first in static mode and then in dynamic multicast mode. Here is the topology of your
first VXLAN:
    switch
router  router
host     host

You must configure this network using a VXLAN with an ID of 10, as shown in the
examples. You can use any VXLAN name you like here: vxlan10. You must set up
a bridge here: br0. You can configure your ETHERNET interfaces as you wish. Below is
an example of the expected result when we inspect the traffic between our two machines
in our VXLAN.

We will now see the same thing using groups whose goal is to enable dynamic multicast.
We can notice that our machines now have a group (here 239.1.1.1 you can modify
this part):

Below is an example of how to display our mac address table in our two routers:

You must render this project in a P2 folder at the root of your git repository. You
should also add the configuration files with comments to explain the set up of each equip-
ment.
You must export this project with a ZIP compression including the
base images. This file must be visible in your git repository.
You must use correct and consistent names for your equipment here
with the login of one of the group members.


in order to use ip -d, use the ip inside /sbin/ip