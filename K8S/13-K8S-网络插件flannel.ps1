k8s 解决网络通信模型问题：
• 容器间通信: 同一个pod内的多个容器间的通信，指定的是lo网卡
• Pod通信:   Pod IP <--> Pod IP k8s中要求pod与pod通信必须要直达，不能进行NAT转换（我们知道pod之间工作在不同的节点上）
• Pod 与 service 之间的通信: Pod IP <--> cluster IP (他们两个在不同的网段下，只是通过iptables或者ipvs规则下进行通信的)
• Service与集群外部客户端的通信；
• 不同节点下容器之间的通信；


CNI:容器网络接口，k8s自身并不解决网络方案，它允许托管插件使用第三方解决方案(解决上面列出的通信问题)，下面比较流行的有
    flannel
    calico
    canel
    kube-router
    ...

kubelet, 如果要使用 第三方网络插件 将插件的配置文件放入 /etc/cni/net.d  目录下被加载为网络插件使用
cat /etc/cni/net.d/10-flannel.conflist 

网络网卡的生成: k8s调用此目录下的flannel文件，由网络插件代为实现地址分配，接口创建、网络创建等
目前flannel能够实现网络的管理 缺陷是网络的策略


flannel 默认使用vxlan网络模式方式


1.Flannel的backend
    1.前面说过Flannel实质上是一种覆盖网络overlay（叠加网络）解决方案，也就是将TCP数据包装在另一种网络包里面进行路由转发和通信，
      它支持UDP、VxLAN、host-gw、AWS VPC、GCE和Ali Vpc路由等数据转发方式；
    2.而由于flannel是一个应用程序，它的守护进程（flannled）可以管理、修改跨节点的flannel.1接口之间的报文是通过哪种协议进行封装转发的，
      这种封装方式称为flannel的Backend（后端）；而Flannel的Backend有下面几种类型，用的最多的是前三种；

2.1.Vxlan：
    1.VXLAN模式使用比较简单，可以理解为是一个二层协议隧道，它是flannel的默认模式；在Vxlan模式下，flannel会在各节点生成一个flannel.1的VXLAN网卡（VTEP设备）；
      而VXLAN模式下封包与解包的工作是由内核进行的.flannel不转发数据，仅动态设置ARP和FDB表项；如上图示VXLAN模式下k8s中跨主机的Pod的通信过程：
        1.容器A中的数据包会先发到veth pair的另一端，也就是cni0上
        2.cni0通过匹配主机A中的路由表信息,将数据包发送到flannel.1接口
        3.flannel.1是一个VTEP设备,收到报文后按照VTEP的配置进行封包.根据flannel.1设备创建时设置的参数VNI、local IP、Port进行VXLAN封包；
        4.主机A通过物理网卡eth0发送封包到 主机B的物理网卡eth0中
        5.主机B的物理网卡eth0再通过VXLAN默认端口8472转发到VTEP设备flannel.1进行解包
        6.解包以后根据IP头匹配路由规则, 内核将包发送到cni0
        7.cni0发送到连接在veth pair另一端的容器B中完成通信；
    2.VXLAN也有两种模式：
        1.vxlan：
            第一种是vxlan叠加网络模式，利用内核级别的VXLAN来封装host之间传送的包
        2.Directrouting：
            Directrouting是vxlan的一种特殊属性；虽然vxlan是一种隧道报文方式，但是它可以降级称为host-gw方式，也就是说vxlan可以直接像host-gw那样在二层物理直接通信，条件是：
                如果所有宿主机节点都在同一个物理网络中（不跨路由器）就工作为host-gw模式，如果不在同一个物理网络中（不跨路由器）就工作为vxlan模式；
                我们可以在部署flannel模式为vxlan时将Directrouting（直接路由）属性打开，有助于性能提升；
        Vxlan的传输效率低的问题：
        如上图Vxlan封装二层报文的格式，是虽然是flannel的默认、常用模式，但由于需要额外的封包和拆包，它的MTU是小于默认的1500；这也是很多人认为Flannel网络传输效率相对低的原因；
2.2.UDP：
    UDP是指四层UDP协议隧道，是所有模式中性能最差的；设计出UDP是有原因的：
        因为在flannel设计最初时有些发行版的linux内核还比较老不支持VxALN，为了能够兼容这些较老系统，flannel设计出UDP这种代替Vxlan的方案；早期很多人认为flannel性能很差就是因为当时UDP的性能差决定的，而如今的VXLAN性能其实并不差，所以在生产环境中是不会使用UDP模式的.
2.3.host-gw：
    1.flannel不仅提供基于封装类型的技术vxlan，也提供基于路由技术的互联技术host-gw模式，host-gw是host-gateway的意思，是将主机作为网关，基于路由技术完成纯三层的ip转发；
    2.host-gw直接路由的逻辑是：把node节点上的每个Pod容器通过物理网桥直接接入到物理网络中，把node节点的网络接口当做pod的网关使用，这样相当于是所有Pod在物理网络（同一个网段）中直接通信，这种不需要解封包的方式在三种模式中性能是最好的，但是有局限性：
        1.原因一因为通过物理网桥直接接入到物理网络中相当于是在物理网络中直接通信，就意味着都是使用MAC地址通信，那么所有宿主机节点IP都必须在同一个物理网络中不能跨路由器!这样的话网络设备间的距离就受限了、相应的数量、范围也就受限了!所以host-gw模式仅适用于二层直接可达的网络；
        2.原因二是因为在host-gw模式下随着集群中节点规模的增大，flannel维护主机上成千上万条路由表（n(n-1)/2条路由）的动态更新也是一个不小的压力，因此在路由方式下，路由表规则的数量是限制网络规模的一个重要因素；
        3.host-gw模式下，负责维护、动态更新主机上路由表信息的是flanneld守护进程；
    3.如上图示，可以解释为什么host-gw要求主机网络二层直接互联？
        从上面的抓包结果可以看出host-gw在传输层走的是tcp，然后在网络层的源IP和目的IP均是容器的IP，也就是虚拟IP，这就决定了二层互联，因为只有交换机是不关注源IP和目的IP；假如两台主机在两个vlan中，二层不通，三层通，那么就需要路由器，而路由器是无法识别容器的这些ip，当然也可以配置路由规则，但是显然没有这么做的。
2.4.aws-vpc：
    使用 Amazon VPC route table 创建路由，适用于AWS上运行的容器
2.5.gce：
    使用Google Compute Engine Network创建路由，所有instance需要开启IP forwarding，适用于GCE上运行的容器
2.6.ali-vpc：
    使用阿里云VPC route table创建路由，适用于阿里云上运行的容器
使用场景说明：
    所有节点都在同一个网段，并且二层网络可能通信，可以考虑选择Host-gw模式。反之节点之间不能通过二层网络通信，可能在不同vlan中，可以考虑选择Vxlan模式，也可以考虑使用 Vxlan Directrouting 模式(默认是false)





kubectl get daemonset -n kube-system                # 我们发现flannel 是以 DaemonSet（后台守护进程） 的形式运行的，并且那个节点上有kubelet那个节点就必须要有flannel（因为有kubelet就必须有pod，而Pod需要进行网络通信）

kubectl get configmap -n kube-system| grep flannel  # 这个是用来配置flannel是怎么运行的
kube-flannel-cfg                     2      62d
kubectl get configmap -o json -n kube-system

flannel的参数配置：
    Network: flannel使用的是CIDR格式的网络地址，用于Pod配置网络功能;
        一、
        10.244.0.0/16 -->
            master: 10.244.0.0/24
            node1: 10.244.1.0/24
            node255: 10.244.255.0/24
            网络位是Pod IP
        
        二、
        10.0.0.0/8
            10.0.0.0/24
            ...
            10.255.255.0/24
    
    SubnetLen: 把Network切分子网络供各节点使用时，使用多长的掩码进行切分，默认是24位掩码；
    SubnetMin: 10.244.10.0/24
    SubnetMax: 10.244.100.0/24

    Backend: vxlan,host-gw,udp







# 配置flannel使用Directrouting模式的VXLAN

kubectl apply -f deploy-demo.yaml 
kubectl get pods -o wide

kubectl exec -it myapp-55d4bfd7b9-zlzgr -- /bin/sh      # 进入node1上的Pod  10.244.1.31

kubectl exec -it myapp-55d4bfd7b9-phc2h -- /bin/sh      # 进入node2上的Pod  10.244.2.24

node1 ping node2
ping 10.244.2.24


mkdir flannel
cd flannel
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
vim kube-flannel.yml
在"Backend" 下添加 "Directrouting": true
kubectl apply -f kube-flannel.yml           # 进入node1 终端上 输入 ip route show 如果显示一下内容，就表明可以直接通过物理网卡直接通信了，如果不行要删除flannel在创建，这里建议一定是在安装的使用部署
10.244.0.0/24 via 172.21.40.161 dev eth0 
10.244.2.0/24 via 172.21.40.163 dev eth0 
# kubectl delete -f kube-flannel.yml
# kubectl apply -f kube-flannel.yml 
kubectl delete -f ../deploy-demo.yaml 








