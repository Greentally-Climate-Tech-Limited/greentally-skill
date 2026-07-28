#!/bin/sh
set -eu

repository="Greentally-Climate-Tech-Limited/greentally-skill"

print_cli() {
    "$1" version >/dev/null
    printf '%s\n' "$1"
}

if [ -n "${GREENTALLY_CLI_PATH:-}" ]; then
    if [ ! -f "$GREENTALLY_CLI_PATH" ] || [ ! -x "$GREENTALLY_CLI_PATH" ]; then
        printf '%s\n' "GREENTALLY_CLI_PATH is not an executable file." >&2
        exit 1
    fi
    print_cli "$GREENTALLY_CLI_PATH"
    exit 0
fi

kernel=$(uname -s)
case "$kernel" in
    Linux)
        platform="linux"
        cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
        cli_path="$cache_root/greentally/cli/greentally"
        ;;
    Darwin)
        platform="darwin"
        cli_path="$HOME/Library/Caches/Greentally/cli/greentally"
        ;;
    *)
        printf '%s\n' "Unsupported operating system: $kernel" >&2
        exit 1
        ;;
esac

if [ -x "$cli_path" ]; then
    print_cli "$cli_path"
    exit 0
fi

path_cli=$(command -v greentally 2>/dev/null || true)
if [ -n "$path_cli" ]; then
    print_cli "$path_cli"
    exit 0
fi

machine=$(uname -m)
case "$machine" in
    x86_64|amd64) architecture="amd64" ;;
    arm64|aarch64) architecture="arm64" ;;
    *)
        printf '%s\n' "Unsupported architecture: $machine" >&2
        exit 1
        ;;
esac

if ! command -v curl >/dev/null 2>&1; then
    printf '%s\n' "curl is required to install Greentally CLI." >&2
    exit 1
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/greentally-install.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT HUP INT TERM

release_json="$temporary_dir/release.json"
curl -fsSL --retry 3 \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$repository/releases/latest" \
    -o "$release_json"

tag=$(sed -n 's/^[[:space:]]*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' "$release_json" | head -n 1)
version=${tag#v}
if [ -z "$tag" ] || [ -z "$version" ]; then
    printf '%s\n' "Could not determine the latest Greentally CLI version." >&2
    exit 1
fi

archive="greentally_${version}_${platform}_${architecture}.tar.gz"
release_base="https://github.com/$repository/releases/download/$tag"
curl -fsSL --retry 3 "$release_base/$archive" -o "$temporary_dir/$archive"
curl -fsSL --retry 3 "$release_base/checksums.txt" -o "$temporary_dir/checksums.txt"

expected=$(awk -v file="$archive" '$2 == file { print $1; exit }' "$temporary_dir/checksums.txt")
if [ -z "$expected" ]; then
    printf '%s\n' "No checksum found for $archive." >&2
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$temporary_dir/$archive" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$temporary_dir/$archive" | awk '{print $1}')
else
    printf '%s\n' "sha256sum or shasum is required to verify Greentally CLI." >&2
    exit 1
fi

if [ "$actual" != "$expected" ]; then
    printf '%s\n' "Checksum verification failed for $archive." >&2
    exit 1
fi

mkdir -p "$temporary_dir/extracted"
tar -xzf "$temporary_dir/$archive" -C "$temporary_dir/extracted" greentally
if [ ! -f "$temporary_dir/extracted/greentally" ]; then
    printf '%s\n' "The release archive does not contain greentally." >&2
    exit 1
fi

mkdir -p "$(dirname "$cli_path")"
chmod 0755 "$temporary_dir/extracted/greentally"
mv "$temporary_dir/extracted/greentally" "$cli_path"
print_cli "$cli_path"
