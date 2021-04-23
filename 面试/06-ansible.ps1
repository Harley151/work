
1、command模块
Command模块在远程主机执行命令，不支持管道，重定向等Shell的特性
1.chdir：在远程主机上运行命令前要提前进入的目录
2.creates：在命令运行时创建一个文件，如果文件已经存在，则不会创建任务
3.removes：在命令运行时移除一个文件，如果文件不存在，则不会执行移除任务
4.executeble：指明运行命令的shell程序


2、shell模块           ##个人推荐用shell
Shell模块在远程主机执行命令，相当于调用远程主机的shell进程，然后在该shell下打开一个子shell运行命令，和command模块的区别是它支持shell特性，如管道，重定向等。


3、raw模块
最原始的方式运行命令（不依赖python，仅通过ssh实现）##也支持重定向、管道符、与运算


总结：
command模块调用的shell不是指令，所以没有bash的环境变量，也不能使用shell的一些操作方式，其他和shell没有区别
shell模块调用的/bin/sh指令执行
raw模块很多地方和shell类似，更多的地方建议使用shell和command模块，通常用于无法安装Python的系统（例如网络设备等）


4、copy模块
copy模块用于复制指定主机文件到远程主机的指定位置，常见参数如下
1.dest：指出复制文件的目标目录位置，使用绝对路径。如果源是目录，指目标也要是目录，如果目标文件已经存在会覆盖原有内容
2.src：指出源文件的路径，可以使用相对路径或绝对路径，支持直接指定目录，如果源是目录则目标也要是目录
3.mode：指出复制时，目标文件的权限 可选
4.owner：指出复制时，目标文件的属主 可选
5.group：指出复制时，目标文件的属组 可选
6.content：指出复制到目标主机上的内容，不能与src一起使用，相当于复制content指明的数据到目标文件中



5、hostname模块
hostname模块用于管理远程主机上的主机名

案例：
ansible client:\!my1:\!my2 -m hostname -a "name=ansible"
##  为第三台客户机改名称，名为ansible


6、yum 模块
1.name：程序包的名称，可以带上版本号，如不指定版本号默认安装为最新版本
2.state=present|latest|absent：指明对程序包执行的操作，
pressent表示安装程序包  >>  出席；出现
latest表示安装最新版本的程序包
absent表示卸载程序包   >>  缺席



7、service模块
Service模块为用来管理远程主机上的服务的模块

1.name：被管理的服务名称
2.state=started|stopped|restarted：动作包含启动关闭或重启
3.enabled=yes|no：表示是否设置该服务开机自启动
4.runlevel：如果设定了enabled开机自启动，则要定义在哪些运行目标下自启动



8、User模块
User模块用于管理远程主机上的用户账户



9、script模块   星星五颗
script模块能够实现远程服务器批量运行本地的shell脚本















