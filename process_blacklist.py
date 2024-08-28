import gzip
import ipaddress
import re

import requests

output_file_name = "transmission_blacklist"

upstream_urls = [
    "https://raw.githubusercontent.com/PBH-BTN/BTN-Collected-Rules/main/combine/all.txt",
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-chinanet.txt",  # 中国电信
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-cn-cmcc.txt",  # 中国移动
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-cncgroup.txt",  # 中国联通
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-cn-crtc.txt",  # 中国铁通
]

processed_lines = set()

for url in upstream_urls:
    response = requests.get(url)
    lines = response.text.splitlines()
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # 过滤掉注释
        if re.match(r"^\d", line):
            if "/" in line:
                network = ipaddress.ip_network(line, strict=False)
                ip_range = f"{network.network_address}-{network.broadcast_address}"
            elif "-" in line:
                ip_range = line
            else:
                ip_range = f"{line}-{line}"
            processed_lines.add(f"btn:{ip_range}")

with open(f"{output_file_name}.txt", "w", encoding="utf-8") as file:
    for line in processed_lines:
        file.write(line + "\n")

with gzip.open(f"{output_file_name}.gz", "wt", encoding="utf-8") as file:
    for line in processed_lines:
        file.write(line + "\n")
