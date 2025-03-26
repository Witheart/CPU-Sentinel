#!/bin/bash

# 依赖检查函数
check_dependencies() {
    local missing=()
    local deps=("mpstat" "awk" "free" "ps" "date")
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "错误：缺少以下必需命令 - ${missing[*]}"
        [[ " ${missing[*]} " =~ "mpstat" ]] && echo "请安装 sysstat 包：sudo apt-get install sysstat"
        exit 1
    fi
}

# 帮助信息
show_help() {
    cat <<EOF
CPU 监控脚本 v2.1

用法: $0 [选项]

选项:
  -t <数值>    CPU阈值百分比 (默认: 60)
  -i <秒数>    检查间隔时间 (默认: 5)
  -h           显示此帮助信息

示例:
  $0 -t 70 -i 10   # 阈值70%，每10秒检查
  $0               # 使用默认参数运行

报告问题请提供日志：$LOG_FILE
作者：https://github.com/Witheart
EOF
}

# 参数初始化
THRESHOLD=60
CHECK_INTERVAL=5

# 解析命令行参数
while getopts "t:i:h" opt; do
    case $opt in
        t) 
            if [[ "$OPTARG" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                THRESHOLD=$OPTARG
            else
                echo "错误：阈值必须为数值"
                exit 1
            fi
            ;;
        i)
            if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                CHECK_INTERVAL=$OPTARG
            else
                echo "错误：间隔时间必须为整数"
                exit 1
            fi
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# 生成带时间戳的日志文件
LOG_FILE="cpu_monitor_$(date +%Y%m%d_%H%M%S).log"

# 检查依赖
check_dependencies

# 主监控循环
while true; do
    cpu_trigger=0
    cpu_data=$(LC_ALL=C mpstat -P ALL $CHECK_INTERVAL 1 | awk -v threshold=$THRESHOLD '
        BEGIN {trigger = 0}
        # 匹配数据行：第二列为CPU编号（all或数字），最后一列为数值
        $2 ~ /^all$|^[0-9]+$/ && $NF ~ /^[0-9.]+$/ {
            usage = 100 - $NF
            if (usage > threshold) {
                print $2, usage
                trigger = 1
            }
        }
        END {exit (trigger ? 0 : 1)}'
    )

    if [ $? -eq 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] 警报：CPU超过阈值 ${THRESHOLD}%" | tee -a "$LOG_FILE"
        
        # 记录系统状态（统一使用英语环境）
        {
            echo "---- CPU 核心负载 ----"
            LC_ALL=C mpstat -P ALL 1 1 | awk '
                # 仅匹配平均数据行（包含CPU编号）
                $0 ~ /^Average/ && $2 ~ /^all$|^[0-9]+$/ {
                    printf "Core %-4s %.1f%%\n", $2, 100-$NF
                }'
            
            echo -e "\n---- 内存使用情况 ----"
            LC_ALL=C free -m | awk '
                # 精确匹配Mem行（包含冒号）
                $1 == "Mem:" {
                    printf "总内存: %dMB\n已使用: %dMB\n使用率: %.1f%%\n", 
                        $2, $3, ($3/$2)*100
                }'
            
            echo -e "\n---- 进程资源 Top10 ----"
            LC_ALL=C ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 11 | awk '
                BEGIN {printf "%-6s %-6s %-8s %-6s %-6s %s\n", 
                    "PID", "PPID", "USER", "CPU%", "MEM%", "CMD"}
                NR>1 {printf "%-6s %-6s %-8s %6.1f %6.1f %s\n", 
                    $1, $2, $3, $4, $5, $6}'
            
            echo -e "\n$(printf '%.0s-' {1..50})\n"
        } >> "$LOG_FILE"
    fi
done