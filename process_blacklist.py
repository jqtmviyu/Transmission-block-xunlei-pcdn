import ipaddress
import re

import requests


def process_blacklist(url, output_file):
    response = requests.get(url)
    lines = response.text.splitlines()

    processed_lines = []

    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        # 检查是否是合法的IP地址或CIDR
        if re.match(r"(\d{1,3}\.){3}\d{1,3}(\/\d{1,2})?$", line) or re.match(
            r"([a-fA-F0-9:]+)(\/\d{1,3})?$", line
        ):
            if "/" in line:
                network = ipaddress.ip_network(line, strict=False)
                ip_range = f"{network.network_address}-{network.broadcast_address}"
            else:
                ip_range = f"{line}-{line}"
            processed_lines.append(f"pbt:{ip_range}")

    with open(output_file, "w", encoding="utf-8") as file:
        for line in processed_lines:
            file.write(line + "\n")


# 调用函数处理远程文件
process_blacklist(
    "https://raw.githubusercontent.com/PBH-BTN/BTN-Collected-Rules/main/combine/all.txt",
    "transmission_blacklist.txt",
)
