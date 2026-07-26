# 当前维护交接

最后更新：2026-07-26

本文档是精简、持续演进的交接记录，而非历史流水账。状态推进时替换过时内容；只保留影响下一步的决策与证据。
稳定策略位于 `../AGENTS.md`。

## 仓库状态

- 工作区：`C:\Users\hz\home\repository\gcc12-toolset-el7`
- GitHub：`hzqmwne/gcc12-toolset-el7`
- 分支：`main`
- 当前 HEAD：`f67fecc ci: validate RPM spec dependency invariants`
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
- 最新 full Run `30199711627` 针对 `f67fecc` 已启动（`jobs=4`、`free_disk=true`、`trace=false`）；
  用户会在完成后通知。不要频繁轮询。
- 若该 full 失败，优先下载失败 job 的精简日志；若成功，更新本节并评估是否创建新发布标签（仅限明确请求）。
