#!/bin/sh

static_host_a() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Host A: $hostname==="
    docker exec -it "$container_name" sh -c "
        ip addr del 20.1.1.1/24 dev eth0 2>/dev/null || true &&
        ip addr add 20.1.1.1/24 dev eth0 &&
        ip link set eth0 up
    "
}

static_host_b() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Host B: $hostname==="
    docker exec -it "$container_name" sh -c "
        ip addr del 20.1.1.3/24 dev eth0 2>/dev/null || true &&
        ip addr add 20.1.1.3/24 dev eth0 &&
        ip link set eth0 up
    "
}

static_host_c() {
    local container_name="$1"
    local hostname="$2"
    echo "===Configuring Host C: $hostname==="
    docker exec -it "$container_name" sh -c "
        ip addr del 20.1.1.2/24 dev eth0 2>/dev/null || true &&
        ip addr add 20.1.1.2/24 dev eth0 &&
        ip link set eth0 up
    "
}

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
            "host_gkubina-3")
                static_host_c "$container" "$hostname"
                ;;
            *)
                echo "Unknown container: $container (hostname: '$hostname')"
                ;;
        esac
    done


