# 构建、打包与验收

## 1. 构建基线

构建镜像固定为：

```text
CentOS 7.9.2009
x86_64
系统 GCC 4.8.5 作为 bootstrap 编译器
glibc 2.17
```

工具集源码：

```text
GCC:      gcc-12.2.1-20221121.tar.xz
binutils: binutils-2.36.1.tar.xz
```

GCC 源码来自 CentOS 归档 `devtoolset-12-gcc-12.2.1-4.1.el7` 使用的快照。`full` 构建保持完整 dual ABI；`compat` 源码副本应用同一归档提交中的 `gcc12-libstdc++-compat.patch`，生成官方 DTS 风格的 patched headers 和 `libstdc++_nonshared48.a`。

## 2. 源码校验

历史 CentOS lookaside 元数据只公布 SHA-1：

```text
gcc-12.2.1-20221121.tar.xz
  ecaedb16188931aa35d627f2edb28dbab5f8f3c1

binutils-2.36.1.tar.xz
  021c97cc0e751e989afb8db025fbd2ae48391831

gcc12-libstdc++-compat.patch
  SHA-256 7a5b89af6fc10a00e61b374b86c49591bd7696cc2b518f3ecad6568033967aa5
```

`fetch-sources.sh` 会：

1. 只允许 HTTPS；
2. 下载到临时 `.part` 文件；
3. 验证归档元数据中的 SHA-1；
4. 原子移动到缓存文件；
5. 生成 `cache/SHA256SUMS.generated`。

SHA-1 只用于匹配历史归档对象，不应被视为现代抗碰撞安全保证。第一次从可信网络取得源码后，应审核并把生成的 SHA-256 固定到内部源码仓库或制品库。生产构建建议断网使用已审核缓存。

手动准备离线源码时，把两个文件放到 `cache/`，脚本仍会验证历史哈希。

## 3. Docker 一键构建

```bash
./build-rpms.sh --jobs 8
```

执行顺序：

1. 构建固定 CentOS 7 RPM builder 镜像；
2. 获取并校验源码；
3. 构建并安装 `gcc12-toolset-runtime`；
4. 构建并安装私有 binutils；
5. 三阶段 bootstrap 完整 GCC 12；
6. 对源码副本应用 DTS 兼容补丁，精简构建 compat headers 与 nonshared archive；
7. 构建所有二进制 RPM 和 SRPM；
8. 导出 RPM SHA-256 清单。

环境变量：

```bash
JOBS=16 IMAGE=internal/gcc12-builder:el7 ./build-rpms.sh
```

脚本不会删除已有 `cache/`。`out/` 中的 RPM 子目录会在成功导出前重建；不要把需要保留的手工文件放在其中。

## 4. GCC 关键配置

`gcc12-toolset-gcc.spec` 使用：

```text
--enable-libstdcxx-dual-abi
--with-default-libstdcxx-abi=new
--enable-languages=c,c++,lto
--disable-multilib
--disable-libsanitizer
--with-arch=x86-64
--with-tune=generic
--with-boot-ldflags=-static-libstdc++ -static-libgcc
```

`full` profile 构建 GCC 12 自己的完整：

```text
libstdc++.so.6.0.30
libstdc++.a
libsupc++.a
```

`compat` profile 对独立源码副本应用固定 DTS 补丁，以 `--with-default-libstdcxx-abi=gcc4-compatible` 构建并安装：

```text
DTS patched headers
_GLIBCXX_USE_DUAL_ABI=0
libstdc++_nonshared.a（来自 nonshared48）
INPUT(/usr/lib64/libstdc++.so.6 -lstdc++_nonshared)
```

两者共用同一份 GCC/binutils 可执行文件。

## 5. 安装

复制 `out/RPMS/` 到 CentOS 7 目标机：

```bash
yum localinstall ./out/RPMS/*.rpm
```

检查系统工具未被覆盖：

```bash
/usr/bin/gcc --version
readlink -f /usr/lib64/libstdc++.so.6
```

检查两个 profile 和当前 shell 原地启用：

```bash
gcc12-toolset-full g++ --version
gcc12-toolset-compat g++ --version

source /opt/gcc12-toolset/enable full
echo "$GCC12_TOOLSET_PROFILE $CXX"
source /opt/gcc12-toolset/enable compat
echo "$GCC12_TOOLSET_PROFILE $CXX"
```

## 6. 基本验收

### 6.1 dual ABI

```bash
./tests/check-abi.sh
```

预期：

```text
_GLIBCXX_USE_DUAL_ABI=1
_GLIBCXX_USE_CXX11_ABI=1
GLIBCXX_3.4.30
CXXABI_1.3.13
```

并分别生成 ABI 0 与 ABI 1 的 `std::string` 符号。

### 6.2 双 profile 与原地 source

```bash
./tests/smoke-profiles.sh
```

它会验证 full/compat 原地切换、compat wrapper、系统 `libstdc++.so.6`、ABI 0 和 `GLIBCXX_3.4.19` 上限。

### 6.3 动态和静态运行

```bash
./tests/smoke-runtime.sh
```

它会验证 full 动态运行、ABI 1 静态 libstdc++ 链接，以及最终 ELF 不再 `NEEDED libstdc++.so.6`。

### 6.4 CentOS 7 符号上限

```bash
./tests/check-centos7-compat.sh /path/to/application
```

静态 C++ runtime 的发布产物应满足：

```text
无动态 GLIBCXX_*
无动态 CXXABI_*
GLIBC <= 2.17
```

## 7. GCC testsuite

RPM 构建中的 `%check` 只执行快速结构检查，不运行完整 GCC testsuite，因为后者耗时很长。正式发布前应在保留的构建容器中执行：

```bash
cd /build/rpmbuild/BUILD/gcc-12.2.1-20221121/obj
make -k check-gcc
make -k check-g++
make -k check-target-libstdc++-v3
```

收集：

```text
gcc/testsuite/gcc/gcc.sum
gcc/testsuite/g++/g++.sum
x86_64-redhat-linux/libstdc++-v3/testsuite/libstdc++.sum
```

需要审查 `FAIL`、`XPASS`、`UNRESOLVED`，并与同源码未修改的上游基线比较。不能只根据 `make check` 返回码判定成功。

compat 构建树还应检查补丁目标本身，并执行安装后的 profile 测试：

```bash
cd /build/rpmbuild/BUILD/gcc-12.2.1-20221121/obj-compat
make -k check-target-libstdc++-v3
cd /workspace
./tests/smoke-profiles.sh
```

上游 compat 构建树 testsuite 默认仍会测试构建树中的库；`smoke-profiles.sh` 才直接验证最终 linker script、CentOS 7 系统库和 `nonshared48` 的组合。

## 8. 推荐编译参数

C++11、ABI 1、CentOS 7 通用 CPU：

```text
-std=c++11
-D_GLIBCXX_USE_CXX11_ABI=1
-march=x86-64
-mtune=generic
-static-libstdc++
-static-libgcc
```

构建共享库时增加：

```text
-fPIC
```

不要使用：

```text
-march=native
-static
```

前者可能引入构建机专属指令，后者会完全静态链接 glibc，影响 NSS、DNS、locale、用户解析和动态加载。

## 9. 私有动态部署

如果不静态链接 libstdc++，目标机必须安装 `gcc12-toolset-libstdc++` 并通过 `full` profile 运行，或者把完整运行库放在应用私有目录并使用相对 RUNPATH：

```text
-Wl,-rpath,'$ORIGIN/../lib'
```

不要：

- 替换 `/usr/lib64/libstdc++.so.6`；
- 写入全局 `/etc/ld.so.conf.d`；
- 在系统 profile 全局设置私有 `LD_LIBRARY_PATH`。

## 10. RPM 隔离设计

私有库全部位于：

```text
/opt/gcc12-toolset/root/usr/lib64
```

spec 使用 RPM provides 过滤，避免私有 `libstdc++.so.6` 被误认为可满足系统包的运行时依赖。启动器只在子进程或当前显式 source 的 shell 中修改环境。

包拆分允许只安装运行时：

```text
gcc12-toolset-runtime
gcc12-toolset-libgcc
gcc12-toolset-libstdc++
```

开发机则安装全部包。

## 11. 常见问题

### 下载失败

CentOS 7 和 EPEL 7 已归档。确认构建环境可以访问：

```text
vault.centos.org
archives.fedoraproject.org
sources.stream.centos.org
ftp.gnu.org
```

生产环境应把这些内容同步到内部 HTTPS 镜像并修改 `sources.lock.sh` 与 Docker 仓库地址。

### bootstrap 内存不足

降低并发：

```bash
./build-rpms.sh --jobs 2
```

### 程序报告 `GLIBCXX_3.4.30 not found`

程序使用完整动态 GCC 12 libstdc++ 编译，却在运行时装载了系统库。使用 `full` profile、应用私有 RUNPATH，或重新以 `-static-libstdc++` 链接。

### 程序要求 `GLIBC_2.18` 以上

某个输入库、对象或 sysroot 来自比 CentOS 7 更新的系统。仅设置编译宏无法修复；必须在 CentOS 7 sysroot 中重新构建相关依赖。

### compat 模式仍然链接到完整私有 libstdc++

检查是否实际使用 compat wrapper：

```bash
source /opt/gcc12-toolset/enable compat
command -v g++
echo "$CXX"
```

两者都应指向 `/opt/gcc12-toolset/profiles/compat/bin/g++`。检查用户参数是否通过绝对路径绕过 wrapper，或是否显式添加了 full profile 的 `-L`/RUNPATH。
