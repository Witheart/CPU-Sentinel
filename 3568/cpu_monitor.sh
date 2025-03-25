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
        
        # 修复1：使用更稳健的mpstat输出解析
        echo "CPU Cores Usage:" >> $LOG_FILE
        mpstat -P ALL 1 1 | awk '
            # 匹配CPU核心行（包括all和数字编号）
            $2 ~ /all|[0-9]+/ {
                # 提取核心编号和总使用率
                core = $2
                usage = 100 - $NF
                printf "Core %s: %.1f%%\n", core, usage
            }
        ' >> $LOG_FILE

        # 修复2：优化进程排序输出
        echo -e "\nTop Processes:" >> $LOG_FILE
        ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 11 | column -t >> $LOG_FILE
        
        echo -e "----------------------------------------\n" >> $LOG_FILE
    fi
done