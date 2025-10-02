# Part 1: GNS3 Configuration with Docker

## 📋 Overview
Part 1 establishes the foundation for the entire BADASS project by setting up the network simulation environment. This part focuses on:
- Installing and configuring GNS3
- Creating Docker-based network appliances
- Building host and router images
- Testing basic network connectivity

---

## 🏗️ Architecture

### Network Topology

```
┌─────────────────────────────────────────────┐
│              GNS3 Project                   │
│                                             │
│   ┌──────────────┐      ┌──────────────┐    │
│   │   Host-1     │      │   Router-1   │    │
│   │  (BusyBox)   │      │  (FRRouting) │    │
│   │  Alpine      │      │   Ubuntu     │    │
│   └──────────────┘      └──────────────┘    │
│                                             │
└─────────────────────────────────────────────┘
```

### Component Details

| Component | Base Image | Purpose | Key Software |
|-----------|-----------|---------|--------------|
| **Host** | Alpine Linux | End-user device simulation | BusyBox, iproute2 |
| **Router** | Docker frrouting image | Network routing device | FRRouting (BGP, OSPF, IS-IS) |

---

## 🛠️ Implementation Steps

### Step 1: Environment Setup

#### Install GNS3
See [GNS3 Installation Guide](https://docs.gns3.com/docs/getting-started/installation/)

#### Install Docker
See [Docker Installation Guide](https://docs.docker.com/get-docker/)

#### Install wireshark (optional, for packet capture)
See [Wireshark Installation Guide](https://www.wireshark.org/download.html)

---

### Step 2: Create Host Docker Image

#### Host Dockerfile
see `P1/project-files/docker/host/Dockerfile`

---

### Step 3: Create Router Docker Image

#### Router Dockerfile
 See `P1/project-files/docker/router/Dockerfile`

### Build Host and router Images
Run the `build_images.sh` script to build both images.


---

### Step 4: Import Docker Images to GNS3

1. Open GNS3
2. Edit → Preferences → Docker containers
3. Click "New"
4. Select existing image from list:
   - `gkubina-host:latest`
   - `gkubina-router:latest`
5. Configure:
   - Name: "gkubina_host" / "gkubina_router"
   - Number of interfaces: 2-4
   - Start command: (use default)
6. Click "Finish"

---

### Step 5: Create GNS3 Topology

#### Configuration Steps in GNS3

1. **Create New Project:**
   - File → New blank project
   - Name: "P1"
   - Location: Choose workspace

2. **Add Devices:**
   - Drag "BADASS Host" to canvas
   - Drag "BADASS Router" to canvas

3. **Connect Devices:**
   - Use "Add a link" tool
   - Connect Host-1 eth0 to Router-1 eth0
   - Connect Host-2 eth0 to Router-1 eth1

4. **Start All Devices:**
   - Right-click → Start all
   - Wait for containers to initialize

---

## 🐛 Troubleshooting

### Issue: Docker Permission Denied

**Symptoms:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login, or run:
newgrp docker

# Verify
docker ps
```

### Issue: GNS3 Can't Find Docker Images

**Symptoms:**
- Images don't appear in GNS3 device list
- "Image not found" errors

**Solution:**
```bash
# Verify images exist
docker images

# Restart GNS3 server
sudo systemctl restart gns3-server

# Or restart GNS3 application completely
```

### Issue: Container Won't Start in GNS3

**Symptoms:**
- Container shows "stopped" immediately after starting
- Errors in GNS3 logs

**Solution:**
```bash
# Check GNS3 logs
tail -f ~/.config/GNS3/gns3_server.log

# Test container manually
docker run -it badass-host:latest /bin/sh

# Ensure CMD in Dockerfile keeps container running
```


---

## 🧠 Key Concepts Learned

### BusyBox
- Minimal Linux utilities in single executable
- Perfect for lightweight containers
- Provides essential networking tools
- Used in Alpine Linux by default

### Docker Containerization
- Isolation of network functions
- Lightweight compared to VMs
- Reproducible builds with Dockerfiles
- Easy deployment in GNS3

### FRRouting (FRR)
- Open-source routing software suite
- Multiple protocol daemons (BGP, OSPF, IS-IS)
- Zebra as routing manager
- CLI similar to Cisco IOS

### GNS3 Simulation
- Network topology design
- Device emulation and simulation
- Integration with Docker
- Real packet flows and captures

---

## 📚 Additional Resources

### Documentation
- [GNS3 Official Docs](https://docs.gns3.com/)
- [Docker Documentation](https://docs.docker.com/)
- [FRRouting Docs](https://docs.frrouting.org/)
- [Alpine Linux Wiki](https://wiki.alpinelinux.org/)

### Tutorials
- [GNS3 Getting Started](https://docs.gns3.com/docs/getting-started/introduction)
- [Docker for Network Engineers](https://www.docker.com/blog/docker-for-network-engineers/)
- [FRR Quick Start](https://docs.frrouting.org/en/latest/setup.html)

### Community
- [GNS3 Community Forum](https://community.gns3.com/)
- [FRRouting GitHub](https://github.com/FRRouting/frr)
- [Docker Community](https://forums.docker.com/)

---

📖 **Continue to [Part 2: Discovering VXLAN](../P2/README.md)**
