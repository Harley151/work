calico 不支持 ipvs
calico 以 Pod形式部署
单独部署 calico/node \ calico-cni \ calico/kube-policy-controller
calico 应该也有etcd存储，但是为了实现统一管理，那么就必须要通过k8s的apiserver调用写入

mkdir /root/mainpod/calico
cd /root/mainpod/calico
curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml 

kubectl get pods -n kube-system                                 # 发现一共三个Pod，而每个Pod拥有2个容器

Network policy 控制两种不同的通信流量
Egress（出站），表示自己作为原地址，对方作为目标地址进行通信，表示Pod作为客户端去访问别人的
Ingress（入站），表示自己是目标地址，对方远程是原
客户端端口是随机的，目标端口是可预测的

通过PodSelecto，选择指定Pod，控制进出入规则
可以为不同名称空间内的Pod设置出入规则


kubectl explain networkpolicy.spec
Egress（出站）
Ingress（入站）
podSelector: 不管是出站还是入站，应该选择哪个Pod
policyTypes: 策略类型，如果给 ingress 那么 ingress，如果给了 Egress 那么 Egress 生效 ，同时给的话同时生效

kubectl explain networkpolicy.spec.egress
ports : 目标端口可以有多个
      port(端口名)
      protocol(端口协议)
to    : 目标地址
      ipBlock:  目标地址是一种地IP址块，范围
      namespaceSelector: 名称空间选择器，控制某个Pod能到达某个名称空间Pod，进行通信
      podSelector:  控制两种Pod进行通信



kubectl explain networkpolicy.spec
from: 目标是自己
      ipBlock:  目标地址是一种地IP址块，范围
      namespaceSelector: 名称空间选择器，控制某个Pod能到达某个名称空间Pod，进行通信
      podSelector:  控制两种Pod进行通信

ports: 端口是自己

mkdir /root/mainpod/networkPolicy
cd /root/mainpod/networkPolicy

vim ingress-def.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}       # 为空表示选择所有Pod
  policyTypes:
  - Ingress             # 只有Ingress生效


kubectl create namespace dev
kubectl create namespace prod

kubectl apply -f ingress-def.yaml  -n dev             # 创建Pod手动指定名称空间,表明现在访问dev名称空间的Pod都被拒绝，因为他定义了Ingress入站规则，并没有指认那个端口和IP，默认是所有端口和IP

kubectl get netpol -n dev                             # 查看 Ingress 入站规则

vim pod-ingress.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1

kubectl apply -f pod-ingress.yaml -n dev
kubectl apply -f pod-ingress.yaml -n prod
kubectl get pods -n dev -o wide                 # 发现 IP 为 10.244.1.4
kubectl get pods -n prod -o wide                # 发现 IP 为 10.244.1.5
curl 10.244.1.4                                 # 一直没有响应，表示被禁止了
curl 10.244.1.5
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>

vim ingress-def.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}       # 为空表示选择所有Pod
  ingress:
  - {}                  # 表明所有Pod都允许访问，如果没定义是拒绝所有的
  policyTypes:
  - Ingress             # 只有Ingress生效

kubectl apply -f ingress-def.yaml -n dev
curl 10.244.1.4
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>
curl 10.244.1.5
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>

两个IP都可以被访问到了


# 打标签

kubectl label pods pod app=myapp -n dev         # 任何在dev名称空间中拥有myapp标签的都允许对他的80端口进行访问
kubectl get pods --show-labels -n dev

vim allow-netpol-demo.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: all-myapp-ingress
spec:
  podSelector:
    matchLabels:
      app: myapp
  ingress:
  - from:
    - ipBlock:
        cidr: 10.244.0.0/16   # 允许这个网段的IP网此Pod
        except: 
        - 10.244.1.2/32    # 不允许这个IP访问此Pod
    ports:
    - protocol: TCP
      port: 80                # 允许访问的端口是 80，不指认表示所有端口
kubectl apply -f allow-netpol-demo.yaml -n dev

kubectl get netpol -n dev
all-myapp-ingress   app=myapp      19s          # 已经生效了







