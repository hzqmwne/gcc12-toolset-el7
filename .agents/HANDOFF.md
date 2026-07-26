# 当前维护交接

最后更新：2026-07-26

本文档是精简、持续演进的交接记录，而非历史流水账。状态推进时替换过时内容；只保留影响下一步的决策与证据。
稳定策略位于 `../AGENTS.md`。

## 仓库状态

- GitHub：`hzqmwne/gcc12-toolset-el7`
- 分支：`main`
- 当前 HEAD：`f703ede docs: record stacktrace validation run`
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
- 运行 `30205860661` 针对已废弃的测试绕过提交启动，已取消。后续：静态验证 backport 补丁、运行 preflight，
  提交并推送；然后以默认输入调度 full。除非收到明确发布请求，不创建或移动发布标签。
