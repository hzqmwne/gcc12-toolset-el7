# 当前维护交接

最后更新：2026-07-26

本文档是精简、持续演进的交接记录，而非历史流水账。状态推进时替换过时内容；只保留影响下一步的决策与证据。
稳定策略位于 `../AGENTS.md`。

## 仓库状态

- GitHub：`hzqmwne/gcc12-toolset-el7`
- 分支：`main`
- 当前 HEAD：`766bf91 fix: apply stacktrace backport exactly`
- `v1.0.0` 不可变。

## 当前设计与证据

- CI 提供 `preflight`、`prerequisites` 与 `full`；前置 RPM 和 GCC RPM 通过同一提交 SHA 的工件传递。
- Make 4.3 直接使用工具集 prefix 配置，并在 RPM 中拥有 `include/gnumake.h`。
- ISL 0.24 在 GCC 构建目录中私有静态构建；GCC 前端不再打包或动态依赖 `libisl.so.23`。
  `tests/check-abi.sh` 直接调用绝对路径的工具集 `g++`，验证这一需求。
- runtime、binutils、gcc 三个 core spec 的 Release 已同步为 9；Make 保持未发布组件的 Release 1。
- 本机指定 Python 的仓库检查、WSL preflight 和 `git diff --check` 均已通过。

## CI 状态与下一步

- Full Run `30189474673`（`1301d8f`）在构建全部成功后，于干净 CentOS 7 安装失败：noarch
  `gcc12-toolset-toolchain` 错误依赖 `gcc12-toolset-runtime(x86-64)`。`c630ed0` 已修复为
  架构无关依赖，三个 core Release 同步为 9。
- `f67fecc` 新增 preflight：core Release 同步，以及 noarch spec 不得对自身主包名使用 `%{?_isa}`。
- Full Run `30199711627`（`f67fecc`）的前置 RPM、GCC RPM、干净 CentOS 7 安装、RPM 隔离、ABI、
  profile、运行时和 multilib 检查均成功。失败仅在 `smoke-features.sh` 的 C++23 stacktrace smoke：
  GCC 12.2.1 的 `<stacktrace>` 中 `basic_stacktrace::max_size()` 将 allocator 错误地引用为
  `_M_impl._M_alloc`，而它属于外层 `basic_stacktrace`。
- DTS 12 的公开 `c8s` 与 `c10s` 源包补丁集没有 stacktrace 回避或修复补丁；它们只处理兼容 ABI、
  nonshared archive 和 DTS 测试条件。应采用最小源码 backport，恢复 `max_size()` smoke 覆盖。
  该载荷变更需要 runtime、binutils 和 gcc 三个 core spec 同步递增 Release 并添加 changelog。
- 运行 `30205860661` 针对已废弃的测试绕过提交启动，已取消。`abf99f3` 已添加源码 backport，恢复
  `max_size()` smoke；core Release 均为 10。Run `30206229733` 的 prerequisites 成功；Run
  `30206231380` 在 GCC `%prep` 失败。补丁目标行正确，但 hunk 的周边上下文与锁定 DTS 源快照不一致，
  严格 `--fuzz=0` 拒绝应用。改用仅匹配目标行的零上下文 hunk；同时将新增 changelog 的 weekday 改正。
- `766bf91` 的零上下文临时补丁尚未作为最终形式保留。已根据 GCC 12.2 发布分支中锁定 DTS 源快照的
  真实第 471–480 行上下文重写补丁，并在 spec 和补丁头中记录其 backport 状态。手动 Actions 的 `jobs`
  输入现为自由文本，无范围校验；公共
  `ubuntu-24.04` runner 为 4 vCPU/16 GiB，默认值保留为 4，较高值会过度订阅而非合理加速。
- Runs `30206693114` 和 `30206695774` 针对旧零上下文补丁启动，已取消。后续：运行 preflight，提交推送，
  并以默认输入重新调度 prerequisites 与 full。不要频繁轮询；除非收到明确发布请求，不创建或移动发布标签。
