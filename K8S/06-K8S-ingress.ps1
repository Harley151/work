
Ingress：（制定规则）

我们先了解一下service的暴露方式：
共有三种：ClusterIP、NodePort与LoadBalance
ClusterIP的方式只能在集群内部访问。
NodePort方式的话，测试环境使用还行，当有几十上百的服务在集群中运行时，NodePort的端口管理是灾难。
LoadBalance方式受限于云平台，且通常在云平台部署ELB还需要额外的费用。

而k8s提供了一种集群维度暴露服务的方式，也就是ingress。ingress可以简单理解为service的service，他通过独立的ingress对象来制定请求转发的规则，
把请求路由到一个或多个service中。这样就把服务与请求规则解耦了，可以从业务维度统一考虑业务的暴露，而不用为每个service单独考虑。
比如：
我们现在有三个url分别是：www.abc.com/aaa、www.abc.com/bbb、www.abc.com/ccc 
ingress规则也是很灵活的，外部请求到达ingress时，会通过自身的规则将不同域名、不同path转发请求到不同的service，并且支持https/http。
参考:https://imgconvert.csdnimg.cn/aHR0cHM6Ly9zZWdtZW50ZmF1bHQuY29tL2ltZy9iVmJ2Y0ZY?x-oss-process=image/format,png



Ingress-controller：（Pod代理，也可以说是负载均衡器）
ingress-controller并不是k8s自带的组件，实际上ingress-controller只是一个统称，用户可以选择不同的ingress-controller实现，
目前，由k8s维护的ingress-controller只有google云的GCE与ingress-nginx两个，其他还有很多第三方维护的ingress-controller，
具体可以参考官方文档。但是不管哪一种ingress-controller，实现的机制都大同小异，只是在具体配置上有差异。一般来说，
ingress-controller的形式都是一个pod，里面跑着daemon程序和反向代理程序。daemon负责不断监控集群的变化，
根据ingress对象生成配置并应用新配置到反向代理，比如nginx-ingress就是动态生成nginx配置，动态更新upstream，
并在需要的时候reload程序应用新配置。为了方便，后面的例子都以k8s官方维护的nginx-ingress为例。



ingress与ingress-controller
要理解ingress，需要区分两个概念，ingress和ingress-controller：

ingress对象：
指的是k8s中的一个api对象，一般用yaml配置。作用是定义请求如何转发到service的规则，可以理解为配置模板。

ingress-controller：
具体实现反向代理及负载均衡的程序，对ingress定义的规则进行解析，根据配置的规则来实现请求转发。
简单来说，ingress-controller才是负责具体转发的组件，通过各种方式将它暴露在集群入口，外部对集群的请求流量会先到ingress-controller，
而ingress对象是用来告诉ingress-controller该如何转发请求，比如哪些域名哪些path要转发到哪些服务等等。



与其他k8s对象一样，ingress配置也包含了apiVersion、kind、metadata、spec等关键字段。有几个关注的在spec字段中，
tls用于定义https密钥、证书。rule用于指定请求路由规则。这里值得关注的是metadata.annotations字段。在ingress配置中，
annotations很重要。前面有说ingress-controller有很多不同的实现，而不同的ingress-controller就可以根据
"kubernetes.io/ingress.class:"来判断要使用哪些ingress配置，同时，不同的ingress-controller也有对应的annotations配置，
用于自定义一些参数。列如上面配置的'nginx.ingress.kubernetes.io/use-regex: "true"',最终是在生成nginx配置中，会采用location ~来表示正则匹配。



ingress的部署，需要考虑两个方面：

1、ingress-controller是作为pod来运行的，以什么方式部署比较好
2、ingress解决了把如何请求路由到集群内部，那它自己怎么暴露给外部比较好

Deployment+LoadBalancer模式的Service
如果要把ingress部署在公有云，那用这种方式比较合适。用Deployment部署ingress-controller，创建一个type为LoadBalancer的service关联这组pod。
大部分公有云，都会为LoadBalancer的service自动创建一个负载均衡器，通常还绑定了公网地址。只要把域名解析指向该地址，就实现了集群服务的对外暴露。

Deployment+NodePort模式的Service
同样用deployment模式部署ingress-controller，并创建对应的服务，但是type为NodePort。这样，ingress就会暴露在集群节点ip的特定端口上。
由于nodeport暴露的端口是随机端口，一般会在前面再搭建一套负载均衡器来转发请求。该方式一般用于宿主机是相对固定的环境ip地址不变的场景。
NodePort方式暴露ingress虽然简单方便，但是NodePort多了一层NAT，在请求量级很大时可能对性能会有一定影响。

DaemonSet+HostNetwork+nodeSelector
用DaemonSet结合nodeselector来部署ingress-controller到特定的node上，然后使用HostNetwork直接把该pod与宿主机node的网络打通，
直接使用宿主机的80/433端口就能访问服务。这时，ingress-controller所在的node机器就很类似传统架构的边缘节点，比如机房入口的nginx服务器。
该方式整个请求链路最简单，性能相对NodePort模式更好。缺点是由于直接利用宿主机节点的网络和端口，一个node只能部署一个ingress-controller pod。比较适合大并发的生产环境使用。






我们要知道客户端访问我们的服务是基于HTTPS协议来访问后端的work节点，如果是这样那么每一个work节点都要有HTTPS，因为只有这个客户与服务之间才能建立HTTPS会话，现在我们期望在调度的那一层就实现HTTPS
现在我们的k8s集群内部调度器要么是ipatabls，要么是ipvs，都是基于4层调度，是没有办法实现的，而kubernetes采用一种独特的方式实现

后端被代理的pod不适用HTTPS，他们就是纯纯的HTTP，而代理pod使用的是HTTPS，拥有HTTPS的pod代理后端接受请求
（请求发送给node_balance调度-->多个node节点的NodePort-(转换)->service_IP-->https_pod-->后端http_pod）,被称之为特殊pod
或者
代理pod使用node宿主机的网络名称空间，node_balance直接调度至https_pod，在调度给后端的Pod，但唯一不好的是调度器调度的是一个pod，使用的是一个名称空间，这就形成了一个单点，如果pod代理不正常了，那么服务就停止了


DaemonSet（Ingress Controller）
在每个节点上都创建一个DaemonSet Pod，而每个节点只运行一个DaemonSet Pod，而这些DaemonSet Pod是专门用来接入7层调度的web流量，
假如我们的k8s有300个节点，而只拿出三个节点运行引入https的DaemonSet Pod，我们把这三个节点打上污点，让别的pod都调度不上来，
定义DaemonSet 控制的Pod只运行这三个节点之上，并且能够容忍这些污点，从而着三个节点的DaemonSet Pod 提供外部接入的七层调度流量

Ingress Controller  是一个自己独立运行的或一组pod资源，它通常就是一个应用程序（就是拥有七层代理能力的应用程序）
Ingress Controller  可以有三种选择做七层代理，默认是Nginx
Nginx
Triefik （微服务）
Envoy（服务网格）

请求流程：
客户请求-->externalLB（外部负载均衡器）-->一个Node_Port_service --> Ingress Controller
--> Ingress 定义的方式（虚拟主机还或者RL） --> 每个主机名所对应一组pod --> pod被定义为一组是通过service分组才能被 Ingress 引用

1、部署 Ingress Pod
2、定义 Ingress
3、定义后端pod设置service并进行pod分组，之后 Ingress 与后端pod关联关系

# mkdir ingress-nginx
# cd ingress-nginx
# for i in deployment.yaml kustomization.yaml prometheus.yaml role-binding.yaml role.yaml service-account.yaml service.yaml
# do
# wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/prometheus/$i
# done
# kubectl apply -f ./

裸机使用：
部署ingress-controller-pods:
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/baremetal/deploy.yaml
将Deployment配置文件替换为以下内容：

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.25.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 33
            runAsUser: 33
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
            - name: https
              containerPort: 443
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10

kubectl apply -f deploy.yaml
kubectl get pods -n ingress-nginx                   #查看是否启动成功
kubectl describe pods ingress-nginx-controller-67897c9494-6qv9r -n ingress-nginx    #状态




部署默认的backend 后端 以及 ingress规则需要调度的 service

mkdir ingress
cd ingress

vim deploy-demo.yaml 
apiVersion: v1
kind: Service
metadata:
    name: myapp
    namespace: default
spec:
    selector:
        app: myapp
        release: cannry
    ports:
    -   name: http
        port: 80
        targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: myapp-deploy
    namespace: default

spec:
    replicas: 3
    selector:
        matchLabels:
            app: myapp
            release: cannry
    template:
        metadata:
            labels:
                app: myapp
                release: cannry
        spec:
            containers:
            - name: myapp
              image: ikubernetes/myapp:v2
              ports:
              - name: http
                containerPort: 80
kubectl apply -f deploy-demo.yaml 
kubectl get pod --show-labels
kubectl get svc


引入外部流量方法：
# 一、更改Ingress-controller配置，让他使用节点的网络名称空间
# 二、部署 service_Node_Port(目的是接入集群外部流量)
vim  service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
    name: ingress-nginx
    namespace: ingress-nginx
spec:
    type: NodePort
    ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080
      protocol: TCP
    - name: https
      port: 443
      nodePort: 30443
      protocol: TCP
    selector:
        app: ingress-nginx

kubectl apply -f service-nodeport.yaml
kubectl get svc -n ingress-nginx

# 定义 ingress 规则
vim ingress-myapp-yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
    name: ingress-myapp
    namespace: default
    annotations:
        kubernetes.io/ingress.class: "nginx"
spec:
    rules:
    - host: myapp.magedu.com
      http:
        paths:
        - path:
          backend:
            serviceName: myapp
            servicePort: 80
kubectl apply -f ingress-myapp-yaml
kubectl get ingress



kubectl exec -n ingress-nginx -it ingress-nginx-controller-67897c9494-6qv9r -- /bin/bash
cat nginx.conf

修改电脑 /etc/hosts
172.21.40.162 myapp.magedu.com
172.21.40.163 myapp.magedu.com


浏览器访问:
kubectl get pods -n ingress-nginx               # 查看引入外部流量的端口
myapp.magedu.com:30593

节点配置hosts:
while true;do curl http://myapp.magedu.com:30593/hostname.html;sleep 1;done
myapp-deploy-5b6987f576-5sts6
myapp-deploy-5b6987f576-lhnx9
myapp-deploy-5b6987f576-z4p8r
会不断轮询三个pod





# 设置backend 后端 pod 为 Tomcat
vim tomcat-deploy.yaml 
apiVersion: v1
kind: Service
metadata:
    name: tomcat
    namespace: default
spec:
    selector:
        app: tomcat
        release: cannry
    ports:
    -   name: http
        port: 8080
        targetPort: 8080
    -   name: ajp
        port: 8009
        targetPort: 8009
---
apiVersion: apps/v1
kind: Deployment
metadata:
    name: tomcat-deploy
    namespace: default

spec:
    replicas: 3
    selector:
        matchLabels:
            app: tomcat
            release: cannry
    template:
        metadata:
            labels:
                app: tomcat
                release: cannry
        spec:
            containers:
            - name: tomcat
              image: tomcat:8.5.32-jre8-alpine
              ports:
              - name: http
                containerPort: 8080
              - name: ajp
                containerPort: 8009

vim ingress-tomcat.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
    name: ingress-tomcat
    namespace: default
    annotations:
        kubernetes.io/ingress.class: "nginx"
spec:
    rules:
    - host: tomcat.magedu.com
      http:
        paths:
        - path:
          backend:
            serviceName: tomcat
            servicePort: 8080

kubectl apply -f tomcat-deploy.yaml
kubectl exec tomcat-deploy-8b6965fd7-fgcxg -- netstat -tnl
kubectl get svc
kubectl apply -f ingress-tomcat.yaml
kubectl get ingress

修改电脑 /etc/hosts
172.21.40.162 myapp.magedu.com tomcat.magedu.com
172.21.40.163 myapp.magedu.com tomcat.magedu.com

浏览器访问:
tomcat.magedu.com:30593

节点配置hosts:
curl tomcat.magedu.com:30593





通过 HTTPS 进行访问后端


vim ingress-tomcat.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
    name: ingress-tomcat
    namespace: default
    annotations:
        kubernetes.io/ingress.class: "nginx"
spec:
    rules:
    - host: yl5v.xyz
      http:
        paths:
        - path:
          backend:
            serviceName: tomcat
            servicePort: 8080

kubectl apply -f tomcat-deploy.yaml

yl5v.xyz  域名已经通过 cloudflare 解析完成的
浏览器访问一下，看看解析有没有问题

http://yl5v.xyz:30593/

mkdir /data/ssl -pv             # 将证书目录放入此目录下
ls /data/ssl/yl5v.xyz/
ca.cer  fullchain.cer  yl5v.xyz.cer  yl5v.xyz.conf  yl5v.xyz.csr  yl5v.xyz.csr.conf  yl5v.xyz.key


secret 也是 k8s 中标准的资源对象，下面 创建一个secret 来引用 pod 

kubectl create secret tls tomcat-ingress-secret --cert=/data/ssl/yl5v.xyz/fullchain.cer --key=/data/ssl/yl5v.xyz/yl5v.xyz.key

tls                     # secret 对象格式
tomcat-ingress-secret   # secret 名称
--cert=                 # 指认证书路径
--key=                  # 指认key文件路径

kubectl get secret 
tomcat-ingress-secret   kubernetes.io/tls                     2      2m6s
kubectl describe secret tomcat-ingress-secret               # 查看详细信息

vim ingress-tomcat-tls.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
    name: ingress-tomcat-tls
    namespace: default
    annotations:
        kubernetes.io/ingress.class: "nginx"
spec:
    tls:
    - hosts: yl5v.xyz
      secretName: tomcat-ingress-secret
    rules:
    - host: yl5v.xyz
      http:
        paths:
        - path:
          backend:
            serviceName: tomcat
            servicePort: 8080

kubectl delete -f ingress-tomcat.yaml 
kubectl apply -f ingress-tomcat-tls.yaml
kubectl describe ingress ingress-tomcat-tls

kubectl exec -n ingress-nginx -it ingress-nginx-controller-67897c9494-6qv9r -- /bin/bash
cat nginx.conf | grep ssl_certificate -w -A 1
        ssl_certificate     /etc/ingress-controller/ssl/default-fake-certificate.pem;
        ssl_certificate_key /etc/ingress-controller/ssl/default-fake-certificate.pem;

可以看到证书已经配置成功

通过浏览器访问打开正常证书也没问题：
https://yl5v.xyz:31719/