1、容器化技术在底层的运行原理？
在 Linux 内核级别上实现了一种新的名为 命名空间（namespace） 的技术，我们知道，操作系统的一个功能就是进程共享公共资源， 诸如，网络和硬盘空间等。 
而docker技术的底层工作原理：就是每个容器运行在它自己的命名空间中，但是，确实与其它运行中的容器共用相同的系统内核。
隔离的产生是由于系统内核清楚地知道命名空间及其中的进程，且这些进程调用系统 API 时，内核保证进程只能访问属于其命名空间中的资源。
对于名称空间的定义我知道一个容器内部有，六种名称空间：UTS（主机名/域名）、User（用户）、Mount（挂载文件系统）、IPC（进程间通信）、Pid（进程ID）、Net（网络）
容器就是将每个进程互相隔离而互不干扰，每个容器都会有自身独立的用户空间，并且所有的容器都共用一个内核，但是
每个用户空间都应该有自己独立主机名和域名、文件系统、IPC（进程间通信的专用通道）、PID（进程编号）、User（用户）、Net（网络），
如果容器之间的IPC可以共享，不然隔离的意义不存在，我们可以将这些称之为名称空年间




2.1、什么是docker-compose？
简单点说就是，docker-compose就是一个编排同时管理多个容器的工具，与它配对使用的是一个docker-compose.yaml文件，
docker-compose命令必须在一个包含docker-compose.yaml文件目录下才能使用。且当下docker-compose命令只能管理当前目录
docker-compose文件中所涉及的容器，安装在机器上的其他容器无法干扰。docker-compose的大部分命令基本和docker的命令重合，
他们唯一的区别是docker命令能管理机器上所有的容器和镜像文件，而docker-compose只能管理当前docker-compose文件所涉及的容器。
2.2、什么是Docker Swarm？
Docker Swarm是Docker的本机群集。它将Docker主机池转变为单个虚拟Docker主机。Docker Swarm提供标准的Docker API，
任何已经与Docker守护进程通信的工具都可以使用Swarm透明地扩展到多个主机。







3、什么是Docker Hub？
Docker Hub是一个由Docker公司运行和管理的基于云的存储库。它是一个在线存储库，Docker进行可以由其他用户发布和使用。





4、dockerfile文件的语法介绍：
    FROM : FROM 指令是dockerfile 文件最重要的指令，必须由他指认基准镜像，后续的指令都是基于此镜像运行环境，若是没有则自动下拉镜像
    语法 : FROM nginx:1.14-alpine

    MAINTAINER : 表明这个Dockerfile文件是谁制作的
    语法 : MAINTAINER "Harley <15156744727@126.com>"
    
    COPY : 将宿主机当前工作目录的文件或几个其他数据打包复制到容器指定目录下
    语法 :  COPY index.html /data/web/html/             #如果容器内没有此目录则会自动创建

    ADD : 支持URL下载的tar文件不展开，指定路径下的tar文件不展开，必须是在当前构建目录才展开tar文件，其他方面和COPY指令一样
    语法 : ADD  http://nginx.org/download/nginx-1.19.6.tar.gz /usr/local/src

    WORKDIR : 容器的家目录
    语法 : WORKDIR /usr/local/src/
    
    VOLUME : 为容器目录
    语法 : VOLUME  /data/mysql

    ENV : 赋值变量
    语法 : 赋值多个变量
    ENV DOC_ROOT /data/web/html \
        WEB_SERVER_PACKAGE="nginx-1.15.2"
    COPY index.html ${/data/web/html}

    EXPOSE : 端口设置
    语法 : EXPOSE 80/tcp

    RUN : 运行shell命令
    语法 : 
    RUN cd /usr/local/src/ && \
        tar -xvf nginx-1.19.6.tar.gz








5、docker 的网络模式

    Bridge 模式:{
        当Docker进程启动时，会在主机上创建一个名为docker0的虚拟网桥，此主机上启动的Docker容器会连接到这个虚拟网桥上。
        虚拟网桥的工作方式和物理交换机类似，这样主机上的所有容器就通过交换机连在了一个二层网络中。
        从docker0子网中分配一个 IP 给容器使用，并设置 docker0 的 IP 地址为容器的默认网关。
        在容器启动之后会生成两个虚拟网卡一个是容器内的eth0，另一个相对应的网卡为主机上的veth虚拟网卡，可以通过brctl show 查看,  yum -y install bridge-utils
        bridge模式是 docker 的默认网络模式,docker run 启动时实际上做了iptables DNAT规则，实现端口转发功能。iptables -t nat -vnL


    }

    Host 模式:{
        如果启动容器时使用的是host模式，那么这个容器将不会获得一个独立的Network Namespace，而是和宿主机共用一个 Network Namespace。
        容器将不会虚拟出自己的网卡，配置自己的 IP 等，而是使用宿主机的 IP 和端口。但是，容器的其他方面，如文件系统、进程列表等还是和宿主机隔离的。
    }

    Container 模式{
        然而这个模式是指，将新创建的容器指定和已经存在的一个容器共享一个 Network Namespace，不会宿主机共享。新创建的容器也不会创建自己的网卡，并配置自己的 IP，
        而是和一个指定的容器共享 IP、端口范围等。同样，两个容器除了网络方面，其他的如文件系统、进程列表等还是隔离的。两个容器的进程可以通过 lo 网卡设备通信。
    }

    None {
        使用none模式，Docker 容器拥有自己的 Network Namespace，但是，并不为Docker 容器进行任何网络配置。
        也就是说，这个 Docker 容器没有网卡、IP、路由等信息。需要我们自己为 Docker 容器添加网卡、配置 IP 等。
    }





6、docker的操作指令都有哪些？

    docker search nginx                        #搜索 Docker Hub镜像仓库内的镜像
    docker pull   nginx::1.14-alpine           #将镜像下载到本地
    docker image  ls                           #列出本地所有镜像，命令：docker image pull ，docker image list
    docker rmi    busybox                      #删除镜像
    docker image rm busybox                    #删除镜像
    docker ps                                  #列出已经运行的容器
    docker container ls                        #列出已经运行的容器
    docker ps -a                               #列出所有容器
    docker create --name myrunoob nginx:latest #创建容器
    docker logs web1                           #查看应用程序日志,加一个选项 -f 是放置在前台显示
    docker info                                #查看系统的运行信息
    docker diff   web1                         #查看容器进程的变化
    docker inspec web1                         #用来查看 Docker 的底层信息。它会返回一个 JSON 文件记录着 Docker 容器的配置和状态信息。
    docker start  b1                           #启动容器
    docker restart web1                        #重新启动容器
    docker stop web1                           #停止容器
    docker start $(docker ps -a | grep Exit |awk '{print $1}')      #启动已经退出的容器
    docker kill b1                             #停止容器的运行
    docker attach web1                         #进入容器,但是确保整个docker中只有一个容器进程在启动中
    docker exec -it web1 /bin/sh               #指定容器进入
    docker cp /opt/1.txt web1:/opt/            #将本地文件复制到容器内部
    docker cp web1:/opt/1.txt /opt/            #将容器内部文件复制到本地
    docker stats -a                            #显示容器正在运行中的硬件信息
    docker pause web1                          #暂停当前处于运行状态的容器
    docker unpause web1                        #恢复处于暂停中的容器
    docker run --restart=always                #服务重新启动后容器也跟着启动（开机自启动）
    docker update --restart=always ID          #更新容器自启动
    docker update --restart=no ID              #取消容器开机自启
    Ctrl+P+Q                                   #进行退出容器，正常退出不关闭容器，如果使用exit退出，那么在退出之后会关闭容器
    --cpus=".5" -m 200M --memory-swap=300M     #资源限制
    docker run -h web1                         #指认容器主机名
    docker run --dns 114.114.114.114           #指认dns地址
    docker run --add-hosts wwww.lois.com:1.1.1.1       #指认hosts解析记录
    docker run -p 81:80                        #指认容器使用的端口,左边为宿主机端口，右边为容器服务端口
    docker run -P                              #暴露所有容器端口
    docker port web1                           #显示指定容器的端口映射
    docker inspect -f {{.Mounts}} web1         #显示容器挂载项
    docker inspect -f {{.NetworkSettings.IPAddress}} web1   #选择的子选项
    
    参考链接：https://docs.docker.com/engine/reference/commandline/docker/
    #危险操作指令：
    docker ps -aq                              #列出所有容器的ID
    docker stop $(docker ps -aq)               #停止所有容器
    docker rm $(docker ps -aq)                 #删除所有容器
    docker images -q                           #列出所有镜像的ID
    docker rmi $(docker images -q)             #删除所有镜像
    
    #容器的资源限制
    docker run --name web2 -d --cpus=".5" -m 200M --memory-swap=300M nginx:1.14-alpine         #其含义是允许该容器最多使用200MB的内存和100MB的swap,使用宿主机0.5个CPU
    docker run -it --rm lorel/docker-stress-ng --vm 2 --vm-bytes 1g                            #对CPU做压力测试

    #镜像和容器的导入导出
    docker save -o nginx.tar nginx:1.14-alpine                                                 #将单个镜像导成一个tar文件
    docker save -o nginx-redis.tar nginx:1.14-alpine redis:4-alpine                            #将两个镜像导成一个tar文件
    docker load -i /root/nginx-redis.tar                                                       #导入镜像，-i 表示从tar归档文件读取镜像，而不是标准输入流
    docker export -o nginx-docker.tar web1                                                     #导出容器（建议是将容器停止之后导出来达到数据的完整性）
    
    #远程获取私有仓库镜像
    默认是到 Docker Hub下拉镜像
    docker pull <registry>[:port]/[<namespace>/]<name>:<tag>                                   #<registry> == 地址 ，port == 端口 ，<namespace> == 用户 ，<name> == 镜像名 ，tag == 标签
    docker pull quay.io/coreos/flannel:v0.10.0-amd64                                           #镜像来自于quay.io服务器 默认走的443端口，是coreos用户flannel镜像，v0.10.0-amd64版本





7、docker怎么制作镜像？
docker run --name b1 -it  busybox:latest
mkdir /data/html/ -p
echo "<h1>busybox httpd server .<h1>" > /data/html/idnex.html
Ctrl+P+Q 或者 重新打开一个终端

docker commit -p b1                                     # -p 指定是在制作镜像时要将服务暂停，不然数据会不完整，现在镜像制作完成，但不会有标签以及用户
docker tag 2d1a8efdf74f mageedu/httpd:v0.1-1            #给这个镜像打上标签
docker tag mageedu/httpd:v0.1-1  mageedu/httpd:latest   #给同一个镜像打上多个标签

#测试镜像是否制作成功
docker run --name t1 -itd mageedu/httpd:latest
docker exec -it t1 /bin/sh
cat /data/html/idnex.html


#推送docker hub仓库
docker login -u mageed              #先登录账号
Password:

docker push mageedu/httpd           #推送镜像






8、为什么要使用Docker
更快的交付和部署。开发人员使用镜像构建标准开发环境，运维和测试人员使用镜像来获得和开发人员相同的运行环境。开发环境和测试运维环境无缝对接，节约开发、测试、部署时间。
更高效的资源利用。相较于虚拟机而言Docker不需要额外的Hypervisor支持，Docker是内核级别的虚拟化，实现更高的性能。
更简单的更新管理。使用Dockerfile，通过简单的修改就可以代替大量的更新操作。






9、Docker虚拟化与虚拟机比较

Docker是操作系统级的虚拟化，内核通过创建多个虚拟的操作系统实例来隔离进程。虚拟机是硬件辅助虚拟化，虚拟的是整个硬件。
虚拟机需要模拟一个独立的OS Kernel而Docker不需要
虚拟机需要一个虚拟机管理程序如VMware，而Docker只需要一个Docker引擎，后者的开销更小
Docker更快妙级，虚拟机分级别
Docker对系统资源需求更少
Docker通过类似Git理念来方便用户获取、分发更新镜像
Docker通过dockerfile实现灵活的创建、部署机制
    虚拟机和Docker本质的区别在于虚拟化的方式不同，虚拟机是一种硬件级别的虚拟化，
    通过软件去模拟硬件系统，并且虚拟机里需要虚拟OS Kernel。Docker是一种容器，是一种隔离机制，是软件级别的模拟。




10、Docker容器有几种状态？
Docker容器可以有四种状态：运行、已暂停、重新启动、已退出





11、什么是虚拟化？
主要有三种类型的虚拟化：

仿真
半虚拟化
基于容器的虚拟化








12、常见问题总结：

(1)、如何批量清理临时镜像文件？
可以使用sudo docker rmi $(sudo docker images -q -f danging=true)命令

(2)、如何查看镜像支持的环境变量？
使用sudo docker run IMAGE env

(3)、本地的镜像文件都存放在哪里
Docker相关的本地资源存放在/var/lib/docker/目录下，其中container目录存放容器信息，graph目录存放镜像信息，aufs目录下存放具体的镜像底层文件。

(4)、容器退出后，通过docker ps 命令查看不到，数据会丢失么？
容器退出后会处于终止（exited）状态，此时可以通过 docker ps -a 查看，其中数据不会丢失，还可以通过docker start 来启动，只有删除容器才会清除数据。

(5)、如何停止所有正在运行的容器？
使用docker kill $(sudo docker ps -q)

(6)、如何清理批量后台停止的容器？
使用docker rm $（sudo docker ps -a -q）

(7)、如何临时退出一个正在交互的容器的终端，而不终止它？
按Ctrl+p，后按Ctrl+q，如果按Ctrl+c会使容器内的应用进程终止，进而会使容器终止。

(8)、很多应用容器都是默认后台运行的，怎么查看它们的输出和日志信息？
使用docker logs，后面跟容器的名称或者ID信息

(9)、使用docker port 命令映射容器的端口时，系统报错Error: No public port ‘80’ published for …，是什么意思？
创建镜像时Dockerfile要指定正确的EXPOSE的端口，容器启动时指定PublishAllport=true

(10)、可以在一个容器中同时运行多个应用进程吗？
一般不推荐在同一个容器内运行多个应用进程，如果有类似需求，可以通过额外的进程管理机制，比如supervisord来管理所运行的进程

(11)、如何控制容器占用系统资源（CPU，内存）的份额？
在使用docker create命令创建容器或使用docker run 创建并运行容器的时候，可以使用-c|–cpu-shares[=0]参数来调整同期使用CPU的权重，使用-m|–memory参数来调整容器使用内存的大小。






13、构建Docker镜像应该遵循哪些原则？
尽量选取满足需求但较小的基础系统镜像，建议选择debian:wheezy镜像，仅有86MB大小 
清理编译生成文件、安装包的缓存等临时文件 
安装各个软件时候要指定准确的版本号，并避免引入不需要的依赖 
从安全的角度考虑，应用尽量使用系统的库和依赖 
使用Dockerfile创建镜像时候要添加.dockerignore文件或使用干净的工作目录






14、仓库（Repository）、注册服务器（Registry）、注册索引（Index）有何关系？
仓库是存放一组关联镜像的集合，比如同一个应用的不同版本的镜像。
注册服务器是存放实际的镜像的地方。
注册索引则负责维护用户的账号，权限，搜索，标签等管理。注册服务器利用注册索引来实现认证等管理。
















































100、docker+jenkins 实现交付图：
https://upload-images.jianshu.io/upload_images/4636177-88409c791f515cc1.png?imageMogr2/auto-orient/strip|imageView2/2/format/webp
参考：https://www.jianshu.com/p/a70572099eda

























