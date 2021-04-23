概述：
    Nginx由俄罗斯开发的并且是开源的高性能HTTP服务器和反向代理服务器，性能尤为强大，官网上说单台nginx服务可以处理5万并发；
特点：
    Nginx性能高、稳定、消耗硬件资源小、能够处理大量并发，主要用于静态的解析及对动态和静态页面进行分离；
    可以实现非阻塞、跨平台、代理、热部署、端口健康检查、动静分离需location匹配正则、采用内核ePoll模型
优势：
    nginx可以做web服务器、缓存服务器、代理服务器、负载均衡器

1、作为Web服务器，nginx处理静态文件、索引文件，他的自动索引效率非常高
2、作为代理服务器，Nginx可以实现无缓存的反向代理加速，提高网站运行速度。
3、作为负载均衡服务器，Nginx既可以在内部直接支持Rails和PHP，也可以支持HTTP代理服务器，对外进行服务。同时支持简单的容错和利用算法进行负载均衡

性能方面:
nginx非常注重于效率，它采用poll模型，可以支持大量并发连接，最大可以支持5万个并发连接数的响应，占用内存资源非常低。

在稳定性方面:
    Nginx采取了分阶段资源分配技术，使得对CPU与内存的占用率非常低,Nginx官方表示Nginx保持1万个没有活动的连接，这些连接只占2.5M内存,而且像这种DDos攻击对nginx没有任何作用。



Nginx支持高并发的原因；
I/O模型之select：
I/O模型之epoll模型：




master进程： 
1.接收外界传递给Nginx的信号，进而管理服务的状态等；
2.管理worker进程，向各worker进程发送信号，监控worker进程的运行状态，当worker进程异常情况下退出后，会自动重新启动新的worker进程；


worker进程：
处理基本的网络事件，他们同等竞争来自客户端的请求，各进程互相之间是独立的。worker进程的个数是可以设置的，一般我们会设置与机器cpu核心数一致； 



nginx配置三模块：
main全局配置模块
event事件模块
http模块：
    多个server，多个location
    设定incloud 指定配置*.conf 文件的目录，将nginx配置模块化，易于管理







配置参数优化：
性能方面：
1、	加工作进程和连接数
通过worker_processes这条参数来添加我nginx服务的worker进程（设置工作进程），nginx的极限处理连接可能就是5万；可以再event模块设置worker_connections  10000; 参数 ，这是nginx单个worker进程最大处理连接数，理论上nginx服务器并发总量就是worker进程数乘于单个进程处理的连接数

2、	CPU的工作进程绑定
通过 worker_cpu_affinity这条参数来实行CPU的绑定，将worker进程绑定到CPU上，这样的目的是提高工作进程的处理效率，worker_rlimit_nofile 与单个进程连接数一致，ulimit -n 查看当前打开文件描述符的值，加上数值可以指定打开的文件描述符 ulimit -n （65535）最大文件描述符

3、	采用epoll模型
这里我们采用的是epoll模型，处理效率高、更高效，也可以说是IO多路复用模型，采用IO异步非阻塞模式，说到epoll那么我们就应该了解一下select模型，从select的工作原理来说，select通过轮询来检测各个集合中的描述符（fd）状态（那么这里的各个集合指的是select包含着读的集合，写的集合，异常的集合，可以等待），如果说集合中的描述符状态发生改变，则会在该集合中设置相应的标记位；如果指定描述符的状态没有发生改变，那么将指定描述符从对应集合中移除，也就是说客户来一个请求，那么select机制就会扫描一个集合在处理一个连接，这就是select机制

4、	文件缓存优化		
open_file_cache max=204800 inactive=20s;  打开文件缓存的最大个数设置参数，我建议尽量与打开文件数一致，inactive表示经过多长时间后文件没有被请求就删除缓存
open_file_cache_valid 30s; 是指多长时间检查一次缓存的有效信息。
open_file_cache_min_uses 1;   open_file_cache  在失效时间内，这个文件最少被使用多少次，我们就设置1次就可以了，那么被使用一次他就一直被缓存，超出inactive时间依旧被删除
	
5、	连接以及请求
keepalive_timeout  30; 客户端与服务端建立连接的超时时间
client_header_timeout 30;  建立完连接之后的请求头超时时间
client_body_timeout 30; 客户端请求主体读取超时时间
client_header_buffer_size 2k;指定客户端请求头部信息大小为2k，提高客户的请求效率
client_max_body_size 10m;客户端请求的最大的单个文件字节数
client_body_buffer_size 128k;缓冲区代理缓冲用户端请求的最大字节数。
large_client_header_buffers 4 4k;对于客户端较大的请求信息头我们给他缓存的数量为四个，每个缓存最大为4k
sendfile on ;开启高效文件传输模式
tcp_nopush on;防止网络阻塞
tcp_nodelay on;防止网络阻塞

6、	通过压缩实现的高效率
gzip on;开启gzip压缩输出
gzip_min_length 1k;压缩文件的最小字节
gzip_buffers  4 16k;在内存空间里给四个缓冲区，每个缓冲区为16k的内存进行文件压缩
gzip_http_version 1.1;设置识别 http 协议版本，默认是 1.1
gzip_comp_level 2;设置压缩等级
gzip_types text/plain text/javascript application/x-javascript text/css text/xml application/xml application/xml+rss;压缩类型，是就对哪些网页文档启用压缩功能

7、	http之fastCGI
fastcgi_connect_timeout 300;Nginx连接后端fastCGI的超时时间（间接防止恶意性攻击）
fastcgi_send_timeout 300;向FastCGI传送请求的超时时间，这个值是已经完成两次握手后向FastCGI传送请求的超时时间。
fastcgi_read_timeout 300;接收FastCGI应答的超时时间，这个值是已经完成两次握手后接收FastCGI应答的超时时间。
fastcgi_buffer_size 4k;fastCGI做应答的第一部分需要最大的缓冲区为4k。（主要是为了防止信息在传输的过程中堆栈从而导致的效率降低）
fastcgi_buffers 8 4k;fastCGI做应答的最大缓冲区最大为4k，可以有8个缓冲区
fastcgi_busy_buffers_size 8k; Busy==忙的，就是在应答比较忙的时候可以将缓冲区设置为8k，是一般情况下的两倍，buffer==缓存存储
fastcgi_temp_file_write_size 8k;Temp==临时的，写入缓存文件最大数据块为8k,默认值是fastcgi_buffers的两倍
fastcgi_cache_valid 200 302 1h;Valid==有效的，指定200,302状态码缓存一个小时
fastcgi_cache_valid 301 1d; 指定301状态码缓存一天。
fastcgi_cache_valid any 1m;指定任意状态码缓存1分钟。
fastcgi_cache_min_uses 10;URL路径被访问了10次以后，就对这个路径进行缓存。







常用优化项:(优先级排序)

1隐藏版本号

2页面缓存：在配置单中Location模块中添加expries

3防盗链：通过location来定义防盗的具体文件或图片格式，用valid_referers将空referer和自身域名后缀定义为白名单，如果访问请求中referer值不为空，而且访问域名不为自身网站的域名的话，说明此请求来意不善，将使用rewrite重新跳转到一个错误页面；注意，防盗链测试不要和expires一起使用。

4手机电脑页面分离：通过user-agent来判断客户端的设备，在server模块中使用if添加手机型号和操作系统等相关信息来判断，匹配到了就通过rewrite来重定义访问页面的路径。

5禁止抓取工具：也是通过在server中使用if添加httpUA定义相关信息判断是否发送403返回值

6连接超时：keepalive_timeout\client_header_timeout\client_body_timeout

7压缩传输：开启gzip on;gzip_min_length压缩下限;gzip_buffers 缓存区大小与数量;gzip_comp_level压缩等级;gzip_type类型text/application

8访问控制：需求httpd-tools工具(htpasswd -c 文件 用户名来创建用户认证文件)在配置单location中添加auth_basic_user_file指定用户认证文件；allow指定允许登录ip；deny指定拒绝网段

9定义错误页面：通过返回的状态码，用location来自定义错误页面

108自动索引：通过location添加autoindex on;需要注意，索引只支持查看，想下载的话，需要把文件做成压缩包格式才行。

11目录别名：在location中添加alias定义别名访问的路径

12日志分割：通过脚本来进行日志分割，将旧日志修改名称，主要是使用kill -USR1来向指定进程生成新的程序运行日志

13加载第三方模块：于平滑升级过程相似，有两种方法，一是停机加载，二是不停机加载，只不过都是在编译过程中添加--add-module来定义第三方模块的路径(需要已经解压)，区别在于，不停机加载与平滑升级一样，编译完成后不安装，备份原程序的二进制启动文件后，用新程序的进行替换并启动，就完成了加载，但是这样存在着一定的风险性。停机加载相对要安全一些。







调度算法：
在我们公司里面nginx做调度器的话，一般采用的是rr轮训算法和weight加权轮训算法，rr算法就是说客户的请求来了，会按照顺序一一的调用后端节点，那么加权轮询算法是根据服务器的性能进行加权处理，比如说我们公司新进了几台服务器，性能比较好，我们给他进行加权处理，像老服务器啊，性能不好的我们就走，默认轮巡就行

常用算法：
1.	ip_hash（可以解决动态session共享回话问题）
客户的请求来了通过nginx的ip_hash算法进行调度，将请求抛给后端的web节点，当下一次同样的客户再次访问这个网站，那么请求依旧抛给后端的同台web节点
2.	fair（动态算法）
按照后端服务器RS的响应时间来分配请求，响应时间短的优先分配，如果需要使用这类调度算法，必须下载nginx的upstream_fair模块
3.	url_hash
4.	least_conn
最少连接数算法。那个机器连接少就分发



Location表达式类型：
~ 表示执行一个正则匹配，区分大小写
~* 表示执行一个正则匹配，不区分大小写
^~ 表示普通字符匹配。使用前缀匹配。如果匹配成功，则不再匹配其他location
= 进行普通字符精确匹配。也就是完全匹配

Location优先级：
(1)、等号类型(=)的优先级最高。一旦匹配成功，则不再查找其他匹配项。
(2)、^~类型表达式。一旦匹配成功，则不再查找其他匹配项。
(3)、正则表达式类型(~ ~*)的优先级次之。如果有多个location的正则能匹配的话，则使用正则表达式最长的那个。
(4)、常规字符串匹配类型。按前缀匹配。








































