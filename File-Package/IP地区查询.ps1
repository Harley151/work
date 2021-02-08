#! /bin/bash

# curl foobar https://ip.cn/index.php?ip={ip_address}
for ip in `cat /root/txt`
do
        curl https://ip.cn/index.php?ip=$ip | grep 所在地理位置 -A2|awk 'NR==3{print $0}' >> /root/ip.txt
done
