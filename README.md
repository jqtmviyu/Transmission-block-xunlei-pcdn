# transmission屏蔽吸血客户端和 pcdn ip段

> 为transmission屏蔽迅雷等吸血客户端

[教程地址](https://github.com/jqtmviyu/BTN-Collected-Rules)


## 防火墙阻止吸血

脚本修改自 [WhymustIhaveaname/Transmission-Block-Xunlei](https://github.com/WhymustIhaveaname/Transmission-Block-Xunlei)

因为是在openwrt中运行,所以有点不太一样(若在debian中运行,sh改为bash,并安装transmission-cli)

需要安装`iptables ip6tables`模块

###  白名单模式: 

`allow_whitelist.sh`

* 除了`whitelist_pattern="Transmission|qBittorrent|µTorrent|aria2|BitComet"`, 其余都会被屏蔽
* 例外情况: `special_pattern="qbittorrent/3\.3\.15|Transmission\ 2\.9|BitComet\ 2\.04"`, 这些也会被屏蔽
* 当时间的小时数字是12的整数倍时,清空防火墙规则和log (eg:12:00/24:00). 0禁用
* 封禁延伸到 `/24` `/64` ip段 
* 当ip是私有地址时,忽略
* 加入没什么用的彩色输出
* `--debug`: 调试模式会打印更多信息,但不会写入log和添加防火墙
* `--chain`: 查看防火墙已添加的ip
* `--log`: 查看日志
* `--flush`: 清空防火墙规则和log
* `--help`: 帮助信息

### 黑名单模式

`block_blacklist.sh`

* block_clients: 每行一条

### 添加计划任务

每两分钟运行一次

```crontab
PATH=/usr/sbin:/usr/bin:/sbin:/bin
*/2 * * * * /root/allow_whitelist.sh 2>> /tmp/allow_whitelist.log
```

## transmission添加屏蔽url

修改自 [PBH-BTN/BTN-Collected-Rules](https://github.com/PBH-BTN/BTN-Collected-Rules) 的all.txt, github action 每天自动更新

新增常见数据中心ip段: [isp/cn](https://github.com/zealic/autorosvpn/tree/master/isp/cn)

设置transmission的URL阻止清单`https://github.com/jqtmviyu/Transmission-block-xunlei-pcdn/raw/main/transmission_blacklist.gz`

### 定时更新

下载并修改`update_transmission_blacklist.sh`

```crontab
0 5 * * * /root/update_transmission_blacklist.sh 2>> /tmp/allow_whitelist.log
```
