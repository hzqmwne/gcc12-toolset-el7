# CentOS 7 GCC 12 完整工具集

本目录用于在固定的 CentOS 7.9/glibc 2.17 环境中构建一套隔离安装的 GCC 12 RPM。它使用一份 GCC/binutils，同时提供 `full` 和 `compat` 两个 C++ 开发 profile。

生成的工具集具有以下特征：

- 安装前缀：`/opt/gcc12-toolset/root/usr`；
- 不覆盖 `/usr/bin/gcc`、`/usr/bin/ld` 或 `/usr/lib64/libstdc++.so.6`；
- GCC 12.2.1 与 binutils 2.36.1 只安装一份；
- binutils 共享运行库位于独立的 common 目录，由两个 profile 共用；
- `full`：完整 `libstdc++.so.6.0.30`、`libstdc++.a`、dual ABI、默认 ABI 1；
- `compat`：DTS 12 patched headers、dual ABI 关闭、系统 `libstdc++.so.6` 和 `libstdc++_nonshared.a`；
- x86_64 主机同时支持 64 位与 `-m32` C/C++ 构建，两个 profile 都经过运行验收；
- 支持 LTO、pthread、OpenMP、Graphite/ISL、GNU IFUNC、GCC 插件和 GNU hash；
- Graphite 使用锁定并私有构建的 GCC upstream ISL 0.24，不依赖系统 `isl-devel`；
- 同时提供默认 BFD ld 与可通过 `-fuse-ld=gold` 选择的 gold linker；
- `full` profile 支持 ASan、UBSan、TSan、LSan 以及 C++23 `std::stacktrace`；
- 支持 `-static-libstdc++`；
- 支持命令启动子进程，也支持 `source` 在当前 shell 原地启用。

## 文档索引

- 构建、安装和测试：[`BUILD.md`](BUILD.md)
- 官方 DTS 与本工具集的兼容性边界：[`COMPATIBILITY.md`](COMPATIBILITY.md)

## 一键构建

宿主机只需要 Docker 和足够的 CPU、内存、磁盘：

```bash
cd gcc12-toolset-el7
./build-rpms.sh
```

指定并发数：

```bash
./build-rpms.sh --jobs 16
```

强制重建构建镜像：

```bash
./build-rpms.sh --rebuild-image
```

构建会下载并缓存源码到：

```text
cache/
```

RPM 和校验文件输出到：

```text
out/RPMS/
out/SRPMS/
out/SHA256SUMS.generated
out/SHA256SUMS.rpms
```

GCC 三阶段 bootstrap 以及第二套 compat libstdc++ 构建通常耗时较长。建议至少准备 16 GiB 内存和 80 GiB 可用磁盘。

## RPM 列表

```text
gcc12-toolset-runtime
gcc12-toolset-binutils
gcc12-toolset-gcc
gcc12-toolset-gcc-c++
gcc12-toolset-libgcc
gcc12-toolset-libstdc++
gcc12-toolset-libstdc++-devel
gcc12-toolset-libstdc++-static
gcc12-toolset-libstdc++-compat
```

安装全部二进制 RPM：

```bash
yum localinstall out/RPMS/*.rpm
```

## 使用

### 启动子进程或执行命令

```bash
gcc12-toolset-full bash
gcc12-toolset-compat bash
gcc12-toolset --profile=full g++ --version
gcc12-toolset --profile=compat cmake ..
```

无参数的 `gcc12-toolset` 默认使用 `full` profile。旧参数 `--runtime=private` 和 `--runtime=system` 分别作为 `full`、`compat` 的兼容别名保留。

### 在当前 shell 原地启用

与 devtoolset 的 `source` 用法类似，不必启动新 shell：

```bash
source /opt/gcc12-toolset/enable full
source /opt/gcc12-toolset/enable compat
```

也可以使用独立入口：

```bash
source /opt/gcc12-toolset/enable-full
source /opt/gcc12-toolset/enable-compat
```

重复 source 另一个 profile 会先移除前一个 profile 的路径，再原地切换。环境会设置 `CC`、`CXX` 和 `GCC12_TOOLSET_PROFILE`。

`compat` profile 使用由官方 DTS 12 补丁构建的第二套 C++ 头文件、`libstdc++_nonshared.a` 和分别指向 `/usr/lib64/libstdc++.so.6`、`/usr/lib/libstdc++.so.6` 的 64/32 位 linker script；GCC、binutils 和前端可执行文件仍与 `full` 共用。具体边界见 `COMPATIBILITY.md`。

32 位构建直接增加 `-m32`：

```bash
gcc12-toolset-full gcc -m32 application.c -o application-32
gcc12-toolset-compat g++ -m32 application.cc -o application-32
```

sanitizer 使用工具集自己的私有运行库，因此只在 `full` profile 中受支持：

```bash
gcc12-toolset-full gcc \
  -fsanitize=address,undefined -fno-omit-frame-pointer \
  application.c -o application-sanitized
```

## 推荐的 CentOS 7 发布方式

需要新 C++11 ABI，同时要求在未安装高版本 `libstdc++` 的 CentOS 7 上运行时，推荐：

```bash
gcc12-toolset-full g++ \
  -std=c++11 \
  -D_GLIBCXX_USE_CXX11_ABI=1 \
  -march=x86-64 -mtune=generic \
  -static-libstdc++ -static-libgcc \
  application.cc -o application
```

不要添加全静态 glibc 的 `-static`。glibc 保持动态链接，目标符号上限应为 `GLIBC_2.17`。

检查产物：

```bash
./tests/check-centos7-compat.sh ./application
```

## 安全和隔离

该工具集不会：

- 修改系统 `alternatives`；
- 覆盖系统 GCC、binutils、libgcc 或 libstdc++；
- 写入 `/etc/ld.so.conf.d`；
- 全局写入 `LD_LIBRARY_PATH`；
- 将私有库作为系统 RPM 依赖的替代品公开。

共享 binutils 运行库位于 `/opt/gcc12-toolset/root/usr/lib64/binutils`，两个
profile 都会像 SCL 一样通过 `LD_LIBRARY_PATH` 启用它。完整 GCC 12
`libgcc`/`libstdc++` 分别位于上一级 `lib64` 和 `lib`，只对 `full` profile
可见；`compat` profile 明确移除这两个路径并链接对应架构的系统 C++ 运行库。静态链接 C++ 运行库
的最终程序不依赖该环境。

## 当前状态

`v1.0.0` 已通过 GitHub Actions 在 CentOS 7 构建镜像中完成 bootstrap、
RPM 打包、全量安装和 C/C++ 编译运行验收。后续 Release 同时提供完整归档、
独立二进制 RPM、SRPM、SHA-256 清单和构建来源证明。

标签构建是正式发布的唯一入口；日常调试可在 Actions 页面手动启动
`Build and Release`，并选择构建并发度和 shell 跟踪。
