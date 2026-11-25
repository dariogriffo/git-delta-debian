git_delta_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$git_delta_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <git_delta_version> <build_version> [architecture]"
    echo "Example: $0 0.22.0 1 arm64"
    echo "Example: $0 0.22.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armhf, i386, all"
    exit 1
fi

# Function to map Debian architecture to the upstream .deb asset name
get_delta_release() {
    local arch=$1
    case "$arch" in
        "amd64"|"arm64"|"armhf"|"i386")
            echo "git-delta_${git_delta_VERSION}_${arch}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Runtime libraries of upstream's binaries, measured per arch: each one is
# built on a different runner, so the glibc floor differs, and only amd64
# links zlib dynamically. i386 needs glibc 2.39, so it does not run on
# bookworm (the mirror excludes bookworm:i386). Upstream's own Depends for
# i386 names the amd64 multilib packages (libc6-i386, lib32gcc-s1) and is
# not usable on a real i386 system, hence our own list.
get_delta_depends() {
    case "$1" in
        "amd64") echo "libc6 (>= 2.34), libgcc-s1, zlib1g (>= 1:1.1.4)" ;;
        "arm64") echo "libc6 (>= 2.18), libgcc-s1" ;;
        "armhf") echo "libc6 (>= 2.16), libgcc-s1" ;;
        "i386")  echo "libc6 (>= 2.39), libgcc-s1" ;;
    esac
}

# Upstream's .deb carries only the binary. The shell completions and the
# themes.gitconfig helper (which Debian's own git-delta also ships) come from
# the source archive at the same tag. Downloaded once, shared by every arch.
SRC_ARCHIVE="delta-${git_delta_VERSION}-src.tar.gz"
SRC_DIR="delta-${git_delta_VERSION}"
fetch_upstream_source() {
    if [ -d "$SRC_DIR" ]; then
        return 0
    fi
    if ! wget -q "https://github.com/dandavison/delta/archive/refs/tags/${git_delta_VERSION}.tar.gz" -O "$SRC_ARCHIVE"; then
        echo "❌ Failed to download the delta source archive"
        return 1
    fi
    tar -xzf "$SRC_ARCHIVE" "$SRC_DIR/etc/completion" "$SRC_DIR/themes.gitconfig" || return 1
    rm -f "$SRC_ARCHIVE"
    for f in etc/completion/completion.bash etc/completion/completion.zsh etc/completion/completion.fish themes.gitconfig; do
        if [ ! -f "$SRC_DIR/$f" ]; then
            echo "❌ Unexpected source layout: $SRC_DIR/$f not found"
            return 1
        fi
    done
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local delta_release

    delta_release=$(get_delta_release "$build_arch")
    if [ -z "$delta_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, armhf, i386"
        return 1
    fi

    echo "Building for architecture: $build_arch using $delta_release"

    fetch_upstream_source || return 1

    # Clean up any previous builds for this architecture
    rm -rf "$delta_release" || true
    rm -f "${delta_release}.deb" || true

    # Download upstream's .deb for this architecture
    if ! wget "https://github.com/dandavison/delta/releases/download/${git_delta_VERSION}/${delta_release}.deb"; then
        echo "❌ Failed to download git-delta .deb for $build_arch"
        return 1
    fi

    # Unpack only the payload; the control data (and its Depends) is replaced by ours
    if ! dpkg-deb -x "${delta_release}.deb" "$delta_release"; then
        echo "❌ Failed to extract git-delta .deb for $build_arch"
        return 1
    fi

    rm -f "${delta_release}.deb"

    if [ ! -f "$delta_release/usr/bin/delta" ]; then
        echo "❌ Unexpected package layout: $delta_release/usr/bin/delta not found"
        return 1
    fi

    # One package for every suite: upstream ships one binary per architecture,
    # so only the old ~<suite> version suffix ever differed. The fixed ~griffo
    # keeps it below the distro's own build of the same version.
    FULL_VERSION="$git_delta_VERSION-${BUILD_VERSION}~griffo_${build_arch}"
    echo "  Building $FULL_VERSION"

    if ! docker build . -t "git-delta-$build_arch" \
        --build-arg git_delta_VERSION="$git_delta_VERSION" \
        --build-arg BUILD_VERSION="$BUILD_VERSION" \
        --build-arg FULL_VERSION="$FULL_VERSION" \
        --build-arg ARCH="$build_arch" \
        --build-arg DELTA_RELEASE="$delta_release" \
        --build-arg DELTA_SRC="$SRC_DIR" \
        --build-arg DELTA_DEPENDS="$(get_delta_depends "$build_arch")"; then
        echo "❌ Failed to build Docker image for $build_arch"
        return 1
    fi

    id="$(docker create "git-delta-$build_arch")"
    if ! docker cp "$id:/git-delta_$FULL_VERSION.deb" - > "./git-delta_$FULL_VERSION.deb"; then
        echo "❌ Failed to extract .deb package for $build_arch"
        return 1
    fi
    docker rm "$id" >/dev/null || true

    if ! tar -xf "./git-delta_$FULL_VERSION.deb"; then
        echo "❌ Failed to extract .deb contents for $build_arch"
        return 1
    fi

    # Clean up extracted directory
    rm -rf "$delta_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building git-delta $git_delta_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures (the ones upstream publishes a .deb for)
    ARCHITECTURES=("amd64" "arm64" "armhf" "i386")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la git-delta_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi

rm -rf "$SRC_DIR" || true
