import gzip
import ipaddress
import re

import requests

OUTPUT_FILE_NAME = "transmission_blacklist"
UPSTREAM_URLS = [
    "https://raw.githubusercontent.com/PBH-BTN/BTN-Collected-Rules/main/combine/all.txt",
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-chinanet.txt",  # 中国电信
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-cn-cmcc.txt",  # 中国移动
    "https://raw.githubusercontent.com/zealic/autorosvpn/master/isp/cn/route-isp-cncgroup.txt",  # 中国联通# 中国铁通
]


def process_ip_line(line):
    line = line.strip()
    if "/" in line:
        network = ipaddress.ip_network(line, strict=False)
        return f"btn:{network.network_address}-{network.broadcast_address}"
    elif "-" in line:
        return f"btn:{line}"
    return f"btn:{line}-{line}"


def main():
    processed_lines = set()

    for url in UPSTREAM_URLS:
        try:
            response = requests.get(url, timeout=10)
            lines = response.text.splitlines()

            for line in lines:
                if line and not line.startswith("#") and re.match(r"^\d", line):
                    try:
                        processed_line = process_ip_line(line)
                        processed_lines.add(processed_line)
                    except:
                        continue

            print(f"处理URL完成: {url}, 获取到 {len(processed_lines)} 条记录")
        except:
            print(f"处理URL失败: {url}")

    if processed_lines:
        # 保存文件
        with open(f"{OUTPUT_FILE_NAME}.txt", "w", encoding="utf-8") as f:
            f.write("\n".join(processed_lines) + "\n")

        with gzip.open(f"{OUTPUT_FILE_NAME}.gz", "wt", encoding="utf-8") as f:
            f.write("\n".join(processed_lines) + "\n")

        print(f"保存完成，共 {len(processed_lines)} 条记录")
    else:
        print("没有处理到任何有效数据")


if __name__ == "__main__":
    main()
