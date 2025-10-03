#!/bin/bash

static_host_a() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Host A: $hostname==="
    docker exec -it "$container_name" sh -c "
        ip addr del 30.1.1.1/24 dev eth0 2>/dev/null || true &&
        ip addr add 30.1.1.1/24 dev eth0 &&
        ip link set eth0 up
    "
}

static_host_b() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Host B: $hostname==="
    docker exec -it "$container_name" sh -c "
        ip addr del 30.1.1.2/24 dev eth0 2>/dev/null || true &&
        ip addr add 30.1.1.2/24 dev eth0 &&
        ip link set eth0 up
    "
}

static_router_a() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router A: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 192.168.100.1/24 dev eth0 2>/dev/null || true &&
        ip addr add 192.168.100.1/24 dev eth0 &&
        ip link set eth0 up &&

        # Remove existing interfaces if they exist
        ip link del vxlan10 2>/dev/null || true &&
        ip link del br0 2>/dev/null || true &&

        # Create bridge interface
        ip link add name br0 type bridge &&
        ip link set br0 up &&

        # Add LAN interface to bridge
        ip link set eth1 master br0 &&
        ip link set eth1 up &&

        # Create VXLAN interface
        ip link add vxlan10 type vxlan id 10 dev eth0 local 192.168.100.1 remote 192.168.100.2 dstport 4789 &&
        ip link set vxlan10 up &&

        # Add VXLAN interface to bridge
        ip link set vxlan10 master br0 &&

        # Add default FDB entry
        bridge fdb append 00:00:00:00:00:00 dev vxlan10 dst 192.168.100.2
    "
}

static_router_b() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router B: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 192.168.100.2/24 dev eth0 2>/dev/null || true &&
        ip addr add 192.168.100.2/24 dev eth0 &&
        ip link set eth0 up &&

        # Remove existing interfaces if they exist
        ip link del vxlan10 2>/dev/null || true &&
        ip link del br0 2>/dev/null || true &&

        # Create bridge interface
        ip link add name br0 type bridge &&
        ip link set br0 up &&

        # Add LAN interface to bridge
        ip link set eth1 master br0 &&
        ip link set eth1 up &&

        # Create VXLAN interface
        ip link add vxlan10 type vxlan id 10 dev eth0 local 192.168.100.2 remote 192.168.100.1 dstport 4789 &&
        ip link set vxlan10 up &&

        # Add VXLAN interface to bridge
        ip link set vxlan10 master br0 &&

        # Add default FDB entry
        bridge fdb append 00:00:00:00:00:00 dev vxlan10 dst 192.168.100.1
    "
}

dynamic_router_a() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router A: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 192.168.100.1/24 dev eth0 2>/dev/null || true &&
        ip addr add 192.168.100.1/24 dev eth0 &&
        ip link set eth0 up &&

        # Remove existing interfaces if they exist
        ip link del vxlan10 2>/dev/null || true &&
        ip link del br0 2>/dev/null || true &&

        # Create bridge interface
        ip link add name br0 type bridge &&
        ip link set br0 up &&

        # Add LAN interface to bridge
        ip link set eth1 master br0 &&
        ip link set eth1 up &&

        # Create VXLAN interface
        ip link add vxlan10 type vxlan id 10 dev eth0 group 239.1.1.1 local 192.168.100.1 dstport 4789 &&
        ip link set vxlan10 up &&

        # Add VXLAN interface to bridge
        ip link set vxlan10 master br0 
    "
}

dynamic_router_b() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router B: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 192.168.100.2/24 dev eth0 2>/dev/null || true &&
        ip addr add 192.168.100.2/24 dev eth0 &&
        ip link set eth0 up &&

        # Remove existing interfaces if they exist
        ip link del vxlan10 2>/dev/null || true &&
        ip link del br0 2>/dev/null || true &&

        # Create bridge interface
        ip link add name br0 type bridge &&
        ip link set br0 up &&

        # Add LAN interface to bridge
        ip link set eth1 master br0 &&
        ip link set eth1 up &&

        # Create VXLAN interface
        ip link add vxlan10 type vxlan id 10 dev eth0 group 239.1.1.1 local 192.168.100.2 dstport 4789 &&
        ip link set vxlan10 up &&

        # Add VXLAN interface to bridge
        ip link set vxlan10 master br0        
    "
}

if [ "$1" == "static" ]; then
    echo "Starting static configuration..."
    containers=$(docker ps --format "{{.Names}}")
    for container in $containers; do
        echo "Configuring container: $container"
        hostname=$(docker exec -it "$container" hostname | tr -d '\r\n' | tr -d ' ')
        echo "Hostname: '$hostname'"
        
        case "$hostname" in
            "host_gkubina-1")
                static_host_a "$container" "$hostname"
                ;;
            "host_gkubina-2")
                static_host_b "$container" "$hostname"
                ;;
            "router_gkubina-1")
                static_router_a "$container" "$hostname"
                ;;
            "router_gkubina-2")
                static_router_b "$container" "$hostname"
                ;;
            *)
                echo "Unknown container: $container (hostname: '$hostname')"
                ;;
        esac
    done

elif [ "$1" == "dynamic" ]; then
    echo "Starting dynamic configuration..."        
    containers=$(docker ps --format "{{.Names}}")
    for container in $containers; do
        echo "Configuring container: $container"
        hostname=$(docker exec -it "$container" hostname | tr -d '\r\n' | tr -d ' ')
        echo "Hostname: '$hostname'"
        
        case "$hostname" in
            "host_gkubina-1")
                static_host_a "$container" "$hostname"
                ;;
            "host_gkubina-2")
                static_host_b "$container" "$hostname"
                ;;
            "router_gkubina-1")
                dynamic_router_a "$container" "$hostname"
                ;;
            "router_gkubina-2")
                dynamic_router_b "$container" "$hostname"
                ;;
            *)
                echo "Unknown container: $container (hostname: '$hostname')"
                ;;
        esac
    done
    

else
    echo "Usage: $0 {static|dynamic}"
    exit 1
fi

