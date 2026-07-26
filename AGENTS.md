# Repository maintenance contract

This file contains stable instructions for automated and human maintainers.
Read `.agents/HANDOFF.md` after this file for the current state and next task.
Update this file only when a durable policy changes; keep run-specific details
in the handoff.

## Scope and invariants

- Repository: `hzqmwne/gcc12-toolset-el7`; normal maintenance targets `main`.
- All text files must be UTF-8 with Unix LF endings.
- Build, RPM tests, consumer tests, and releases run only in GitHub Actions.
  Local work is limited to editing, static checks, commits, and pushes.
- Preserve manual `workflow_dispatch` modes and the `v*.*.*` tag release path.
- Release `v1.0.0` is immutable: never move, replace, or republish that tag or
  its assets.
- Preserve complete SCL/devtoolset activation semantics. Toolset binaries and
  private libraries are expected to work after an explicit launcher or
  `source /opt/gcc12-toolset/enable`; do not silently replace system tools.
- If an existing RPM payload changes, increment `Release` in all three core
  specs (`runtime`, `binutils`, and `gcc`) together and add matching changelog
  entries. A new, never-published component may start at Release 1.
- The supported core is C/C++, binutils, runtime activation, and GNU Make.
  Fortran is intentionally excluded. CMake is not part of the DTS 12 core
  toolchain meta package; add it only later as a separately scoped component.
- Normal in-scope edits, commits, pushes, manual Actions dispatches, and Actions
  inspection are authorized. Do not create or move release tags without a
  specific release request.

## Validation and CI feedback

Use the cheapest stage that can falsify the current hypothesis:

1. Run local static checks and `.github/scripts/preflight.sh` when the local
   environment supports it.
2. Use manual `preflight` for repository-only changes.
3. Use manual `prerequisites` for runtime, binutils, Make, source-lock, or
   prerequisite-stage changes.
4. Start `full` only after cheaper relevant checks pass, or when GCC/consumer
   behavior itself must be validated.
5. Re-run only failed jobs when their upstream artifacts are valid for the same
   commit. Never reuse artifacts from a different commit as release evidence.

Default manual full-build inputs are `jobs=4`, `free_disk=true`, and
`trace=false`. Avoid frequent polling: inspect once after dispatch, then wait
for a job boundary, a user request, or enough elapsed time to expect progress.
Prefer downloaded diagnostics or targeted failure-log tails over dumping an
entire multi-hour log into the conversation.

## Agent and model orchestration

Keep one primary agent responsible for repository mutations, integration,
commits, pushes, and CI dispatch. Use subagents only for concrete, bounded work
that can proceed independently, such as:

- read-only CI log triage for separate runs;
- auditing one spec or one test family;
- checking documentation or DTS feature parity;
- reviewing a prepared diff for missed packaging or release invariants.

Do not delegate the same files to multiple writing agents. By default,
subagents should return evidence, file/line references, and a concise proposed
change; the primary agent applies and validates the integrated patch. Two
parallel subagents are normally enough. Do not spawn a subagent merely to
summarize context or perform one quick search.

Cost-oriented model policy:

- Use a balanced model at low or medium reasoning for repository inventory,
  status checks, documentation, formatting, and known mechanical edits.
- Use the strongest coding model at high reasoning for RPM dependency design,
  GCC/binutils configuration, ABI/runtime isolation, release correctness, or a
  repeated CI failure whose cause is not yet established.
- Reserve xhigh/max/ultra reasoning for ambiguous cross-component failures,
  security/release incidents, or when high reasoning has already produced an
  incomplete diagnosis.
- Give subagents the smallest self-contained brief and only the recent turns
  they need. Prefer `fork_turns="none"` plus explicit paths, run IDs, known
  constraints, and the requested output for read-only audits. Use full-history
  forks only when the subtask genuinely depends on conversational nuance.

The long-lived primary conversation should retain decisions and integration
state, not raw logs. Put durable rules here and update `.agents/HANDOFF.md` at
milestones, before switching sessions, and whenever the current blocker or
next validation step changes.

