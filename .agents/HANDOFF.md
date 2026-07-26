# 当前维护交接

最后更新：2026-07-26

本文档是精简、持续演进的交接记录，而非历史流水账。状态推进时替换过时内容；只保留影响下一步的决策与证据。
稳定策略位于 `../AGENTS.md`。

## 仓库状态

- GitHub：`hzqmwne/gcc12-toolset-el7`
- 分支：`main`
- 当前 HEAD：`00772f1 docs: update maintenance handoff`
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
  GCC 12.2.1 的 `<stacktrace>` 中 `basic_stacktrace::max_size()` 访问了不存在的 `_M_alloc` 成员。
  修复应避免该已知缺陷路径，保留 `current()`、`empty()` 与 `size()` 的编译和运行覆盖；该测试修复
  不改变 RPM 载荷，core Release 无需递增。
- `1458c82` 以 `current()`、`empty()` 和 `size()` 替换有缺陷的 `max_size()` 覆盖路径；本地 preflight
  与 `git diff --check` 已通过。Full Run `30205860661` 已针对该提交以默认输入启动；不要频繁轮询。
- 若该 run 成功，更新本节；若失败，优先只读取失败 job 的精简日志。除非收到明确发布请求，不创建或移动发布标签。
