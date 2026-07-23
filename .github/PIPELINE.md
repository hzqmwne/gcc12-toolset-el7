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
源文件与 RPM 校验清单、构建元数据和文档。

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
磁盘/内存快照、Docker 信息和 `out/` 中已经生成的清单。GitHub 的 “Re-run
failed jobs” 可在不重复成功 job 的情况下重跑。

发布归档可用以下命令验证来源：

```bash
gh attestation verify gcc12-toolset-el7-1.0.0-x86_64.tar.gz \
  --repo OWNER/gcc12-toolset-el7
sha256sum -c SHA256SUMS
```
