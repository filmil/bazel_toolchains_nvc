#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
#
# Builds NVC with its LLVM code generator, linked so that it needs only the C
# library at run time, and packs it into a tarball beside a tarball of the
# source it was built from.
#
# Runs inside an Ubuntu 20.04 container, so the binary needs glibc 2.31 or
# newer and nothing else. From the repository root:
#
#   docker run --rm -v "$PWD:/work" ubuntu:20.04 /work/package/build.sh VERSION
#
# VERSION is a line of `package/versions.txt`. The tarballs land in /work/out:
#
#   nvc-VERSION-linux-x86_64.tar.gz     bin/nvc, lib/nvc (std, ieee, ...)
#   nvc-VERSION-source.tar.gz           the NVC source, as built
set -o errexit -o nounset -o pipefail

VERSION="${1:?usage: build.sh VERSION}"
read -r _ COMMIT LLVM_VERSION < <(grep -E "^${VERSION//./\\.} " /work/package/versions.txt) || {
    echo "build.sh: ${VERSION} is not in package/versions.txt" >&2
    exit 1
}
LLVM_NAME="clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-18.04"
LLVM_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${LLVM_NAME}.tar.xz"
NAME="nvc-${VERSION}-linux-x86_64"
PREFIX="/opt/${NAME}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq build-essential autoconf automake flex bison \
    pkg-config curl xz-utils ca-certificates \
    zlib1g-dev libzstd-dev libffi-dev libtinfo5 libtinfo-dev > /dev/null

# Link zlib, zstd, libffi and terminfo statically: with their shared
# objects gone, the linker takes the archives. `llvm-config` itself
# still runs against the shared terminfo of `libtinfo5`.
rm -f /usr/lib/x86_64-linux-gnu/libz.so \
      /usr/lib/x86_64-linux-gnu/libzstd.so \
      /usr/lib/x86_64-linux-gnu/libffi.so \
      /usr/lib/x86_64-linux-gnu/libtinfo.so

mkdir -p /build /work/cache /work/out
cd /build
if [ ! -f "/work/cache/${LLVM_NAME}.tar.xz" ]; then
    curl -sSL -o "/work/cache/${LLVM_NAME}.tar.xz" "${LLVM_URL}"
fi
# A rootless container cannot give the files their owners from the archive.
tar --no-same-owner -xf "/work/cache/${LLVM_NAME}.tar.xz"
LLVM_CONFIG="/build/${LLVM_NAME}/bin/llvm-config"

curl -sSL -o "/work/out/nvc-${VERSION}-source.tar.gz" \
    "https://github.com/nickg/nvc/archive/${COMMIT}.tar.gz"
tar --no-same-owner -xzf "/work/out/nvc-${VERSION}-source.tar.gz"
cd "nvc-${COMMIT}"
autoreconf --force --install -I m4 > /dev/null
mkdir build && cd build
../configure --prefix="${PREFIX}" \
    --enable-llvm --enable-static-llvm --with-llvm="${LLVM_CONFIG}" \
    --disable-tcl --disable-lto \
    LDFLAGS="-static-libstdc++ -static-libgcc"
make -j"$(nproc)"
make install
cp ../COPYING "${PREFIX}/"

# The checks a release must pass. The binary needs nothing but the C
# library, it says it uses LLVM, and it simulates a design.
echo "== ldd ${PREFIX}/bin/nvc"
ldd "${PREFIX}/bin/nvc" | tee /tmp/ldd.txt
if grep -vE 'linux-vdso|libc\.so|libm\.so|libdl\.so|libpthread\.so|librt\.so|ld-linux' /tmp/ldd.txt; then
    echo "build.sh: the binary needs more than the C library" >&2
    exit 1
fi
"${PREFIX}/bin/nvc" --version | tee /tmp/version.txt
grep -q "Using LLVM ${LLVM_VERSION}" /tmp/version.txt
mkdir -p /tmp/smoke && cd /tmp/smoke
cat > smoke.vhd <<'VHDL'
entity smoke is
end entity;
architecture sim of smoke is
begin
    process
    begin
        report "smoke test ran";
        wait;
    end process;
end architecture;
VHDL
"${PREFIX}/bin/nvc" -a smoke.vhd -e smoke -r 2>&1 | tee /tmp/smoke.txt
grep -q "smoke test ran" /tmp/smoke.txt

tar -C /opt -czf "/work/out/${NAME}.tar.gz" "${NAME}"
cd /work/out
sha256sum "${NAME}.tar.gz" "nvc-${VERSION}-source.tar.gz"
