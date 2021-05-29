1、请陈述一下三次握手和四次挥手？
三次握手：
所谓的三次握手指的是tcp/ip 模型中的第四层传输层，是客户端与服务端端口建立的tcp连接，也是指端口与端口之间的虚拟化链接
第一次握手：客户端向服务端发起SYN报文请求，并进入SYN_SEND状态，等待服务器确认
第二次握手：服务端收到客户端发起的SYN报文请求，并返回ACK响应报文，同时自己也要向客户端发送SYN确认报文，表明我已收到请求
第三次握手：客户端收到服务器的SYN和ACK包，并向服务器发送确认包ACK(ack=k+1)，此包发送完毕，客户端和服务器进入ESTABLISHED状态，完成三次握手。



四次挥手：
最开始的时候，客户端和服务器都是处于ESTABLISHED状态，然后客户端主动关闭，服务器被动关闭。
第一次挥手：客户端向服务端发起FIN释放报文，(其序列号为seq=u)，此时，客户端进入FIN-WAIT-1（终止等待1）状态
第二次挥手：服务器收到连接释放报文，发出ACK确认报文，此时，服务端就进入了CLOSE-WAIT（关闭等待）状态。
            客户端收到服务器的确认请求后，此时，客户端就进入FIN-WAIT-2（终止等待2）状态，等待服务器发送连接释放报文（在这之前还需要接受服务器发送的最后的数据）。
            
第三次挥手：服务器将最后的数据发送完毕后，就向客户端发送FIN连接释放报文，由于在半关闭状态，服务器很可能又发送了一些数据，服务器就进入了LAST-ACK（最后确认）状态，等待客户端的确认
第四次挥手：客户端收到服务器的连接释放报文后，必须发出ACK确认报文，此时，客户端就进入了TIME-WAIT（时间等待）状态，
            但此时的TCP链接报文并没有释放，必须要经过最长报文段寿命的时间后，客户端才会撤回响应的TCP，才进入CLOSED状态。




2、请陈述一下NDS解析请求流程？
用户要访问www.baidu.com，会先找本机的host文件，再找本地设置的DNS服务器，如果也没有的话，就去网络中找根服务器，
根服务器反馈结果，说只能提供一级域名服务器.cn，就去找一级域名服务器，一级域名服务器说只能提供二级域名服务器.com.cn,
就去找二级域名服务器，二级域服务器只能提供三级域名服务器.baidu.com.cn，就去找三级域名服务器，三级域名服务器
正好有这个网站www.baidu.com，然后发给请求的服务器，保存一份之后，再发给客户端




3、请说明OSI七层模型
应用层：应用程序与接口（如QQ和其他三方软件的对接），封装的协议有（http  dns  telnet   nfs   ftp   tftp   smtp（25）  snmp（161）      ）
表示层：表示数据的格式、压缩、加密
会话层：
        作用：建立、维护、管理应用程序之间的会话。
        功能：对话控制、同步
传输层：
        作用：负者建立端到端的连接、保证报文在端到端之间的传输。——对应设备（防火墙）
        功能：连接控制、流量控制、差错控制。
        协议：TCP   UDP
网络层：
        网络层功能：为网络设备提供逻辑地址，进行路由选择、分组转发，IP地址是三层地址
        协议：IP  ARP  RARP  ICMP（Internet控制报文协议） IGMP
数据链路层：
        作用：在局域网内部实现主机与主机之间的通讯——对应设备（交换机）
        协议：PPP  FDDI
物理层：将数据包以比特流的形式从网卡内部传输出去，也是定义比特的表示、数据传输速率、信号的传输模式（单工、半双工、全双工）




4、请说出熟知的端口号

应用程序	 FTP	     TFTP	TELNET  SMTP    DNS	    HTTP	SSH 	MYSQL    REDIS
熟知端口	21,20	      69	 23	     25	     53	     80	     22	    3306      6739
传输层协议	TCP	          UDP	TCP	     TCP	UDP	     TCP	TCP	    TCP       TCP

ICMP：网络控制协议，没有端口




5、Linux如何挂载windows下的共享目录？
（1）、Windows打开需要共享的目录
（2）、mount.cifs //IP地址/server /mnt/server -o user=administrator,password=123456
注意：user与pass 是windows主机的账号和密码 注意空格 和逗号




6、如何查看http的并发请求数与其TCP连接状态？
语法格式如下：netstat -n | awk '/^tcp/ {++b[$NF]} END {for(a in b) print a,"\t",b[a]}'
统计网络连接数：netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,"\t",state[key]}'

状态描述：
CLOSED：无连接是活动的或正在进行
LISTEN：正在侦听
SYN_RECV：一个连接请求已经到达，等待确认
SYN_SENT：应用已经开始，打开一个连接
ESTABLISHED：正常数据传输状态
FIN_WAIT1：应用说它已经完成
FIN_WAIT2：另一边已同意释放
ITMED_WAIT：等待所有分组死掉
CLOSING：两边同时尝试关闭
TIME_WAIT：另一边已初始化一个释放
LAST_ACK：等待所有分组死掉

如发现系统存在大量TIME_WAIT状态的连接，通过调整内核参数解决:
net.ipv4.tcp_syncookies = 1 //表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN***，默认为0，表示关闭；
net.ipv4.tcp_tw_reuse = 1  //表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；
net.ipv4.tcp_tw_recycle = 1  //表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。
net.ipv4.tcp_fin_timeout = 30  //修改系統默认的 TIMEOUT 时间

在怀疑有Dos***的时候，可以输入：
netstat -na | grep :80 |awk '{print $5}'|awk -F '::ffff:' '{print $2}' | grep ':' | awk -F: '{print $1}' | sort | uniq -c | sort -r | awk -F' ' '{if ($1 > 50) print $2}' | sed 's/^.*$/iptables -I firewall 1 -p tcp -s & --dport 80 --syn -j REJECT/' | sh





7、如何用tcpdump嗅探80端口的访问看看谁最高？
tcpdump -i eth0 -tnn dst port 80 -c 1000 |awk -F "," '{print $1"."$2"."$3"."$4"."}'|sort |uniq -c|sort -nr|head -5





8、如何配置文件描述符

临时配置：
echo 65530 > /proc/sys/fs/file-max          # 最大打开的文件描述符
sysctl fs.file-max
或者
vim /etc/sysctl.conf
fs.file-max=65535
或者
通过ulimit -Sn设置最soft limit
ulimit -Sn 160000
通过ulimit -Hn设置最Hard limit
ulimit -Hn 160000
同时设置soft limit和hard limit。对于非root用户只能设置比原来小的hard limit
ulimit -n 180000


永久配置：
vim /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
soft是一个警告值，而hard则是一个真正意义的阀值，超过就会报错，一般情况下都是设为同一个值。需要注销重新登录配置才会生效
nofile是文件描述符，noproc是进程，一般情况下只限制文件描述符数和进程数就够了




9、如何查看Linux系统每个ip的连接数？
netstat -n|head -n 100|awk '/^tcp/ {print $4}'|awk -F ":" '{print $1}'|sort |uniq -c|sort -rn




10、shell下生成32位随机密码
cat /dev/urandom |head -1 |md5sum |head -c 32




11、统计出apache的access.log中访问量最多的5个ip
cat access.log |awk '{print $1}'|sort |uniq -c |sort -nr|head -n5




12、ps aux 中的VSZ代表什么意思，RSS代表什么意思
VSZ:虚拟内存集,进程占用的虚拟内存空间；RSS:物理内存集,进程占用实际物理内存空间。





13、介绍下Linux系统的开机启动顺序
(1)、开机自检
(2)、BIOS或uefi系统初始化
(3)、读取MBR扇区
(4)、grub菜单引导加载程序
(5)、加载内核模块
(6)、init初始化、centos6 版本是init主进程启动，他的进程是串行启动的，而centos7 是systemd主进程启动，他的进程都是并行启动
(7)、读取运行级别的配置文件





14、简要说一下Linux 系统运行级别？
    0: 关闭计算机
    1: 单用户模式
    2: 无网络多用户模式
    3: 有网络多用户模式
    4: 保留作自定义，否则同运行级 3
    5: 同运行级 4，一般用于图形界面(GUI)登录(如 X的 xdm 或 KDE的 kdm)
    6: 重启动计算机




15、符号链接与硬链接的区别
ln 3.txt 4.txt 这是硬链接，相当于复制，不可以跨分区，但修改3,4会跟着变，若删除3,4不受任何影响。
ln -s 3.txt 4.txt 这是软连接，相当于快捷方式。修改4,3也会跟着变，若删除3,4就坏掉了。不可以用了。




16、保存当前磁盘分区的分区表
dd  if=/dev/sda of=./mbr.txt bs=1 count=512




17、怎么把脚本添加到系统服务里，即用service来调用
#!/bin/bash
# chkconfig: 345 85 15
# description: httpd
然后保存，chkconfig httpd –add 创建系统服务，现在就可以使用service 来 start or restart




18、写一个脚本，实现批量添加20个用户，用户名为user01-20，密码为user后面跟5个随机字符
#!/bin/bash
#description: useradd
for i in $(seq -f"%02g" 1 20);do
useradd user$i
echo "user$i-$(echo $RANDOM|md5sum|cut -c 1-5)"|passwd –stdin user$i >/dev/null 2>&1
done



19、写一个脚本，实现判断192.168.1.0/24网络里，当前在线的IP有哪些，能ping通则认为在线
#!/bin/bash
for ip in $(seq 1 255)
do
ping -c 1 192.168.1.$ip > /dev/null 2>&1
if [ $? -eq 0 ]; then
echo 192.168.1.$ip UP
else
echo 192.168.1.$ip DOWN
fi
done
wait





20、如何让history命令显示具体时间？
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S"
export HISTTIMEFORMAT
history
212  2021-03-28 16:57:12HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S"
213  2021-03-28 16:57:12export HISTTIMEFORMAT
214  2021-03-28 16:57:13history





21、默认生产环境中，三台服务器均可满足访问外网需求；但最终目标是完成服务器01与服务器03之间的不同网段间通讯，
    即服务器01的10.0.0.10主机IP地址可以正常访问服务器03的10.0.1.10主机IP地址？
vmnet8虚拟网配置项：
选中【NAT模式与虚拟机共享主机的IP地址】
选中【将主机虚拟适配器连接到此网络】
子网IP【10.0.0.0】；子网掩码【255.255.255.0】
vmnet1虚拟网配置项：
选中【仅主机模式在专用网络内连接虚拟主机】
选中【将主机虚拟适配器连接到此网络】
子网IP【10.0.1.0】；子网掩码【255.255.255.0】
图片地址: https://img-blog.csdnimg.cn/20200912101908532.png#pic_center

route -n  打印主机路由表条目信息
服务器01上配置网络路由条目
route add -net 10.0.1.0 netmask 255.255.255.0 gw 10.0.0.11
服务器03上配置网络路由条目
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.1.11
配置开启主机路由转发功能
服务器02主机在拓扑中负责进行路由转发，需要开启相应配置参数
# vim /etc/sysctl.conf
net.ipv4.ip_forward= 1
# sysctl -p

方法2：增加文件，并写入如下需要添加的路由信息：vim /etc/sysconfig/static-routes
any net 220.181.9.0/24 gw 192.168.72.2
any host 220.181.9.2 gw 192.168.72.2




22、如何防止Linux命令行或脚本里MySQL登录密码泄露？
HISTCONTROL=ignorespace 
表示忽略以空白字符开头的命令。
这里是临时生效，要想永久生效，请放入/etc/bashrc。
mysql -uroot -p'123'           # 不会被记录到历史内部
history -c                     # 清除所有所有记录




23、如何将前台脚本放入后台执行
方法一：可以利用screen命令进行后台运行（yum -y install screen）
方法二：可以利用nohup命令进行后台运行，对此会生成出一个nohup.out日志
方法三: bash 脚本名称 & exec /bin/bash
通过jobs管理后台程序




24、如何将本地80端口的请求转发到8080端口，当前主机IP为192.168.133.126
iptables -t nat -A PREROUTING -d 192.168.133.126 -p tcp --dport 80 -j DNAT --to-des 192.168.133.126:8080




25、linux网络配置中如何给一块网卡添加多个IP地址
(1)、手工配置别名的VIP的方法
ifconfig eth0:1 10.0.0.100 netmask 255.255.255.224 up
route add -host 10.0.0.100 dev eth0        
###---增加一条主机路由，可选配置

(2)、手工删除别名VIP的方法
ifconfig eth0:1 10.0.0.100 netmask 255.255.255.224 down
ifconfig eth0:1 down


(3)、别名IP永久生效的方法
写入到网卡配置文件可让别名IP永久生效，名字可以为ifcfg-eth0:x，x为0-255的任意数字，IP等内容格式和ifcfg-eth0一致
vim /etc/sysconfig/network-scripts/ifcfg-eth0:1
DEVICE=eth0:1
IPADDR=10.0.0.100





25、查找出/tmp目录下面修改时间是7天以前，大小在50k到2M之间，并以.log结尾的文件？
find /tmp/ -type f -mtime +7 -size +50k -a -size -2M -name "*.log" | xargs -i cp {} /data
find /tmp/ -type f -mtime +7 -size +50k -a -size -2M -name "*.log" -exec cp {} /tmp \;
cp $(find /tmp/ -type f -mtime +7 -size +50k -a -size -2M -name "*.log") /data




26、如何删除多个文件中包含的空格或其他特殊字符，怎么做？
find /tmp/ -type f -name "*.log" -print0 | xargs -0 ls -l




27、CPU使用率超过80%或硬盘超过85%邮件报警
top -n1 | tail -n +3 | head -1 | awk -F'[, ]+' '{print 100-$11}'                    # 获取空闲率
#!/bin/bash
cpuUsed=`top -n1 | tail -n +3 | head -1 | awk -F '[, ]+' '{print 100-$11}'`
diskUsed=`df -h | awk -F '[ %]+' '/\/$/{print $5}'`
logFile=/tmp/check.log

function Sendmail(){
    mail -s "监控报警" 330289344@qq.com < $logFile
}

function check(){
    if [ `echo "$cpuUsed>80"|bc` -eq 1 -o $diskUsed -ge 85 ];then
        echo "`date +%F`  CPU使用率:${cpuUsed}%,磁盘使用率:$(diskUsed)%" >> $logFile
        Sendmail
    fi
}

function main(){
    check
}
main

加入定时任务，每5分钟执行一次
crontab -e 
/5 * * * * check.sh





28、监控学校的网络出口正常性，需要写一个脚本，操作系统每30秒钟访问百度首页，如果能够正常打开则记录正常日志，如果出现异常则发邮件报警
#! /bin/bash
Web="www.baidu.com"
A="Web is Good!"
while true
do
    state=`curl -I -s $Web | head -1 | cut -d " " -f2`
    if [[ $state -eq "200" ]]
    then
        echo "$A,the Web is $Web" >> /home/log/website-access.`date +%F`.log
    else
        echo "Web failed $Web" >> /home/log/website-error.`date +%F`.log
        echo "Web failed $Web `date +%F`" | mail -s "website-error `date +%F`" 330289344@qq.com
    fi
    sleep 30
done



29、如何快速删除Linux中海量小文件
解决办法：
1）ls | xargs rm -f
2）find . -type f | xargs rm -f
3）rsync -av --delete /null /tmp/




30、如何正确清理MySQL binlog
1)手动删除
删除mysql-bin.000004之前的而没有包含mysql-bin.000004
mysql> purge binarylogs to 'mysql-bin.000004';

按照时间，删除指定时间之前的
mysql> purge master logs before '2017-03-20 00:00:00';
清理所有bin-log
reset master

2)设置自动删除
set global expire_logs_days = 7;




31、设置一条Iptables规则，允许192.168.10.0段访问873端口
iptables -A INPUT -s 192.168.10.0/24 -p tcp --dport 873 -j ACCEPT




32、vim命令粘贴带\#号或注释信息格式会出现混乱情况，有什么方法进行解决？
原因分析：是由于vim编辑命令的自动缩进功能所影响，因此粘贴带注释的代码时可以取消自动缩进
vim test.txt             #<--编辑一个文件
:set paste                #<--在vim的命令行模式输入，关闭vim缩进功能
:set nopaste               #<--开启vim缩进功能

比较方便的方法就是修改用户家目录下的 .vimrc配置文件：
set pastetoggle=<F9>
以后在插入模式下，只要按F9键就可以快速切换自动缩进模式了




33、使用find命令的时候 |xargs(管道xargs)与-exec有什么区别？
find /kolor -type f |xargs  find命令找到的文件一次性都给 |xargs 处理
find /kolor -type f -exec   find命令找到一个文件 就传递给 -exec 处理一次

find /kolor -type f |xargs tar zcf /tmp/kolor-xargs.tar.gz
相当于
tar zcf /tmp/kolor-xargs.tar.gz /kolor/stu02.txt

find /kolor -type f -exec tar zcf /tmp/kolor-exec.tar.gz {} \;
相当于
tar zcf /tmp/kolor-exec.tar.gz /kolor/stu02.txt
tar zcf /tmp/kolor-exec.tar.gz /kolor/stu10.txt




34、实现172.16.1.0/24段所有主机通过124.32.54.26外网IP共享上网
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s 192.168.88.0/24 -j SNAT --to-source 124.32.54.26




35、/etc/profile /etc/bashrc .bashrc .bash_profile的区别
/etc/profile 主要用是系统的环境变量，同时我们也放些别名
/etc/bashrc  主要用来存放系统的别名和自己定义的函数（都可以放到 /etc/profile中）

只针对当前登陆的用户生效 ↓
.bashrc 是用户自己定义的别名
.bash_profile 是用户自己定义的环境变量




36、❤IDC 机房带宽突然从平时 100M 增加到 400M，请你分析问题所在并解决   ☆☆☆☆
直接导致数百台服务器无法连接，该机房全部业务中断。
首先会反射为DDOS问题，结果解决时间加长了，如果能提前做好预案，恢复速度可能就会好很多

分析问题
1)IDC带宽被占满的原因很多，常见的有：
a.真实遭受DDOS攻击
b.内部服务器中毒，大量外发流量
c.网站元素（如图片）被盗连，在门户页面被推广导致大量流量产生
d.合作公司来抓数据，如：对合作单位提供了API数据接口
e.购买了CDN业务，CDN猛抓源站
f.其他原因


拦截可以在三个层次做。
（1）专用硬件
Web 服务器的前面可以架设硬件防火墙，专门过滤请求。这种效果最好，但是价格也最贵。
（2）本机防火墙
操作系统都带有软件防火墙，Linux 服务器一般使用 iptables。比如，拦截 IP 地址1.2.3.4的请求，可以执行下面的命令。
iptables -A INPUT -s 1.2.3.4 -j DROP

（3）Web 服务器
Web 服务器也可以过滤请求。拦截 IP 地址1.2.3.4，nginx 的写法如下。
location / {
  deny 1.2.3.4;
}





37、Nginx需要优化哪些内容？
1.gzip压缩优化
2.expires缓存优化
3.网络IO事件模型优化
4.隐藏软件名称和版本号
5.防盗链优化
6.禁止恶意域名解析
7.禁止通过IP地址访问网站。
8.HTTP请求方法优化。
9.防DOS攻击单IP并发连接的控制，与连接速率控制。
10.严格设置Web站点目录的权限。
11.将Nginx进程以及站点运行于监牢模式(nginx服务降权启动（不能使用80端口，使用其他端口，例如8080）、站点目录设置普通用户)。
12.通过robot协议以及HTTP_USER_AGENT防爬虫优化
13.配置错误页面根据错误码指定网页反馈给用户
14.Nginx日志相关优化
访问日志切割轮询、不记录指定元素日志、最小化日志目录权限。
15.限制上传到资源目录的程序被访问，防止木马入侵系统破坏文件。
16.FastCGI参数buffer和cache以及超时等的优化。
17.php.ini和php-fpm.conf配置文件的优化。
18.有关Web服务的linux内核方面深度优化（网络连接、IO、内存等）。
19.Nginx加密传输优化（SSL）。
20.Web服务器磁盘挂载及网络文件系统优化。
21.使用Nginx cache。
22.nginx WAF(nginx+lua) 安全。




38、企业生产MySQL如何优化？
a：硬件的优化：
1、采用64位cpu，cpu至少4颗，L2缓存越大越好
2、内存要大，32-64G运行1-2个实例，96-128G运行3-4个实例
3、机械盘选用sas盘，转速15000以上，用可能的话使用ssd
4、raid卡使用raid10
5、网卡多块，千兆以上
6、数据库不要使用虚拟化，slave硬件要好于master

b：操作系统优化
1、操作系统选择x86_64位，尽量采用xfs文件系统
2、优化磁盘存储参数
3、优化内核参数
4、优化网络等

c：mysql构架优化
1、根据内存大小，配置服务器跑多实例
2、主从复制采用mixed模式，尽量不要跨机房同步，若要跨机房，尽量采用远程写，本地读
3、定期检查、修复主从复制的数据差异
4、业务拆分，搜索功能不使用MySQL数据库执行；某些高并发，安全性一般的业务使用nosql，如：memcache、 redis等
5、数据库前端加cache，如memcache，用于用户登录，商品查询
6、动态数据静态化，整个文件静态化，页面片段静态化
7、数据库集群读写分离，一主多从，通过dbproxy进行集群读写分离
8、单表超过800万，拆库拆表，如人工将（登录、商品、订单）拆表拆库
9、选择从库备份，并且对数据库进行分表分库备份

d：MySQL数据库层面优化
1、优化my.cnf参数
2、优化库表设计，包括字符集、字符串长度、创建短索引、多用复合索引；
3、SQL语句优化，减少慢语句数量；

e：数据库管理流程、制度优化
1、人的流程：开发—>核心运维/DBA
2、测试流程：内网 IDC测试线上执行
3、客户端管理，PHPMYADMIN

f：MySQL数据库安全优化
1、数据库禁止设置外网
2、数据库文件权限优化；
3、授权用户权限限制，尽量专库专用户
4、限制开发对生产库的操作权限
5、防止SQL语句注入




39、基础娱乐命令：像幻灯片一样播放每个字符
echo "Kolor，网工，运维" | pv -qL 20




40、网络并发，并发与架构设计基础知识
PV是什么：PV是page view的简写。PV是指页面的访问次数，每打开或刷新一次页面，就算做一个pv。
计算模型： 
每台服务器每秒处理请求的数量=((80%*总PV量)/(24小时*60分*60秒*40%)) / 服务器数量 。
其中关键的参数是80%、40%。表示一天中有80%的请求发生在一天的40%的时间内。24小时的40%是9.6小时，有80%的请求发生一天的9.6个小时当中（很适合互联网的应用，白天请求多，晚上请求少）。 

简单计算的结果：
4000000/34560/1=115.7
((80%*500万)/(24小时*60分*60秒*40%))/1 = 115.7个请求/秒 
((80%*100万)/(24小时*60分*60秒*40%))/1 = 23.1个请求/秒 

初步结论：
现在我们在做压力测试时，就有了标准，如果你的服务器一秒能处理115.7个请求，就可以承受500万PV/每天。
如果你的服务器一秒能处理23.1个请求，就可以承受100万PV/每天。




41、shell知识点：shell脚本中字符串截取
1. # 号截取，删除左边字符，保留右边字符。
变量： var=http://www.koloredu.com/123.htm
echo ${var#*//}
其中 var 是变量名，# 号是运算符，*// 表示从左边开始删除第一个 // 号及左边的所有字符
即删除 http://
结果是 ：www.koloredu.com/123.htm

2. ## 号截取，删除左边字符，保留右边字符。
变量： var=http://www.koloredu.com/123.htm
echo ${var##*/}
##*/ 表示从左边开始删除最后（最右边）一个 / 号及左边的所有字符 
即删除 http://www.koloredu.com/
结果是 ：123.htm

3. %号截取，删除右边字符，保留左边字符
变量： var=http://www.koloredu.com/123.htm
echo ${var%/*}
%/* 表示从右边开始，删除第一个 / 号及右边的字符
即删除 /123.htm
结果是：http://www.koloredu.com

4. %% 号截取，删除右边字符，保留左边字符
变量： var=http://www.koloredu.com/123.htm
echo ${var%%/*}
%%/* 表示从右边开始，删除最后一个 / 号及右边的字符 
即删除  //www.koloredu.com/123.htm.
结果是：http:

5. :x:y格式表示取字符串信息，从左边第x+1个字符开始，及取出字符的y个数
变量： var=http://www.koloredu.com/123.htm
echo ${var:0:5} 
其中的 0 表示左边第一个字符开始，5 表示字符的总个数。
即取值 从字符串的0字符取值h，取5个字符，到字符：（冒号） 
结果是：http:

6. :y格式表示取字符串信息，从左边第y+1个字符开始，一直到结束。
变量： var=http://www.koloredu.com/123.htm
echo ${var:7} 
其中的 7 表示左边第8个字符开始，一直到结束。 
即取值 从字符串的第7位/之后取值，知道字符串结束
结果是 ：www.koloredu.com/123.htm

7. :x-y:z格式表示取字符串信息，其中x-y表示字符串的取值范围，从右边第x-y位个字符取值，及取字符的z个字符数
变量： var=http://www.koloredu.com/123.htm
echo ${var:0-7:3}
其中的 0-7 表示右边算起第七个字符开始，3 表示字符的个数。
即取值 0-7从字符串右边取7位，然后再从左边取前3位
PS：特殊说明
①当1-7时，表示0-7取7位，但从最左边的取值中减去1位，即var=987654321   0-7=987654321  1-7=87654321  
②当7-7时，表示0-7取7位，但从最左边的取值中减去7位，即var=987654321   0-7=987654321  7-7=987654321
③当取值的范围小于输出的字符数时，将全部输出，即var=987654321    0-3=321   取4位时，显示321
结果是：123

8. :x-y格式表示取字符串信息，其中x-y表示字符串的取值范围，从右边第0个字符开始，一直到y位结束。
变量： var=http://www.koloredu.com/123.htm
echo ${var:0-7}
表示从右边第七个字符开始，一直到结束。
即取值 0-7从字符串右边取7位 
结果是：123.htm
注：（左边的第一个字符是用单个数字字符0表示，右边的第一个字符用 0-1 表示）.com/123.htm.




42、常用的磁盘raid有哪些？描述下原理和区别？
图片地址:https://img-blog.csdnimg.cn/20200912020251154.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM5NTc4NTQ1,size_16,color_FFFFFF,t_70#pic_center
RAID 0，可以是一块盘和N个盘组合 
优点：读写快，是RAID中最好的
缺点：没有冗余，一块坏了数据就全没有了

RAID 1，只能2块盘，盘的大小可以不一样，以小的为准
10G+10G只有10G，另一个做备份。
它有100%的冗余，缺点：浪费资源，成本高

RAID 5 ，3块盘，容量计算10*（n-1）,损失一块盘
特点，读写性能一般，读还好一点，写不好


43、yum安装软件的时候，记不全包名，如何查找到完整的包名？
方法一：yum search bash
方法二：yum list | grep ^bash

