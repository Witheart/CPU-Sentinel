#!/bin/bash

# 配置参数
LOG_FILE="cpu_monitor.log"  # 日志文件路径
THRESHOLD=5                # CPU使用率阈值（%）
CHECK_INTERVAL=5            # 检测间隔时间（秒）

while true; do
    # 获取各CPU核心的使用率（非总体）
    cpu_usages=$(mpstat -P ALL $CHECK_INTERVAL 1 | awk -v threshold=$THRESHOLD '
        # 处理mpstat输出
        $3 ~ /[0-9]/ && $2 != "all" {
            # 计算总使用率（100 - 空闲率%）
            usage = 100 - $NF
            if (usage > threshold) {
                print $2, usage
                trigger = 1
            }
        }
        END { exit (trigger ? 0 : 1) }'  # 触发条件满足时返回0，否则1
    )

    # 如果触发条件（任意核心超过阈值）
    if [ $? -eq 0 ]; then
        # 记录时间戳
        echo "=== High CPU Usage Detected: $(date +'%Y-%m-%d %H:%M:%S') ===" >> $LOG_FILE
        # 记录各核心状态
        echo "CPU Cores Usage:" >> $LOG_FILE
        mpstat -P ALL 1 1 | grep -E "^Average: (all|[0-9]+)" >> $LOG_FILE
        # 记录按CPU使用率排序的进程
        echo -e "\nTop Processes:" >> $LOG_FILE
        ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 11 >> $LOG_FILE
        echo -e "----------------------------------------\n" >> $LOG_FILE
    fi
done