# 兼容性模型

## 1. 为什么官方 devtoolset 可以“完整兼容”系统 libstdc++

这里的“完整兼容”需要准确理解。RHEL 7 Developer Toolset 的目标不是同时提供完整新 ABI 和系统库兼容，而是让高版本 GCC 生成的受支持程序继续使用 RHEL 7 的系统 C++ ABI。

它通过四个配套措施实现这个目标：

1. 继续动态链接 `/usr/lib64/libstdc++.so.6.0.19`；
2. 保留 GCC 4 时代的 `std::string`、`std::list` ABI；
3. 在安装头文件中关闭 dual ABI，固定 `_GLIBCXX_USE_CXX11_ABI=0`；
4. 用经过严格选择的 `libstdc++_nonshared.a` 补充少量系统库没有的新实现。

Developer Toolset 的 `libstdc++.so` 开发链接文件本质上是 linker script，逻辑近似：

```text
INPUT(/usr/lib64/libstdc++.so.6 -lstdc++_nonshared)
```

因此 DTS 的兼容性来自“始终以系统旧运行库为 ABI 基线”，而不是来自高版本完整 `libstdc++.so` 可以任意切换为旧库。

DTS 付出的代价同样明确：

- 没有完整 GCC 12 `libstdc++.so.6.0.30`；
- 不能使用 `std::__cxx11::basic_string` 新 ABI；
- 部分依赖新 ABI 或新库布局的标准库能力不可用；
- `_GLIBCXX_USE_CXX11_ABI=1` 不能把缺失的运行库实现变出来。

所以官方 DTS 实现的是“旧 ABI 完整兼容”，而不是“新旧运行库同时完整兼容”。

## 2. 本工具集如何在一次安装中提供两种模型

GCC、G++、binutils 和内部前端只安装一份。互斥的部分作为两个开发 profile 安装：

```text
/opt/gcc12-toolset/root/usr/
    共用 GCC、binutils
    lib64/binutils/：两个 profile 共用的 binutils 共享运行库
    lib64/：仅 full 可见的完整 GCC 动态/静态运行库

/opt/gcc12-toolset/profiles/compat/
    DTS patched headers
    libstdc++_nonshared.a
    指向 /usr/lib64/libstdc++.so.6 的 linker script
    g++/c++ wrapper
```

构建时从同一源码快照产生两个视图：

1. `full` 进行正常三阶段 bootstrap，生成完整 dual ABI libstdc++；
2. `compat` 源码副本应用归档 DTS 12 的 `gcc12-libstdc++-compat.patch`；
3. `compat` 只重新构建 GCC 和 target libstdc++，提取兼容头文件与 RHEL 7/GCC 4.8 对应的 `libstdc++_nonshared48.a`；
4. 安装阶段把 compat `c++config.h` 的 `_GLIBCXX_USE_DUAL_ABI` 固定为 `0`。

因此它不是仅切换 `LD_LIBRARY_PATH`，而是切换编译期头文件和链接视图。

## 3. 两个 profile 的准确语义

### `full`

```bash
gcc12-toolset-full bash
source /opt/gcc12-toolset/enable full
```

使用完整 GCC 12 头文件和：

```text
/opt/gcc12-toolset/root/usr/lib64/libstdc++.so.6.0.30
```

支持 ABI 0 与 ABI 1，默认 ABI 1，符号上限为 `GLIBCXX_3.4.30`。

### `compat`

```bash
gcc12-toolset-compat bash
source /opt/gcc12-toolset/enable compat
```

使用 DTS patched headers，并通过 linker script 链接：

```text
/usr/lib64/libstdc++.so.6
+ /opt/gcc12-toolset/profiles/compat/.../libstdc++_nonshared.a
```

该 profile：

- `_GLIBCXX_USE_DUAL_ABI=0`；
- `_GLIBCXX_USE_CXX11_ABI=0`；
- 只把 common binutils 目录加入 `LD_LIBRARY_PATH`，不暴露完整私有 libstdc++；
- CMake 等构建系统通过 `CC`、`CXX` 使用 compat wrapper；
- 目标是复现 RHEL 7 DTS 的系统 libstdc++ 兼容模型。

旧名称 `private`、`system` 仅作为 `full`、`compat` 的兼容别名。

## 4. 仍需说明的兼容边界

本实现复用了 DTS 12 最关键的 libstdc++ 兼容补丁、头文件模型、`nonshared48` 归档选择和 linker script，但它是独立重构包，不是 Red Hat 签名和认证的原始 DTS RPM。

正式发布前仍应完成：

- GCC、G++ 和 libstdc++ 完整 testsuite；
- DTS compat testsuite 与 Red Hat 构建结果对比；
- 实际依赖库矩阵验证；
- RPM 签名、SBOM、源码归档及安全补丁维护。

另外，已经用 `full` profile 生成并记录 `GLIBCXX_3.4.20+` 的程序，不能通过 `compat` 启动入口自动降级；profile 选择发生在编译和链接阶段。

完整新库与系统旧库都使用 SONAME `libstdc++.so.6`。插件或共享库也不能在同一进程中各自装载一套 runtime 后安全交换 STL 对象、异常、RTTI 或分配器状态。

## 5. 推荐部署矩阵

| 需求 | 推荐方式 |
|---|---|
| 开发、测试完整 GCC 12 标准库 | `full` profile |
| ABI 1 程序部署到干净 CentOS 7 | `full` 加 `-static-libstdc++ -static-libgcc` |
| 必须动态使用 GCC 12 libstdc++ | `full` 或应用私有 `$ORIGIN` RUNPATH |
| 必须使用系统 libstdc++ | `compat` profile，并执行符号审计 |
| C++ 共享库被未知宿主加载 | 优先私有统一动态运行库；不要轻易静态嵌入两套 runtime |

## 6. 静态 libstdc++ 的边界

静态链接 libstdc++ 可以消除动态 `GLIBCXX_*` 和 `CXXABI_*` 需求，但不能消除所有平台约束：

- glibc 仍应动态链接且最高为 `GLIBC_2.17`；
- 第三方动态库不能要求更新 glibc；
- 目标 CPU 指令集应保持 `x86-64`，不要使用 `-march=native`；
- C++ 异常跨 DSO 时要统一 libgcc/runtime；
- 静态 libstdc++ 链入共享库时不得跨边界传递 STL、异常和 RTTI；
- 所有静态对象必须以 `-fPIC` 构建后才能安全进入共享库。

最终兼容性由最终 ELF 的动态依赖和符号版本决定，而不是只由编译器版本或 ABI 宏决定。
