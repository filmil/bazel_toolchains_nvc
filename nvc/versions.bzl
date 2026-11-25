# SPDX-License-Identifier: Apache-2.0
"""Where the published binaries are, and what they hash to.

One entry per NVC version this module has released. The URL is a
release asset of this repository. From 1.22.0-324ed157-r2 on, the
checksum is the sha256sum of the downloaded tarball after its build
provenance attestation checked out (README.md, "How a release is
made"); a local build makes a different tarball.
"""

# The version served when a consumer names none.
# 1.22.0-324ed157-r2 is the same NVC as 1.22.0-324ed157, with an attested
# build.
DEFAULT_NVC_VERSION = "1.22.0-324ed157-r2"

NVC_BINARIES = {
    # The first release. It has no build provenance attestation; its
    # checksum was copied from the release notes. Kept for those who pin
    # it; -r2 below is the same NVC with an attested build.
    "1.22.0-324ed157": {
        "linux_x86_64": struct(
            url = "https://github.com/filmil/bazel_toolchains_nvc/releases/download/nvc-1.22.0-324ed157/nvc-1.22.0-324ed157-linux-x86_64.tar.gz",
            sha256 = "6e0fed66e96cdf2b4c4fb1f35c5e195dd3ce2649952916ad0e4e6de65ccf1197",
        ),
    },
    # Verified 2026-11-24 PST, for the binary tarball below and for the
    # release's source tarball (the GPL source, not a platform binary):
    #   gh attestation verify <file> --repo filmil/bazel_toolchains_nvc \
    #     --signer-workflow filmil/bazel_toolchains_nvc/.github/workflows/release.yml \
    #     --source-ref refs/tags/nvc-1.22.0-324ed157-r2
    # The sha256 below is sha256sum of the verified binary tarball and
    # matches GitHub's digest of that asset.
    "1.22.0-324ed157-r2": {
        "linux_x86_64": struct(
            url = "https://github.com/filmil/bazel_toolchains_nvc/releases/download/nvc-1.22.0-324ed157-r2/nvc-1.22.0-324ed157-r2-linux-x86_64.tar.gz",
            sha256 = "046191b1d06e23cd3fea57df050ac5b99936d18516434d900ffb4aa61520cbdd",
        ),
    },
}
