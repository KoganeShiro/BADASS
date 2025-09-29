VM Virtualbox badass

gkubina/gkubina

Creation d'une VM pour installer GNS3

Ubuntu-based distributions (64-bit only)

These instructions are for Ubuntu and all distributions based on it (like Linux Mint).

OK sudo add-apt-repository ppa:gns3/ppa
OK sudo apt update                                
OK sudo apt install gns3-gui gns3-server


If you want IOU support

OKsudo dpkg --add-architecture i386
OKsudo apt update
OKsudo apt install gns3-iou

To install Docker CE (Xenial_and_newer)

Remove any old versions:

OKsudo apt remove docker docker-engine docker.io
OKsudo snap remove docker

Install the following packages:

OKsudo apt-get install apt-transport-https OKca-certificates curl software-properties-common

Import the official Docker GPG key:

OKcurl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Add the appropriate repo:

OKsudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(. /etc/os-release && echo $VERSION_CODENAME) stable"

Install Docker-CE:

OKsudo apt update
OKsudo apt install docker-ce

Finally, add your user to the following groups:

ubridge libvirt kvm wireshark docker

OK sudo usermod -aG ubridge,libvirt,kvm,wireshark,docker $(whoami)

Restart your user session by logging out and back in, or restarting the system.

https://docs.gns3.com/docs/getting-started/installation/linux

https://docs.gns3.com/docs/getting-started/setup-wizard-gns3-vm

https://docs.gns3.com/docs/getting-started/setup-wizard-gns3-vm

https://docs.gns3.com/docs/getting-started/your-first-gns3-topology

Use the GNS3 VM on Windows and Mac OS. It’s optional, but not required, when running GNS3 natively in Linux.

