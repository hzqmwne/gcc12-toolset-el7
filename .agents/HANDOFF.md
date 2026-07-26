# 当前维护交接

最后更新：2026-07-26

本文档是精简、持续演进的交接记录，而非历史流水账。状态推进时替换过时内容；只保留影响下一步的决策与证据。
稳定策略位于 `../AGENTS.md`。

## 仓库状态

- 工作区：`C:\Users\hz\home\repository\gcc12-toolset-el7`
- GitHub：`hzqmwne/gcc12-toolset-el7`
- 分支：`main`
- 当前 HEAD：`2371bb7 fix: statically link GCC ISL`
- `v1.0.0` 不可变。

## 当前设计与证据

- CI 提供 `preflight`、`prerequisites` 与 `full`；前置 RPM 和 GCC RPM 通过同一提交 SHA 的工件传递。
- Make 4.3 直接使用工具集 prefix 配置，并在 RPM 中拥有 `include/gnumake.h`。
- ISL 0.24 在 GCC 构建目录中私有静态构建；GCC 前端不再打包或动态依赖 `libisl.so.23`。
  `tests/check-abi.sh` 直接调用绝对路径的工具集 `g++`，验证这一需求。
- runtime、binutils、gcc 三个 core spec 的 Release 已同步为 8；Make 保持未发布组件的 Release 1。
- 本机指定 Python 的仓库检查、WSL preflight 和 `git diff --check` 均已通过。

## CI 状态与下一步

- Run `30188359733` 针对旧提交 `f9a4f98` 调度；它可验证 Make 修复，但不能作为 `2371bb7` 的证据。
- 收到该运行结果后记录结论，但不要从它启动 full。
- 对 `2371bb7` 依次调度 `prerequisites`，成功后调度一次 `full`，输入固定为
  `jobs=4`、`free_disk=true`、`trace=false`。
- full 必须确认 Make prefix/`gnumake.h`、前端不含 `NEEDED libisl.so`，以及不激活环境下的 ABI 测试。
