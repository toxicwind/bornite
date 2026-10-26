#!/bin/bash
# Install bornite - download latest release binary from GitHub
# Usage: ./install-bornite.sh [version]
#   version: release version number (e.g., "170") or "latest" (default)
set -e

VERSION="${1:-latest}"
REPO="mostlygeek/bornite"

mkdir -p /install/bin

# If a full commit hash is given, find the release tag that points to it
if echo "${VERSION}" | grep -qE '^[0-9a-f]{40}$'; then
    echo "=== Resolving commit ${VERSION:0:7} to release tag ==="
    TAG=$(git ls-remote --tags "https://github.com/${REPO}.git" 2>/dev/null \
        | grep "^${VERSION}" | sed 's|.*refs/tags/||' | grep -v '\^{}' | head -1)
    if [ -n "${TAG}" ]; then
        echo "Resolved to tag: ${TAG}"
        VERSION="${TAG#v}"
    else
        echo "No release tag found for commit ${VERSION:0:7}, using latest"
        VERSION="latest"
    fi
fi

# Strip leading 'v' prefix so both "198" and "v198" work
VERSION="${VERSION#v}"

# Resolve "latest" to actual version number
if [ "$VERSION" = "latest" ]; then
    echo "=== Resolving latest bornite release ==="
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
    if [ -z "$VERSION" ]; then
        echo "FATAL: Could not determine latest release version" >&2
        exit 1
    fi
    echo "Latest version: ${VERSION}"
fi


ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "FATAL: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Download and extract
URL="https://github.com/${REPO}/releases/download/v${VERSION}/bornite_${VERSION}_linux_${ARCH}.tar.gz"
echo "=== Downloading bornite v${VERSION} ==="
echo "URL: $URL"
curl -fSL -o /tmp/bornite.tar.gz "$URL"
tar -xzf /tmp/bornite.tar.gz -C /install/bin/
rm /tmp/bornite.tar.gz

# Validate
if [ ! -x "/install/bin/bornite" ]; then
    echo "FATAL: bornite binary not found or not executable" >&2
    ls -la /install/bin/ >&2
    exit 1
fi

echo "$VERSION" > /install/bornite-version

echo "=== bornite v${VERSION} installed ==="
ls -la /install/bin/bornite