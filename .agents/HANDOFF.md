# Current maintenance handoff

Last updated: 2026-07-26

This is a compact, evolving handoff rather than a transcript. Replace stale
status when work advances; preserve only decisions and evidence that affect the
next action. Stable policy belongs in `../AGENTS.md`.

## Repository state

- Workspace: `C:\Users\hz\home\repository\gcc12-toolset-el7`
- GitHub: `hzqmwne/gcc12-toolset-el7`
- Branch: `main`
- Current pushed HEAD: `5e41bc0 feat: add DTS-style make toolchain`
- Worktree was clean when this handoff was written.
- `v1.0.0` is immutable.

Recent relevant commits:

- `5e41bc0 feat: add DTS-style make toolchain`
- `fa5953d ci: add preflight validation mode`
- `41b618f ci: split prerequisite and gcc builds`
- `5c8551c fix: create private isl install directory`
- `6594891 fix: expose private isl runtime`
- `7390d7b fix: build private isl prerequisite`

## Implemented design

- CI has `preflight`, `prerequisites`, and `full` manual modes.
- The build is split into prerequisite RPMs and GCC RPMs with artifact transfer.
- Runtime/binutils/gcc core spec Releases are currently synchronized at 7.
- GNU Make 4.3 source is SHA-256 locked and a new
  `gcc12-toolset-make-4.3-1` spec exists.
- `gcc12-toolset-toolchain` is a DTS-style meta package requiring runtime,
  binutils, GCC, G++, and toolset Make.
- GCC no longer has a runtime dependency on the system `make` package.
- CMake is intentionally not in the core meta package.

## Two latest failed runs

### Run 30141719842 at commit fa5953d

URL: https://github.com/hzqmwne/gcc12-toolset-el7/actions/runs/30141719842

- Preflight, prerequisite RPM build, and the two-hour GCC RPM build succeeded.
- The clean CentOS 7 install succeeded.
- `tests/check-rpm-isolation.sh` succeeded, so the earlier RPM capability
  false-positive is no longer the active blocker.
- Verification then failed in `tests/check-abi.sh`:
  `cc1plus: error while loading shared libraries: libisl.so.23`.
- Cause: `check-abi.sh` invokes the absolute toolset `g++` without first
  activating the SCL environment. `libisl.so.23` is deliberately private under
  `/opt/gcc12-toolset/root/usr/lib/gcc/x86_64-redhat-linux/12.2.1`; the enable
  script adds that directory to `LD_LIBRARY_PATH`.
- Other GCC prerequisites do not expose the same symptom because GMP, MPFR,
  MPC, and zlib come from system packages and normal loader paths, while
  bootstrap libstdc++/libgcc are statically linked where configured. ISL is the
  intentionally private, non-system shared dependency.
- Under the repository's explicit SCL activation contract this points to a test
  invocation bug, not evidence that all compiler packaging is invalid. If
  direct absolute-path compiler use without activation were intended to be
  supported, then the packaging/link configuration would need a RUNPATH or a
  different private-library layout; that is not the current contract.

Recommended correction: source `/opt/gcc12-toolset/enable full` near the start
of `tests/check-abi.sh` before invoking the compiler. Keep the private ISL
directory assertions in profile tests.

### Run 30142368829 at commit 5e41bc0

URL: https://github.com/hzqmwne/gcc12-toolset-el7/actions/runs/30142368829

- Preflight succeeded.
- The prerequisite job failed while building the new Make RPM; GCC did not run.
- EL7's RPM `%configure` macro appended its own `/usr` prefix after the custom
  argument. The log proves Make installed into
  `BUILDROOT/gcc12-toolset-make-.../usr`, not the toolset prefix.
- `%check` correctly failed because
  `/opt/gcc12-toolset/root/usr/bin/make` did not exist.
- The install also produces `include/gnumake.h`, which the current `%files`
  list does not own and would become the next packaging error.

Recommended correction in `gcc12-toolset-make.spec`:

- call `./configure --prefix=%{toolset_prefix} --disable-nls` directly instead
  of `%configure`;
- add `%{toolset_prefix}/include/gnumake.h` to `%files`;
- retain Make Release 1 because no successful/published Make RPM exists yet.

## Next execution sequence

1. Apply both corrections above with `apply_patch`.
2. Run shell syntax checks, repository encoding/LF checks, `git diff --check`,
   and local preflight when Python is available.
3. Commit and push `main`.
4. Dispatch `Build and Release` in `prerequisites` mode first. Inspect it once;
   do not poll frequently.
5. If prerequisites succeeds, dispatch one `full` run with `jobs=4`,
   `free_disk=true`, and `trace=false`.
6. Do not re-run failed jobs from either old run: they belong to older commits,
   and the latest run has no valid prerequisite artifact.

After the next milestone, replace this failure section with the new commit,
run IDs, results, and remaining blocker rather than appending a full history.

