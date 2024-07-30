# openwrt屏蔽吸血客户端和 pcdn ip段

> 为transmisson屏蔽迅雷等吸血客户端

[教程地址](https://github.com/jqtmviyu/BTN-Collected-Rules)


## 防火墙阻止吸血客户端

1. 创建脚本

修改自 [WhymustIhaveaname/Transmission-Block-Xunlei](https://github.com/WhymustIhaveaname/Transmission-Block-Xunlei)

因为是在openwrt中运行,所以有点不太一样

下载 `block_xunlei.sh` 并修改

ps: 如果要在linux中运行, 可能需要将 `cut -d " " -f 1 ` 改回 `cut --delimiter " " --fields 1`

2. 添加计划任务

每两分钟运行一次

```crontab
PATH=/usr/sbin:/usr/bin:/sbin:/bin
*/2 * * * * /root/block_xunlei.sh 2>> /root/block_xunlei.log
```

## 添加屏蔽url

修改自 [PBH-BTN/BTN-Collected-Rules](https://github.com/PBH-BTN/BTN-Collected-Rules) 的all.txt

github action 每天自动更新

`transmission_blacklist.gz` 体积更小, 下载更快.

需要复制的是raw, 并且不能被墙.

### 定时更新

下载并修改`update_transmission_blacklist.sh`

```crontab
0 5 * * * /root/update_transmission_blacklist.sh 2>> /root/block_xunlei.log
```