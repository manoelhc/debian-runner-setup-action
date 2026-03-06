#!/bin/bash
set -e

PACKAGES_INPUT="${INPUT_PACKAGES:-full}"
ENABLE_CACHE="${INPUT_CACHE:-true}"

CACHE_DIR="/var/cache/apt/archives"
HOLLOW_PACKAGE_NAME="debian-runner-setup-hollow"
MARKER_FILE="/var/lib/dpkg/info/${HOLLOW_PACKAGE_NAME}.marker"

get_package_presets() {
    local preset="$1"
    case "$preset" in
        minimal)
            echo "build-essential git curl wget"
            ;;
        python)
            echo "build-essential git curl wget libssl-dev libffi-dev libreadline-dev libsqlite3-dev libbz2-dev liblzma-dev libzstd-dev zlib1g-dev pkg-config"
            ;;
        ruby)
            echo "build-essential git curl wget libssl-dev libreadline-dev libyaml-dev libgmp-dev libatomic1"
            ;;
        rust)
            echo "build-essential git curl wget pkg-config libssl-dev libffi-dev"
            ;;
        go)
            echo "build-essential git curl wget"
            ;;
        node)
            echo "build-essential git curl wget libssl-dev libcrypto3-dev libpp-dev libnghttp2-dev libzstd-dev"
            ;;
        full)
            echo "build-essential cmake pkg-config libssl-dev libffi-dev libreadline-dev libsqlite3-dev libncurses5-dev libbz2-dev liblzma-dev libzstd-dev zlib1g-dev git curl wget autoconf automake libtool bison flex gettext libcurl4-openssl-dev libnghttp2-dev uuid-dev libev-dev libevent-dev libpcre2-dev libpq-dev libmariadb-dev libxml2-dev libxslt1-dev libyaml-dev libgmp-dev libatomic1"
            ;;
        *)
            echo "$preset"
            ;;
    esac
}

create_hollow_package() {
    local pkg_name="$1"
    
    echo "Creating hollow package marker: $pkg_name"
    
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    mkdir -p "$pkg_name/DEBIAN"
    
    cat > "$pkg_name/DEBIAN/control" <<EOF
Package: $pkg_name
Version: 1.0.0
Section: misc
Priority: optional
Architecture: all
Description: Marker package for debian-runner-setup-action
     This is a hollow package created to mark that build
     dependencies have been installed.
EOF
    
    touch "$pkg_name/DEBIAN/md5sums"
    chmod 755 "$pkg_name/DEBIAN/md5sums"
    
    dpkg-deb --build "$pkg_name" "/tmp/${pkg_name}.deb"
    dpkg -i "/tmp/${pkg_name}.deb" 2>/dev/null || true
    
    rm -rf "$temp_dir"
    
    mkdir -p "$(dirname "$MARKER_FILE")"
    touch "$MARKER_FILE"
    echo "Hollow package installed: $pkg_name"
}

check_hollow_package() {
    if [ -f "$MARKER_FILE" ]; then
        return 0
    fi
    return 1
}

check_packages_installed() {
    local packages="$1"
    local all_installed=true
    
    for pkg in $packages; do
        if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            all_installed=false
            break
        fi
    done
    
    if [ "$all_installed" = "true" ]; then
        return 0
    fi
    return 1
}

install_packages() {
    local packages="$1"
    
    echo "Updating package lists..."
    sudo apt-get update -qq
    
    echo "Installing packages: $packages"
    sudo apt-get install -y -qq $packages
    
    echo "Cleaning up to reduce cache size..."
    sudo apt-get clean -qq
    sudo rm -rf /var/lib/apt/lists/*
}

main() {
    echo "=== Debian Runner Setup Action ==="
    echo "Packages: $PACKAGES_INPUT"
    echo "Cache enabled: $ENABLE_CACHE"
    
    local packages
    packages=$(get_package_presets "$PACKAGES_INPUT")
    
    if [ "$ENABLE_CACHE" = "true" ]; then
        if check_hollow_package && check_packages_installed "$packages"; then
            echo "Hollow package detected - packages already installed"
            echo "=== Using existing packages ==="
            return 0
        fi
    fi
    
    echo "Installing packages..."
    install_packages "$packages"
    
    if [ "$ENABLE_CACHE" = "true" ]; then
        create_hollow_package "$HOLLOW_PACKAGE_NAME"
    fi
    
    echo "=== Setup complete ==="
}

main "$@"
