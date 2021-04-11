kubectl 是kube-apiserver 的客户端程序，通过连接到apiserver能够实现各种k8s集群相关对象资源的增删改查操作



常用操作:{

    kubectl get componentstatFus                                                #获取各个组件的运行状态
    kubectl get nodes                                                           #获取各个节点信息
    kubectl get ns                                                              #
    kubectl get pods -n kube-system                                             #获取节点上所有的pod ,而且这些属于kube-system名称空间
    kubectl get pods -n kube-system -o wide                                     #获取集群所有组件
    kubectl version                                                             #获取k8s版本
    kubectl cluster-info                                                        #查看集群的详细信息,kubernetes master:向外输出的地址是，kubeDNS：是集群外部访问的端口转发代理的访问方式
    kubectl run nginx --image=nginx:1.14-apline --port=80 deployment=1          #pod的名称为nginx，--image指认镜像 --port 指认端口，默认端口打开，deployment（副本）指认pod数量
    kubectl run nginx-deploy --image=nginx:1.14-alpine --port=80  --replicas=1  #老版本使用方式
    kubectl get deployment                                                      #查看副本有哪些pod
    kubectl get pods --all-namespaces                                           #查看所有namespace的pods运行情况
    kubectl get pods  kubernetes-dashboard-76479d66bb-nj8wr --namespace=kube-system         #查看具体pods，记得后边跟namespace名字哦
    kubectl get pods -o wide kubernetes-dashboard-76479d66bb-nj8wr --namespace=kube-system  # 查看pods具体信息
    kubectl get cs                                                              # 查看集群健康状态
    kubectl get deployment --all-namespaces                                     # 获取所有deployment
    kubectl get pods --include-uninitialized                                    # 列出该 namespace 中的所有 pod 包括未初始化的
    kubectl get deployment nginx-app                                            # 查看deployment()
    kubectl get rc,services                                                     # 查看rc和servers
    kubectl describe pods xxxxpodsname --namespace=xxxnamespace                 # 查看pods结构信息（重点，通过这个看日志分析错误）,# 对控制器和服务，node同样有效
    kubectl logs $POD_NAME                                                      # 查看pod日志
    kubectl exec my-nginx-5j8ok -- printenv | grep SERVICE                      # 查看pod变量
    # 集群
    kubectl get cs                                                              # 集群健康情况
    kubectl cluster-info                                                        # 集群核心组件运行情况
    kubectl get namespaces                                                      # 表空间名
    kubectl version                                                             # 版本
    kubectl api-versions                                                        # API
    kubectl get events                                                          # 查看事件
    kubectl get nodes                                                           #获取全部节点
    kubectl delete node k8s2                                                    #删除节点
    kubectl rollout status deploy nginx-test
    # 创建
    kubectl create -f ./nginx.yaml                                              # 创建资源
    kubectl create -f .                                                         # 创建当前目录下的所有yaml资源
    kubectl create -f ./nginx1.yaml -f ./mysql2.yaml                            # 使用多个文件创建资源
    kubectl create -f ./dir                                                     # 使用目录下的所有清单文件来创建资源
    kubectl create -f https://git.io/vPieo                                      # 使用 url 来创建资源
    kubectl run -i --tty busybox --image=busybox                                #----创建带有终端的pod
    kubectl run nginx --image=nginx                                             # 启动一个 nginx 实例
    kubectl run mybusybox --image=busybox --replicas=5                          #----启动多个pod
    kubectl explain pods,svc                                                    # 获取 pod 和 svc 的文档
    # 更新
    kubectl rolling-update python-v1 -f python-v2.json                          # 滚动更新 pod frontend-v1
    kubectl rolling-update python-v1 python-v2 --image=image:v2                 # 更新资源名称并更新镜像
    kubectl rolling-update python --image=image:v2                              # 更新 frontend pod 中的镜像
    kubectl rolling-update python-v1 python-v2 --rollback                       #  退出已存在的进行中的滚动更新
    cat pod.json | kubectl replace -f -                                         # 基于 stdin 输入的 JSON 替换 pod
    强制替换，删除后重新创建资源。会导致服务中断。
    kubectl replace --force -f ./pod.json
    为 nginx RC 创建服务，启用本地 80 端口连接到容器上的 8000 端口
    kubectl expose rc nginx --port=80 --target-port=8000
    更新单容器 pod 的镜像版本（tag）到 v4
    kubectl get pod nginx-pod -o yaml | sed 's/\(image: myimage\):.*$/\1:v4/' | kubectl replace -f -
    kubectl label pods nginx-pod new-label=awesome                              # 添加标签
    kubectl annotate pods nginx-pod icon-url=http://goo.gl/XXBTWq               # 添加注解
    kubectl autoscale deployment foo --min=2 --max=10                           # 自动扩展 deployment “foo”
    # 编辑资源
    kubectl edit svc/docker-registry                                            # 编辑名为 docker-registry 的 service
    KUBE_EDITOR="nano" kubectl edit svc/docker-registry                         # 使用其它编辑器
    # 动态伸缩pod
    kubectl scale --replicas=3 rs/foo                                           # 将foo副本集变成3个
    kubectl scale --replicas=3 -f foo.yaml                                      # 缩放“foo”中指定的资源。
    kubectl scale --current-replicas=2 --replicas=3 deployment/mysql            # 将deployment/mysql从2个变成3个
    kubectl scale --replicas=5 rc/foo rc/bar rc/baz                             # 变更多个控制器的数量
    kubectl rollout status deploy deployment/mysql                              # 查看变更进度
    # 删除
    kubectl delete -f ./pod.json                                                # 删除 pod.json 文件中定义的类型和名称的 pod
    kubectl delete deployment myapp-test                                        # 删除副本，pod资源也会随之删除
    kubectl delete pod,service baz foo                                          # 删除名为“baz”的 pod 和名为“foo”的 service
    kubectl delete pods,services -l name=myLabel                                # 删除具有 name=myLabel 标签的 pod 和 serivce
    kubectl delete pods,services -l name=myLabel --include-uninitialized        # 删除具有 name=myLabel 标签的 pod 和 service，包括尚未初始化的
    kubectl -n my-ns delete po,svc --all                                        # 删除 my-ns namespace下的所有 pod 和 serivce，包括尚未初始化的
    kubectl delete pods prometheus-7fcfcb9f89-qkkf7 --grace-period=0 --force 强制删除

    # 交互
    kubectl logs nginx-pod                                                      # dump 输出 pod 的日志（stdout）
    kubectl logs nginx-pod -c my-container                                      # dump 输出 pod 中容器的日志（stdout，pod 中有多个容器的情况下使用）
    kubectl logs -f nginx-pod                                                   # 流式输出 pod 的日志（stdout）
    kubectl logs -f nginx-pod -c my-container                                   # 流式输出 pod 中容器的日志（stdout，pod 中有多个容器的情况下使用）
    kubectl run -i --tty busybox --image=busybox -- sh                          # 交互式 shell 的方式运行 pod
    kubectl attach nginx-pod -i                                                 # 连接到运行中的容器
    kubectl port-forward nginx-pod 5000:6000                                    # 转发 pod 中的 6000 端口到本地的 5000 端口
    kubectl exec nginx-pod -- ls /                                              # 在已存在的容器中执行命令（只有一个容器的情况下）
    kubectl exec nginx-pod -c my-container -- ls /                              # 在已存在的容器中执行命令（pod 中有多个容器的情况下）
    kubectl top pod POD_NAME --containers                                       # 显示指定 pod和容器的指标度量
    # 调度配置
    $ kubectl cordon k8s-node                                                   # 标记 my-node 不可调度
    $ kubectl drain k8s-node                                                    # 清空 my-node 以待维护
    $ kubectl uncordon k8s-node                                                 # 标记 my-node 可调度
    $ kubectl top node k8s-node                                                 # 显示 my-node 的指标度量
    $ kubectl cluster-info dump                                                 # 将当前集群状态输出到 stdout                                    
    $ kubectl cluster-info dump --output-directory=/path/to/cluster-state       # 将当前集群状态输出到 /path/to/cluster-state
    #如果该键和影响的污点（taint）已存在，则使用指定的值替换
    $ kubectl taint nodes foo dedicated=special-user:NoSchedule


}


nginx操作 :{
cat create_deployment_nginx_app2.yaml
apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: nginx-app2
spec: 
  replicas: 1 
  selector: 
    matchLabels:
       app: nginx 
  template: 
    metadata: 
      labels: 
        app: nginx 
    spec: 
      containers: 
      - name: nginxapp2-container 
        image: nginx:latest 
        imagePullPolicy: IfNotPresent 
        ports: 
        - name: nginxapp2
          containerPort: 80

    kubectl apply -f create_deployment_nginx_app2.yaml 
    kubectl get deployment.apps
    kubectl get rs
    kubectl get pods
    kubectl get pods -o wide
    curl http://172.16.235.129


    #给pod 一个固定端点，到时候访问客户端固定端点即可，而固定端点是service提供的
    kubectl expose 暴露服务 ， --port=80 指定service ip的端口 映射给容器--target-port=80内部的端口,
    deployment nginx-deploy 意思是将这个控制器相关的pod资源都创建一个服务 ，服务名叫--name=nginx
    kubectl get deployment  #得到控制器下面的pod名称，为：nginx-app2
    kubectl expose deployment nginx-app2 --name=nginx --port=80 --target-port=80 --protocol=TCP     #发布成功

    kubectl get svc
    创建出来的TYPE默认是ClusterIP，CLUSTER-IP是根据集群的10.96.0.0 16个掩码动态生成的ip{
        NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
        kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   40h
        nginx        ClusterIP   10.99.150.133   <none>        80/TCP    5m49s
    }
    切记！service 是为pod提供固定访问端点的，service IP 对应 pod IP ，service port 对应 pod port，但是这种端点不支持集群外部访问,但更多的是被客户端访问。 

    访问：
    curl 10.99.150.133

    
    kubectl get pods -n kube-system -o wide | grep coredns                  #获取coredns IP地址
    kubectl get svc -n kube-system                                          #获取kube-dns 服务地址，通过这个地址解析nginx
    yum -y install bind-utils                                               #安装dig命令
    dig -t A nginx @10.96.0.10

    kubectl run client --image=busybox --replicas=1 -it --restart=Never     #在创建一个pod ，--restart=Never pod不重启。{
        cat /etc/resolv.conf
        nameserver 10.96.0.10
        search default.svc.cluster.local svc.cluster.local cluster.local
        nameserver 的IP就是集群的dns，而svc.cluster.local域名是kubernetes 本地pod资源特定后缀，default 是这个pod的所属的名称空间的名字

        打开另一个master终端
        dig -t A nginx.default.svc.cluster.local @10.96.0.10{
            ;; ANSWER SECTION:
            nginx.default.svc.cluster.local. 30 IN  A       10.99.150.133
            解析出来的IP就是web pod发布的service nginx 标签名
        }

        返回原始终端{
            wget -O - -q http://nginx                                       #通过nginx 服务名 解析成ip 获取web 资源 
        }
        kubectl get pods
        kubectl delete pods nginx-app2-7b78bfb8c8-dghj9                     #删除pod之后会根据副本自动在生成一样的pod

        再返回原来终端{
            wget -O - -q http://nginx                                       #还是能获取web 资源 
        }
        
        最终的出结论：这就是所谓的他们通过标签和标签选择器所关联pod资源，而不是通过地址来选择，所以无论pod怎么变化，
        他只要属于那个deployment,只要是kubectl expose deployment 指定 的pod，都会纳入到我们的服务端，service 用的不是iptables规则，而是ipvs规则

        kubectl get pods --show-labels                                      #获取pod标签
        kubectl describe svc nginx                                          #查看nginx 服务资源的详细信息
        kubectl edit svc nginx                                              #针对NGINX控制器配置单进行修改（例如更改IP）


        #动态扩容
        kubectl create deployment myapp --image=ikubernetes/myapp:v1 --replicas=3     #创建副本并启动pod资源
        kubectl get deployment -o wide -w                                             #查看副本,-w 放置前台显示
        kubectl create service clusterip  myapp --tcp=80:80                           #公布节点，左边是对外端口，右边是容器内部端口
        打开另一个终端：
        kubectl run client --image=busybox --replicas=1 -it --restart=Never
        kubectl get svc                                                               #获取ip
        wget -O - -q 10.104.225.16 或者 wget -O - -q 10.104.225.16/hostname.html      #先是得到web内容，后是得到pod名称
        while true;do wget -O - -q 10.104.225.16/hostname.html;sleep 1 ;done          #不断访问不同的pod
        #开始针对pod扩缩容
        kubectl scale --replicas=5 deployment myapp                                   #创建5个pod
        while true;do wget -O - -q 10.104.225.16;sleep 1 ;done                        #不断访问web页面
        #滚动更新
        kubectl set image deployment myapp myapp=ikubernetes/myapp:v2                 #将版本升级到v2
        kubectl rollout status deployment myapp                                       #检查控制器的更新过程
        while true;do wget -O - -q 10.104.225.16;sleep 1 ;done                        #发现已经更新完成

        #回滚更新
        kubectl rollout undo deployment myapp                                         #回滚到上一个版本

        iptables -vnL -t nat                                                          #规则
        #更改类型让web浏览器访问
        kubectl edit svc myapp                                                        #修改副本内容
        找到TYPE ClusterIP 更改为NodePort
        kubectl get svc                                                               #发现80端口后面又有一个端口，通过浏览器访问此端口                                             
        输入：http://192.168.88.11:31708/                                             #便能在浏览器访问资源内容
    }

    kubectl get svc 
    service 生成了一个服务nginx，并且默认生成了一个iptables/ipvs规则，把所有访问到CUSTER-IP  和 PORT 的都调度至标签选择器关联到的哥pod后端
}
