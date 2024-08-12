#!/bin/sh

# 用户定义的变量
username="用户名"
password="密码"
host="127.0.0.1"
port=9091
chain="OUTPUT"
custom_chain_ipv4="CUSTOM_CHAIN_IPV4"
custom_chain_ipv6="CUSTOM_CHAIN_IPV6"
whitelist_pattern="Transmission|qBittorrent|µTorrent|aria2|BitComet"      # 白名单
special_pattern="qbittorrent/3\.3\.15|Transmission\ 2\.9|BitComet\ 2\.04" # 白名单例外
log_path="/tmp/allow_whitelist.log"
interval_hour=12 # 12:00/24:00 重置防火墙规则
DEBUG=0         # 调试模式,默认禁用,不会加入防火墙和修改日志
# ANSI 转义码定义
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colo

# 包装 echo 的函数
echo_default() {
  echo -e "$@"
}

echo_info() {
  echo -e "${BLUE}$1${NC}"
}

echo_warn() {
  echo -e "${ORANGE}$1${NC}"
}

echo_err() {
  echo -e "${RED}$1${NC}"
}

echo_pass() {
  echo -e "${GREEN}$1${NC}"
}

debug_echo_default() {
  if [ "$DEBUG" -eq 1 ]; then
    echo -e "$@"
  fi
}

debug_echo_info() {
  if [ "$DEBUG" -eq 1 ]; then
    echo_info "$1"
  fi
}

debug_echo_warn() {
  if [ "$DEBUG" -eq 1 ]; then
    echo_warn "$1"
  fi
}

debug_echo_err() {
  if [ "$DEBUG" -eq 1 ]; then
    echo_err "$1"
  fi
}

debug_echo_pass() {
  if [ "$DEBUG" -eq 1 ]; then
    echo_pass "$1"
  fi
}

# 打印自定义链规则
print_chain_rules() {
  echo_info "当前IPv4规则:"
  iptables  -L --line-numbers
  echo_info "当前IPv6规则:"
  ip6tables -L --line-numbers
}

print_log() {
  cat $log_path
}

# 清空自定义链函数和日志
flush_chains() {
  echo_info "清空自定义链 $custom_chain_ipv4 和 $custom_chain_ipv6"
  iptables -F $custom_chain_ipv4  # 清空IPv4自定义链
  ip6tables -F $custom_chain_ipv6 # 清空IPv6自定义链
  echo_info "清空日志"
  echo "" >$log_path
}

# 处理参数函数
process_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --debug)
      DEBUG=1
      echo_info "调试模式已启用"
      ;;
    --chain)
      print_chain_rules
      exit 0
      ;;
    --log)
      print_log
      exit 0
      ;;
    --flush)
      flush_chains
      exit 0
      ;;
    --help)
      echo "  --debug    Enable debug mode"
      echo "  --chain    Print chain rules"
      echo "  --log      Print log"
      echo "  --flush    Flush chains and log"
      echo "  --help     Show this help message"
      exit 0
      ;;
    *)
      echo "Invalid option: $1" >&2
      process_args --help
      exit 1
      ;;
    esac
    shift
  done
}

# 处理传入的参数
process_args "$@"

# 主脚本逻辑部分

# 检查时间是否为4小时的整数倍
check_interval() {
  local minute=$(date "+%M")
  local hour=$(date "+%H")
  if [ "$minute" -eq 00 ] && [ $(($hour % $interval_hour)) -eq 0 ] && [ "$DEBUG" -eq 0 ]; then
    debug_echo_info "当前时间是4小时的整数倍"
    flush_chains
  fi
}

# 检查并创建自定义链并获取规则
create_chains_and_get_rules() {
  debug_echo_info "检查并创建自定义链（如果不存在）并获取当前规则..."

  ipv4_rules=$(iptables -nL $custom_chain_ipv4 2>/dev/null)
  if [ -z "$ipv4_rules" ]; then
    debug_echo_info "创建IPv4自定义链 $custom_chain_ipv4"
    iptables -N $custom_chain_ipv4
  else
    debug_echo_info "当前IPv4自定义链规则:"
    debug_echo_default "$ipv4_rules"
  fi

  ipv6_rules=$(ip6tables -nL $custom_chain_ipv6 2>/dev/null)
  if [ -z "$ipv6_rules" ]; then
    debug_echo_info "创建IPv6自定义链 $custom_chain_ipv6"
    ip6tables -N $custom_chain_ipv6
  else
    debug_echo_info "当前IPv6自定义链规则:"
    debug_echo_default "$ipv6_rules"
  fi
}

# 确保自定义链在主链中被调用函数
ensure_chain_calls() {
  debug_echo_info "确保自定义链在主链中被调用..."
  iptables -C $chain -j $custom_chain_ipv4 > /dev/null 2>&1 || (
    debug_echo_info "添加 $custom_chain_ipv4 到 $chain"
    iptables -A $chain -j $custom_chain_ipv4
  )
  ip6tables -C $chain -j $custom_chain_ipv6 > /dev/null 2>&1 || (
    debug_echo_info "添加 $custom_chain_ipv6 到 $chain"
    ip6tables -A $chain -j $custom_chain_ipv6
  )
}

# 检查是否为私有地址函数
is_private_ip() {
  local ip=$1
  if echo "$ip" | grep -q ":"; then
    echo $ip | grep -qE '^fc00:|^fd00:|^fe80:'
  else
    echo $ip | grep -qE '^10\.|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-1]\.|^192\.168\.|^127\.0\.0\.1'
  fi
}

# 获取所有传输任务的对等节点IP地址
debug_echo_info "获取传输任务对等节点的IP地址..."
ips=$(transmission-remote $host:$port --auth $username:$password -t all --info-peers | grep -v "^Address" | grep -v "^$")
debug_echo_default "$ips"

# 执行函数
check_interval
create_chains_and_get_rules
ensure_chain_calls

# 遍历所有IP地址
echo "$ips" | while IFS= read -r line; do
  ip=$(echo "$line" | cut -d " " -f 1)
  client=$(echo "$line" | awk '{for(i=6;i<=NF;++i)printf "%s ",$i;print ""}' | xargs)

  # 跳过无效的IP
  if [ -z "$ip" ]; then
    continue
  fi

  # 初始化标志
  in_special_cases=0
  in_whitelist=0

  # 检查是否在特殊情况中
  if echo "$client" | grep -qiE "$special_pattern"; then
    in_special_cases=1
    echo_err "例外\t\t$client\t\t$ip"
  fi

  # 检查是否在白名单中
  if echo "$client" | grep -qiE "$whitelist_pattern"; then
    in_whitelist=1
    debug_echo_default "白名单\t\t$client\t\t$ip"
  else
    echo_err "黑名单\t\t$client\t\t$ip"
  fi

  # 如果在特殊情况或不在白名单中，检查并加入屏蔽规则
  if [ "$in_special_cases" -eq 1 ] || [ "$in_whitelist" -eq 0 ]; then
    # 检查当前IP是否已经在规则中
    if (echo "$ip" | grep -q ":" && echo "$ipv6_rules" | grep -q "$ip") || (echo "$ip" | grep -qv ":" && echo "$ipv4_rules" | grep -q "$ip"); then
      echo_pass "$ip 已在规则中"
    else
      echo_err "$ip 不在规则中"
      # 检查是否为私有地址
      if is_private_ip "$ip"; then
        echo_pass "$ip 是私有地址, 忽略."
      else
        # 添加规则
        [ "$DEBUG" -eq 0 ] && echo -e "$(date '+%Y-%m-%d %H:%M:%S')\t$client\t$ip" >>$log_path
        if echo "$ip" | grep -q ":"; then
          echo_err "添加IPv6地址 $ip 到自定义链 $custom_chain_ipv6"
          [ "$DEBUG" -eq 0 ] && ip6tables -I $custom_chain_ipv6 -d $ip -j DROP
        else
          echo_err "添加IPv4地址 $ip 到自定义链 $custom_chain_ipv4"
          [ "$DEBUG" -eq 0 ] && iptables -I $custom_chain_ipv4 -d $ip -j DROP
        fi
      fi
    fi
  fi
done

echo_info "脚本执行完毕."
