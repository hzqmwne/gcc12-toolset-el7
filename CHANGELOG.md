# Changelog

本项目使用语义化版本，发布标签格式为 `vMAJOR.MINOR.PATCH`。

## 1.0.1 - 2026-07-24

- 在独立的全新 CentOS 7 开发机镜像中全量安装 RPM，验证系统 GCC 4.8.5
  与 GCC 12 按需启用、互不覆盖，并执行 C/C++ 编译、ABI、profile、
  运行时和 RPM 隔离测试。
- Release 同时发布完整归档、独立二进制 RPM、SRPM 和统一 SHA-256 清单。
- 对清单中的完整归档和每个 RPM/SRPM 生成构建来源证明。
- 增加构建期间的主机和容器资源采样，为并发度调优提供实测数据。
- 根据 4 vCPU runner 的峰值资源实测，将默认构建并发从 2 调整为 4。
- 将 RPM 构建与消费者验收拆分为独立 job，使验收失败可以复用已构建 RPM。
- 更新 GitHub Actions 到最新稳定版本并继续固定不可变提交 SHA。
- RPM Release 统一升级到 `2`，确保重新发布的包具有唯一 NEVRA。

## 1.0.0 - 2026-07-24

- 首次发布 CentOS 7 GCC 12 隔离工具集。
- 提供 `full` 与 `compat` 两种 C++ profile。
- 增加 GitHub Actions 构建、验收、制品证明与 Release 发布。
