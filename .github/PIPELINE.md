# GitHub Actions 流水线

平台相关实现全部位于 `.github/`，不修改工具链的 Docker、RPM spec、构建脚本和测试逻辑。

## 流水线分层

- `CI`：每次 push 和 pull request 执行 UTF-8/LF、SemVer、Bash 语法、
  ShellCheck 和 Dockerfile 静态检查。
- `Build and Release`：手动触发时构建并上传临时制品；推送与 `VERSION`
  一致的 `vMAJOR.MINOR.PATCH` 标签时，在构建和验收通过后创建 GitHub
  Release。

完整构建使用固定的 `ubuntu-24.04` runner，任务上限为 360 分钟。默认并发为
2，降低 16 GiB 标准 runner 的内存压力。发布制品包括二进制 RPM、SRPM、
源文件与 RPM 校验清单、构建元数据和文档。完整归档、每个二进制 RPM 和
每个 SRPM 都作为独立 Release 资产发布，并由同一份 `SHA256SUMS` 覆盖。

RPM 构建完成后，流水线另外构建一个不含系统 GCC/G++ 的干净 CentOS 7
消费者镜像。它预装 glibc 和系统 libstdc++ 的开发基线，以禁用 YUM
仓库的方式全量安装本次生成的 RPM，然后执行 C/C++ 编译、ABI、profile、
运行时和 RPM 隔离测试。这样构建镜像中的依赖不会掩盖成品 RPM 的安装问题。

## 版本管理

`VERSION` 是仓库发布版本的唯一来源，使用稳定 SemVer。GCC、binutils 和
RPM Release 继续由各自 spec 独立管理，避免把平台发布版本混入 RPM 主逻辑。

发布步骤：

1. 更新 `VERSION` 与 `CHANGELOG.md`；
2. 合并并等待 `CI` 成功；
3. 创建同名标签，例如 `git tag -a v1.0.0 -m "v1.0.0"`；
4. push 标签；`Build and Release` 自动完成构建、安装验收、打包、证明和发布。

## 调试

在 Actions 页面手动运行 `Build and Release`：

- `jobs` 可选 1、2 或 4；内存不足时选择 1；
- `trace` 会用 `bash -x` 输出主机侧构建脚本跟踪；
- `free_disk` 会清理 runner 上与本项目无关的预装 SDK，给 GCC bootstrap
  留出空间。

无论成功或失败，流水线都会上传 `diagnostics-*`，其中包含完整控制台日志、
磁盘/内存快照、构建期间每 15 秒一次的容器资源采样、Docker 信息和 `out/`
中已经生成的清单。应先用手动构建比较 `jobs=2` 与 `jobs=4` 的耗时和峰值
内存，再修改标签构建的默认并发。GitHub 的 “Re-run failed jobs” 可在不
重复成功 job 的情况下重跑。

发布归档可用以下命令验证来源：

```bash
gh attestation verify gcc12-toolset-el7-1.0.1-x86_64.tar.gz \
  --repo OWNER/gcc12-toolset-el7
sha256sum -c SHA256SUMS
```
