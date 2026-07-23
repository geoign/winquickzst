# Third-party notices

`bin/fast-tarzst.exe` was built from the local `fast-tarzst` Rust project at commit `a764cc94f2128592404174036f43b9fd9944a62f`.

- Binary SHA-256: `E1F3508610CD3DCE91BED9493AFA1F3869BA6E127089EA4DA355E48F8DFACB70`
- Version: `0.6.1`
- Target: `x86_64-pc-windows-msvc`
- `fast-tarzst` license: MIT

The build vendors `tar` crate 0.4.46 under its original MIT OR Apache-2.0
license. Local performance extensions add a reusable 8 MiB large-entry copy
buffer and a Windows-specific read-ahead pipeline: a streaming directory
scan feeds a worker pool that reads files of every size in chunks through a
shared buffer pool, bounded by a byte budget that defaults to one eighth of
physical RAM (512 MiB to 4 GiB). Entries are written as their data becomes
ready (`--ordered` restores deterministic order). Tar archive compatibility
is unchanged. The vendored source and patch description are included in the
`fast-tarzst` source repository.

The binary build uses the following Rust crates under the license expressions published in their Cargo packages:

| Package | Version | License |
|---|---:|---|
| anyhow | 1.0.104 | MIT OR Apache-2.0 |
| autocfg | 1.5.1 | Apache-2.0 OR MIT |
| cc | 1.3.0 | MIT OR Apache-2.0 |
| cfg-if | 1.0.4 | MIT OR Apache-2.0 |
| chrono | 0.4.45 | MIT OR Apache-2.0 |
| ctrlc | 3.5.2 | MIT OR Apache-2.0 |
| dunce | 1.0.5 | CC0-1.0 OR MIT-0 OR Apache-2.0 |
| filetime | 0.2.29 | MIT OR Apache-2.0 |
| find-msvc-tools | 0.1.9 | MIT OR Apache-2.0 |
| getrandom | 0.4.3 | MIT OR Apache-2.0 |
| jobserver | 0.1.35 | MIT OR Apache-2.0 |
| num-traits | 0.2.19 | MIT OR Apache-2.0 |
| pkg-config | 0.3.33 | MIT OR Apache-2.0 |
| shlex | 2.0.1 | MIT OR Apache-2.0 |
| tar | 0.4.46 | MIT OR Apache-2.0 |
| windows-link | 0.2.1 | MIT OR Apache-2.0 |
| windows-sys | 0.59.0 | MIT OR Apache-2.0 |
| windows-sys | 0.61.2 | MIT OR Apache-2.0 |
| zstd | 0.13.3 | MIT |
| zstd-safe | 7.2.4 | MIT OR Apache-2.0 |
| zstd-sys | 2.0.16+zstd.1.5.7 | MIT OR Apache-2.0 |

## Vendored Zstandard license

The Zstandard implementation bundled by `zstd-sys` is distributed under the following BSD 3-Clause license:

> Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
>
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
> - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
> - Neither the name Facebook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
