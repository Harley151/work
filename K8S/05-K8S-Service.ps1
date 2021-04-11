service 名称解析是强依赖于CoreDNS附件的，部署完k8s也是必须要部署的CoreDNS
三类IP：
node network
pod network
cluster network 也可以叫做service network
前两种网络是实实在在的网络设备（也有可能是硬件也有可能是软件模拟的），而第三类地址则是虚拟存在的IP网络，仅存在于service规则当中（virtual IP）

kube-proxy组件通过k8s 当中固有的watch（监视）请求方式始终监视着apiserver当中有关service的变动信息，
并随时获取任何一个与service资源相关的变动状态，最后将这种变动信息转换为当前节点之上的service请求规则，这种规则有可能是iptables规则也有可能是ipvs规则，这取决于service的实现方式



service的三种工作模式：

第一种请求:（userspce）
客户请求服务的pod资源，首先会请求各个服务pod的对应端点service IP也就是内核空间的service规则，
然后由内核空间的service将请求分发到各个用户空间节点之上的kube-proxy组件，再由组件将请求分发至不同的pod资源，
响应的话就是原路返回，主要说明的是，请求从用户空间到内核空间再到用户空间，响应的时候又是从用户空间返回内核空间再返回给用户空间的客户端，这种的请求效率就很低下

第二种请求:（iptables）
用户空间客户请求 --> 内核空间service IP （iptables） --> 用户空间 pod Server，服务响应 --> 内核空间service IP （iptables） --> 返回数据给用户空间的client

第三种请求: (ipvs)
用户空间客户请求 --> service IP（ipvs）--> 用户空间 pod Server，服务响应 --> service IP （ipvs） --> 返回数据给用户空间的client

k8s版本在1.11版本之前模式使用的是userspce，1.11之后默认用的是ipvs，ipvs没有被激活（是指在安装k8s时编辑k8s配置文件，禁用swap，再额外添加一个变量，内核中添加关于ipvs的模块，才能激活ipvs）将会降级为IPtables

如果说是创建一个pod副本或者是一个自主式pod，通常我们会给pod打上能够与service关联的标签，
然后创建的指令会发送给apiserver组件，apiserver会将配置请单内容记录到etcd当中，
这时候各个节点之上的kube-proxy 组件一直会watch（监视）到有关service的变动信息，发现创建的pod标签适用于自己的标签选择器选择，则作为自己的资源后端


service类型：
    ExternalName（表示将集群外部的服务应用到集群内部来）, ClusterIP（默认为cluster，仅用于集群内部通信）, NodePort（集群外部通信）, and LoadBalancer


service 清单:

vim redis-svc.yaml

apiVersion: v1
kind: Service
metadata:
    name: redis
    namespace: default
spec:
    selector:
        app: redis
        role: logstor
    clusterIP: 10.97.97.97          #如果不自己定义IP则会自随机生成一个IP地址
    type: ClusterIP
    ports:
    - port: 6379                    #表示service IP上的端口
      targetPort: 6379              #表示pod IP 上的端口
    # nodePort: 6379                #表示被集群外部访问的端口  

kubectl apply -f redis-svc.yaml
kubectl get svc
kubectl describe svc redis
Name:              redis
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          app=redis,role=logstor
Type:              ClusterIP
IP Families:       <none>
IP:                10.97.97.97
IPs:               10.97.97.97
Port:              <unset>  6379/TCP
TargetPort:        6379/TCP
Endpoints:         10.244.1.38:6379
Session Affinity:  None
Events:            <none>


Endpoints概念:

Endpoints是k8s中标准的对象，可以说是service与pod的中间层，service不会直接与pod交互，而是直接到 Endpoints(有IP+端口)，再由 Endpoints关联后端pod（可以手动为service创建 Endpoints资源 ）



NodePort访问:

vim myapp-svc.yaml 
apiVersion: v1
kind: Service
metadata:
    name: myapp
    namespace: default
spec:
    selector:
        app: myapp
        release: canary
    clusterIP: 10.99.99.99          #如果不自己定义IP则会自随机生成一个IP地址
    type: NodePort
    ports:
    - port: 80                      #表示service IP上的端口
      targetPort: 80                #表示pod IP 上的端口
      nodePort: 30080               #表示被集群外部访问的端口,端口保证在30000~32767之间，默认是动态分配的

kubectl apply -f myapp-svc.yaml 
kubectl get svc
myapp        NodePort    10.99.99.99     <none>        80:30080/TCP   6s

通过集群外访问此节点上的IP:30080 端口

while true;do curl http://172.21.40.162:30080/hostname.html;sleep 1;done
while true;do curl http://172.21.40.162:30080;sleep 1;done
注意: 如果显示连接被拒，那么你就需要看一下你的标签选择器，有没有和pod的标签相对应上。并且访问的时候一定要访问work 节点的 IP ，master 节点IP不返回数据




集群内部pod client 访问集群外部的 pod服务 实现方式：
通过 ExternalName 可实现此操作，1、我们在集群内部创建一个service端点，这个service不是本地pod，而是service关联到外部服务上去了，
pod 客户端请求，service然后由 service 与 node 做SNAT层级转换，将请求发送至集群外部节点IP，然后响应再由节点响应至集群内部node，再由node做DNAT转换发送给service，再返回给客户端的流程
这个类似于使用内部服务一样使用外部服务



通过打补丁的方式绑定同一客户端请求始终发送同一客户端pod   （用到的是Client字段,默认是 none）
kubectl patch svc  myapp -p '{"spec":{"sessionAffinity":"ClientIP"}}'
while true;do curl http://172.21.40.162:30080/hostname.html;sleep 1;done        #发现请求被绑定

改为 None 就能立即调度了
kubectl patch svc  myapp -p '{"spec":{"sessionAffinity":"None"}}'
while true;do curl http://172.21.40.162:30080/hostname.html;sleep 1;done        #发现请求随机



无头 service 的实现
service关联至后端的多个Pod ，一开始创建 service 都是有一个固定的IP都具有一个名称空间的 ，
但是这时我们将service的名称空间去掉（这就叫无头），创建几个pod，而每个pod都有自己的名称空间，都有自己独立的IP
如果service的名称空间去掉那么后端关联的service将关联新创建的Pod IP，service的IP取决于我们创建多少Pod ，ClusterIP None 字段为空给出
vim myapp-svc-headless.yaml 
apiVersion: v1
kind: Service
metadata:
    name: myapp-svc
    namespace: default
spec:
    selector:
        app: myapp
        release: canary
    clusterIP: None
    ports:
    - port: 80
      targetPort: 80
kubectl apply -f myapp-svc-headless.yaml 
kubectl get svc


dig -t A myapp-svc.default.svc.cluster.local. @10.96.0.10           #@10.96.0.10 通过 kubectl get svc -n kube-system 获取，他是DNS解析
;; ANSWER SECTION:
myapp-svc.default.svc.cluster.local. 30 IN A    10.244.2.38
myapp-svc.default.svc.cluster.local. 30 IN A    10.244.2.39
myapp-svc.default.svc.cluster.local. 30 IN A    10.244.1.43
myapp-svc.default.svc.cluster.local. 30 IN A    10.244.1.44
myapp-svc.default.svc.cluster.local. 30 IN A    10.244.2.42

这些service IP 实际就是 pod IP ，也就是一个service拥有5个IP，这些内容显示的有点慢，后面会用到
