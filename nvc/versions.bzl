# SPDX-License-Identifier: Apache-2.0
"""Where the published binaries are, and what they hash to.

One entry per NVC version this module has released. The URL is a
release asset of this repository; the checksum is the one the release
notes give, as the release workflow measured it. Copy it from there,
not from a local build: a local build makes a different tarball.
"""

# The version served when a consumer names none.
DEFAULT_NVC_VERSION = "1.22.0-324ed157"

NVC_BINARIES = {
    "1.22.0-324ed157": {
        "linux_x86_64": struct(
            url = "https://github.com/filmil/bazel_toolchains_nvc/releases/download/nvc-1.22.0-324ed157/nvc-1.22.0-324ed157-linux-x86_64.tar.gz",
            sha256 = "6e0fed66e96cdf2b4c4fb1f35c5e195dd3ce2649952916ad0e4e6de65ccf1197",
        ),
    },
}
