# OCI references must be lowercase and GHCR keeps the owner's casing (Star0x00),
# so the registry namespace is spelled out here instead of being interpolated.
registry := "ghcr.io/star0x00"
platform := "linux/amd64"

# Builds always are --pull=always and --platform linux/amd64 so that a local run
# and a CI run produce the same thing. CI drives these recipes; the only extra
# work it does itself is the registry login and the pushes.

# Build the router bootc image (optional 2nd argument adds a tag)
build tag="latest" sha="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    tags=(-t "{{registry}}/router-bootc:{{tag}}")
    if [ -n "{{sha}}" ]; then tags+=(-t "{{registry}}/router-bootc:{{sha}}"); fi
    podman build --pull=always --platform {{platform}} "${tags[@]}" .

# Build the dsh image the dsh-web quadlet runs (optional argument adds a tag)
dsh tag="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{justfile_directory()}}"
    v=$(just dsh-version)
    tags=(-t "{{registry}}/dsh:$v" -t "{{registry}}/dsh:$(just dsh-minor)")
    if [ -n "{{tag}}" ]; then tags+=(-t "{{registry}}/dsh:{{tag}}"); fi
    podman build --pull=always --platform {{platform}} \
        -f Containerfile.dsh \
        --build-arg DSH_VERSION="$v" \
        "${tags[@]}" .

# Print the full dsh version declared in Containerfile.dsh
dsh-version:
    @grep -m1 '^ARG DSH_VERSION=' Containerfile.dsh | cut -d= -f2

# Print the minor dsh tag the dsh-web quadlet pins (0.2.1 out of 0.2.1-rc.5)
dsh-minor:
    @grep -m1 '^ARG DSH_VERSION=' Containerfile.dsh | cut -d= -f2 | cut -d- -f1
