#!/bin/sh

router_rr() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router RR: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 10.1.1.1/30 dev eth0 2>/dev/null || true &&
        ip addr add 10.1.1.1/30 dev eth0 &&
        ip link set eth0 up &&

        ip addr del 10.1.1.5/30 dev eth1 2>/dev/null || true &&
        ip addr add 10.1.1.5/30 dev eth1 &&
        ip link set eth1 up &&

        ip addr del 10.1.1.9/30 dev eth2 2>/dev/null || true &&
        ip addr add 10.1.1.9/30 dev eth2 &&
        ip link set eth2 up &&

        # Remove existing interfaces if they exist
        ip link del lo 2>/dev/null || true &&

        # Create loopback interface
        ip addr add 1.1.1.1/32 dev lo &&
        ip link set lo up
    "
}

router_a() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router B: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 10.1.1.2/30 dev eth0 2>/dev/null || true &&
        ip addr add 10.1.1.2/30 dev eth0 &&
        ip link set eth0 up &&

        ip addr del 1.1.1.2/32 dev lo 2>/dev/null || true &&
        ip addr add 1.1.1.2/32 dev lo &&
        ip link set lo up &&

        # Router-1 VXLAN configuration
        ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.2 nolearning &&

        # Create bridge and add interfaces
        ip link add br10 type bridge &&
        ip link set vxlan10 master br10 &&
        # Host-facing interface (connected to Host-1)
        ip link set eth1 master br10 &&

        # Bring interfaces up
        ip link set vxlan10 up &&
        ip link set br10 up
       
    "
}

router_b() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router B: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 10.1.1.6/30 dev eth0 2>/dev/null || true &&
        ip addr add 10.1.1.6/30 dev eth0 &&
        ip link set eth0 up &&

        ip addr del 1.1.1.3/32 dev lo 2>/dev/null || true &&
        ip addr add 1.1.1.3/32 dev lo &&
        ip link set lo up &&

        # Router-1 VXLAN configuration
        ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.3 nolearning &&

        # Create bridge and add interfaces
        ip link add br10 type bridge &&
        ip link set vxlan10 master br10 &&
        # Host-facing interface (connected to Host-1)
        ip link set eth1 master br10 &&

        # Bring interfaces up
        ip link set vxlan10 up &&
        ip link set br10 up
       
    "
}

router_c() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Router C: $hostname==="
    docker exec -it "$container_name" sh -c "
        # Configure underlay IP address
        ip addr del 10.1.1.10/30 dev eth0 2>/dev/null || true &&
        ip addr add 10.1.1.10/30 dev eth0 &&
        ip link set eth0 up &&

        ip addr del 1.1.1.4/32 dev lo 2>/dev/null || true &&
        ip addr add 1.1.1.4/32 dev lo &&
        ip link set lo up &&

        # Router-1 VXLAN configuration
        ip link add vxlan10 type vxlan id 10 dstport 4789 local 1.1.1.4 nolearning &&

        # Create bridge and add interfaces
        ip link add br10 type bridge &&
        ip link set vxlan10 master br10 &&
        # Host-facing interface (connected to Host-1)
        ip link set eth1 master br10 &&

        # Bring interfaces up
        ip link set vxlan10 up &&
        ip link set br10 up
    "
}


echo "Starting static configuration..."
containers=$(docker ps --format "{{.Names}}")
for container in $containers; do
    echo "Configuring container: $container"
    hostname=$(docker exec -it "$container" hostname | tr -d '\r\n' | tr -d ' ')
        echo "Hostname: '$hostname'"
        
        case "$hostname" in
            "router_gkubina-1")
                router_rr "$container" "$hostname"
                ;;
            "router_gkubina-2")
                router_a "$container" "$hostname"
                ;;
            "router_gkubina-3")
                router_b "$container" "$hostname"
                ;;
            "router_gkubina-4")
                router_c "$container" "$hostname"
                ;;
            *)
                echo "Unknown container: $container (hostname: '$hostname')"
                ;;
        esac
    done

