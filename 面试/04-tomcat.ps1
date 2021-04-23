tomcat最核心的两个组件：Connector（连接器） 和 Container（容器）
一个service内可以有多个connector（连接器）但是只能有一个container容器的形成，有了service就可以对外提供服务，
但是service需要server给它一个生存环境，那么整个tomcat的生命周期由server控制，connector主要负责对外交流，container主要处理connector接受的请求，并和成一个service对外服务


Java SE（Java Platform，Standard Edition）：Java平台，标准版
Java EE（Java Platform，Enterprise Edition）：Java平台，企业版
Java ME（Java Platform，Micro Edition）：Java平台，微版本

Tomcat是一个java的web容器，Tomcat是实现了javaEE当中的Servlet和JSP规范的一个容器。
Tomcat一般用于动态请求的处理（Servlet）。Tomcat采用组件的方式去设计（面向组件）。整体的功能是通过组件的方式去拼装的。
并且每一个组件都可以进行替换保证了它的一个灵活性。看到下图：
Server 和 Service组件： Tomcat的一个服务器（Server）和Tomcat的服务（Service Tomcat-standalone），主要作用是将连接器（Connector）和引擎（Engine）关联；
连接器（Connector）： 连接器帮助我们把客户端里面的请求连接到我们Tomcat的服务。Tomcat可以配置多个连接器。
在这个连接器中可以指定Service和外部通信的一个协议（HTTP 1.1、HTTPS、AJP： apache 私有协议，用于apache 反向代理Tomcat）。
容器组件（Container ）： 容器组件包含引擎（Engine，默认的引擎叫catalina）、虚拟机（Host）、Context。
Engine主要的作用是将协议解析并转换成request传给虚拟机。
虚拟机（Host） 基于域名分发请求（可以配置多个虚拟机）。
Context隔离每个WEB应用，每一个Context的ClassLoader都是独立的（Tomcat的webapps目录下有一个ROOT文件夹代表的是根路径）。
Tomcat还有一些其它组件，像logger日志管理器、loader载入器、pipeline管道等。这些组件都是内嵌的组件。

1、为什么我们要使用tomcat，类似的软件有哪些？
这是一种趋势部分开发项目使用的都是java语言，在者因为java语言比较稳定非常成熟，相对来说开发的项目要容易一些，网上的文案也有很多，web端口默认是8080
类似的软件有Weblogic （收费）Jboss（免费）Resin、Jetty

2、tomcat优化
内存优化：JAVA_OPTS='-Xms=256m -Xmx=1024m -Xmn=512m'
并发优化：maxProcessors=2000，最大处理线程数
maxSpareThreads=2000，tomcat连接器的最大空闲socket线程数
缓存优化：compressionMinSize=2048，启动压缩的输出内容大小，默认2048

3、tomcat主要端口
8005：这个端口负责监听关闭Tomcat的请求 shutdown:向以上端口发送的关闭服务器的命令字符串。
8009: 与其他http服务通信接口。
8080: 建立http也就是客户端访问连接用。可以修改


4、解决Tomcat启动慢的方法
Tomcat启动慢主要原因是生成随机数的时候卡住了,导致tomcat启动不了。
yum install rng-tools # 安装rngd服务（熵服务，增大熵池）
systemctl start rngd  # 启动服务