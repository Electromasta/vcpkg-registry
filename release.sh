#!/usr/bin/env bash
# Release a new version of a port in this registry.
#
#   ./release.sh <port> <version> <commit-or-ref>
#   ./release.sh commonplusplus 1.1.0 master
#
# Points the port at the given commit of its source repo, sets the version, commits the port,
# records the version with `vcpkg x-add-version`, and commits that. Pushing is left to you.
set -euo pipefail

if [ $# -ne 3 ]; then
    echo "usage: $0 <port> <version> <commit-or-ref>" >&2
    exit 1
fi

cd "$(dirname "$0")"

port="$1"
version="$2"
ref="$3"
dir="ports/$port"
manifest="$dir/vcpkg.json"
portfile="$dir/portfile.cmake"

[ -f "$manifest" ] && [ -f "$portfile" ] || { echo "no port at $dir" >&2; exit 1; }
git diff --quiet -- versions && git diff --cached --quiet -- versions || { echo "versions/ has uncommitted changes" >&2; exit 1; }

# A branch or tag name is resolved to the commit it points at right now
url=$(sed -n 's/^\s*URL\s\+\(\S\+\).*/\1/p' "$portfile" | head -1)
if [[ "$ref" =~ ^[0-9a-f]{40}$ ]]; then
    sha="$ref"
else
    # An annotated tag lists the tag object first; its "^{}" line is the commit it points at
    sha=$(git ls-remote "$url" "$ref" "$ref^{}" | awk '/\^\{\}$/ { peeled = $1 } NR == 1 { first = $1 } END { print peeled ? peeled : first }')
    [ -n "$sha" ] || { echo "could not resolve '$ref' in $url" >&2; exit 1; }
fi

jq --arg v "$version" '.version = $v | del(.["port-version"])' "$manifest" > "$manifest.tmp"
mv "$manifest.tmp" "$manifest"
vcpkg format-manifest "$manifest"
sed -i "s/^\(\s*REF\s\+\)\S\+/\1$sha/" "$portfile"

git add -- "$dir"
if ! git diff --cached --quiet -- "$dir"; then
    git commit -m "$port $version" -- "$dir"
fi

# x-add-version won't create the baseline for a brand-new registry
if [ ! -f versions/baseline.json ]; then
    mkdir -p versions
    echo '{ "default": {} }' > versions/baseline.json
fi
vcpkg x-add-version "$port" --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions
git add -- versions
if ! git diff --cached --quiet -- versions; then
    git commit -m "$port $version: add version" -- versions
fi

echo
echo "Released $port $version (source $sha)"
echo "Next: git push, then set \"baseline\": \"$(git rev-parse HEAD)\" in projects that should get it"
