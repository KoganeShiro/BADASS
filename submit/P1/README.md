# BADASS 

## Part 1: GNS3 configuration with Docker.
It is thus necessary to install and
configure GNS3 as well as docker in your virtual machine.
Now that everything works, you need to use two docker images which you must
create.
The first image should be based on a system of your choice and must contain at least
busybox or an equivalent solution.
Alpine seems to be a good solution.
The second image should use a system of your choice and must adhere to the following
constraints:
• A software that manages packet routing (zebra or quagga).
• The service BGPD active and configured.
• The service OSPFD active and configured.
• An IS-IS routing engine service.
• busybox or an equivalent.
There are pre-built images which need to be configured with this kind
of service. Your containers must work in GNS3 with the requested
services. You can add anything you wish to complete this project.
Warning: Your images will be used throughout this project. No IP
address should be configured by default.

You must use these two docker images in GNS3 and realize this small diagram.

You need to have both machines working. We must be able to connect to them by GNS3.
The name of the machines is not put at random it will be necessary to
have your login in the name of each equipment (equipement-name)

You must render this project in a P1 folder at the root of your git repository. You
should also add the configuration files with comments to explain the set up of each equip-
ment.
You must export this project with a ZIP compression including the base images. This file must be visible in your git repository


