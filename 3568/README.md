# 作用
# CPU 监控脚本

## 概述

这是一个用于监控系统 CPU 使用率的 Bash 脚本。当 CPU 使用率超过指定阈值时，脚本会记录当前系统状态，包括 CPU 核心负载、内存使用情况以及消耗资源最多的进程。

## 功能

• 实时监控 CPU 使用率
• 可自定义 CPU 使用率阈值
• 可自定义监控间隔时间
• 当 CPU 使用率超过阈值时，记录系统状态到日志文件
• 自动检查并提示缺少的依赖项

## 依赖

• `mpstat` (来自 `sysstat` 包)
• `awk`
• `free`
• `ps`
• `date`

在 Ubuntu/Debian 系统上，可以通过以下命令安装 `sysstat` 包：

```bash
sudo apt-get install sysstat
```

## 使用说明

### 基本用法

```bash
./cpu_monitor.sh
```

默认情况下，脚本会监控 CPU 使用率，当超过 60% 时记录系统状态，每 5 秒检查一次。

### 自定义参数

```bash
./cpu_monitor.sh -t 70 -i 10
```

• `-t <数值>`: 设置 CPU 使用率阈值（默认：60）
• `-i <秒数>`: 设置检查间隔时间（默认：5）

### 帮助信息

```bash
./cpu_monitor.sh -h
```

## 日志文件

脚本会生成一个带时间戳的日志文件，格式为 `cpu_monitor_YYYYMMDD_HHMMSS.log`，其中包含 CPU 超过阈值时的系统状态信息。

## 示例输出

```log
[2023-10-01 12:34:56] 警报：CPU超过阈值 60%
---- CPU 核心负载 ----
Core all   65.2%
Core 0     70.1%
Core 1     60.3%

---- 内存使用情况 ----
总内存: 8000MB
已使用: 4000MB
使用率: 50.0%

---- 进程资源 Top10 ----
PID    PPID   USER    CPU%  MEM%  CMD
1234   1      user1   30.0   2.5  /usr/bin/some_process
5678   1234   user2   25.0   1.8  /usr/bin/another_process

--------------------------------------------------
```

## 作者

[Witheart](https://github.com/Witheart)
