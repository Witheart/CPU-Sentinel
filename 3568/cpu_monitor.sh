#!/bin/bash

# 配置参数
LOG_FILE="cpu_monitor.log"
THRESHOLD=60
CHECK_INTERVAL=5

while true; do
    cpu_usages=$(mpstat -P ALL $CHECK_INTERVAL 1 | awk -v threshold=$THRESHOLD '
        $3 ~ /[0-9]/ && $2 != "all" {
            usage = 100 - $NF
            if (usage > threshold) {
                print $2, usage
                trigger = 1
            }
        }
        END { exit (trigger ? 0 : 1) }'
    )

    if [ $? -eq 0 ]; then
        echo "=== High CPU Usage Detected: $(date +'%Y-%m-%d %H:%M:%S') ===" >> $LOG_FILE
        
        # 修复1：仅提取Average行数据
        echo "CPU Cores Usage:" >> $LOG_FILE
        mpstat -P ALL 1 1 | awk '
            # 匹配Average行（核心数据）
            $0 ~ /^Average:/ && $2 ~ /all|[0-9]+/ {
                core = $2
                usage = 100 - $NF
                printf "Core %s: %.1f%%\n", core, usage
            }
        ' >> $LOG_FILE

        # 修复2：移除column命令依赖，改用awk对齐
        echo -e "\nTop Processes:" >> $LOG_FILE
        ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 11 | awk '
            BEGIN {printf "%-6s %-6s %-8s %-6s %-6s %s\n", "PID", "PPID", "USER", "%CPU", "%MEM", "CMD"}
            NR>1 {printf "%-6s %-6s %-8s %-6s %-6s %s\n", $1, $2, $3, $4, $5, $6}
        ' >> $LOG_FILE
        
        echo -e "----------------------------------------\n" >> $LOG_FILE
    fi
done