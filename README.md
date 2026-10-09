<!-- SPDX-License-Identifier: Apache-2.0 -->
# bazel_toolchains_nvc

[![release](https://github.com/filmil/bazel_toolchains_nvc/actions/workflows/release.yml/badge.svg)](https://github.com/filmil/bazel_toolchains_nvc/actions/workflows/release.yml)
[![registry](https://github.com/filmil/bazel_toolchains_nvc/actions/workflows/publish.yml/badge.svg)](https://github.com/filmil/bazel_toolchains_nvc/actions/workflows/publish.yml)

An NVC toolchain for [rules_nvc](https://github.com/filmil/bazel_rules_nvc),
from a prebuilt binary that has NVC's LLVM code generator.


## Why

The `nvc` module that rules_nvc builds from source leaves LLVM out. Such an
NVC interprets every design it simulates. NVC's own x86-64 code generator is
switched off in its source, and NVC stops at start-up if it is switched back
on. An NVC built with LLVM compiles the design to machine code instead.

Measured on the f1 RISC-V core, running the architectural test `I-add-00`
(19,986 cycles):

    NVC from the nvc module (interpreter)    about 8 min
    this binary (LLVM)                       48 s

LLVM is large, and building it, or linking NVC against it, does not belong in
every build. So NVC is built once, in CI, with LLVM linked in, and published as
a release. This module hands that binary to rules_nvc's toolchain type.


## Using it

```python
bazel_dep(name = "bazel_toolchains_nvc", version = "0.1.0")

nvc_binary = use_extension(
    "@bazel_toolchains_nvc//nvc:extension.bzl",
    "nvc_binary",
)
use_repo(nvc_binary, "nvc_prebuilt")

register_toolchains("@nvc_prebuilt//:toolchain")
```

A toolchain the root module registers takes precedence over the one rules_nvc
registers, so nothing else changes: the rules are still rules_nvc's, and only
where NVC comes from is different. This needs rules_nvc 4.7.0 or newer, the
first whose toolchain type other modules may use.

To pick a published version other than the default:

```python
nvc_binary.use(version = "1.22.0-324ed157")
```

The module registers no toolchain of its own, as bazel_toolchains_verilator
does not: registering one would make every build that depends on this module
fetch the binary.


## What is in a release

A release `nvc-<version>` has two assets:

    nvc-<version>-linux-x86_64.tar.gz   bin/nvc, and lib/nvc: the standard
                                        libraries (std, ieee, nvc, ...),
                                        compiled by that binary
    nvc-<version>-source.tar.gz         the NVC source it was built from

The binary is NVC at the commit `package/versions.txt` names, with LLVM from
an official LLVM release. LLVM, the C++ runtime, zlib, zstd, libffi and
terminfo are linked in, so it needs only the C library, glibc 2.31 or newer.
It is built in an Ubuntu 20.04 container for that reason.


## How a release is made

1. Add a line to `package/versions.txt`: the version, the NVC commit, and the
   LLVM version.
2. Tag it, and push the tag:

        git tag nvc-1.22.0-324ed157 && git push --tags

   The release workflow runs `package/build.sh` in the container. The script
   checks the binary before it is published: that it needs only the C
   library, that it reports LLVM, and that it simulates a design.
3. Copy the checksum from the release notes into `nvc/versions.bzl`.
4. Release the module with a `v<version>` tag. Then publish it to
   filmil/bazel-registry by hand: a release that a workflow makes does not
   start other workflows, so the publication does not start by itself.

        gh workflow run publish.yml -R filmil/bazel_toolchains_nvc \
            -f tag_name=v<version>

   It opens a pull request in filmil/bazel-registry; merge it.

To build the same tarball locally:

    docker run --rm -v "$PWD:/work" ubuntu:20.04 \
        /work/package/build.sh 1.22.0-324ed157


## Licenses

This repository is under the Apache License 2.0. NVC is under the GNU General
Public License, version 3; its `COPYING` is in every binary tarball, and its
source is in every release. LLVM is under the Apache License 2.0 with LLVM
exceptions.
