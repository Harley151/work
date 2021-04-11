pod 控制器: 
定义：pod 控制器是用来代理用户管理pod的中间层，并确保每一个pod资源始终处于用户定义所期望的目标状态

    Replication Controller: 最早的副本控制器，因为之前这个控制器能完成功能很庞大，现在已被废弃， ReplicaSet是新一代的 Replication Controller
    ReplicaSet: 用户创建指定pod数量的副本，一直满足用户所期望的pod副本数，pod数量多退少补，并支持滚动更新策略以及自动扩缩绒等机制
    以上两种共有的特性：1、用户所期望的副本数，2、标签选择器（通过标签选择器选择自己管理的pod资源，来满足用户所期望的数量）3、支持滚动更新策略以及自动扩缩绒等机制

    Deployment:Deployment 工作在 ReplicaSet之上 ，通过控制 ReplicaSet 来控制 pod 资源，它支持 滚动更新和回滚操作，声明式配置                #只关注的是群体，管理的是无状态的运用
    DaemonSet: 用于确保集群中的每一个节点只运行一个特定的pod副本，通常是用来实现系统级的后台任务，只要新加一个节点则会自动添加特定的pod副本         #只关注的是个体
    Job: 只能执行一次的任务作业，任务完成pod退出，未完成则继续重构                                                                       #只关注的是个体
    Cronjob: 周期性运行，每一次运行都有正常退出的时间                                                                                 #只关注的是个体
    StatefulSet: 管理我们有状态运用，而且每一个pod副本都是被单独管理的，它拥有自己独有的标识



kubectl explain rs                                              #ReplicaSet 简写 rs



#定义 ReplicaSet 副本清单
vim rs-demo.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
    name: myapp
    namespace: default
spec:
    replicas: 2
    selector:
        matchLabels:
            app: myapp
            release: cannry
    template:
        metadata:
            name: myapp-pod
            labels:
                app: myapp
                release: cannry
                environment: tx
        spec:
            containers:
            - name: myapp-container
              image: ikubernetes/myapp:v1
              ports:
              - name: http
                containerPort: 80

kubectl create -f rs-demo.yaml
kubectl get rs
NAME                    DESIRED(期望数量)      CURRENT（当前数量）   READY（就绪数量）   AGE（运行）
myapp                           2                   2               2               8s

kubectl get pods                                            #可以发现template 模板中定义的pod名称没有作用，这个pod资源名称是随机给的
kubectl describe pods myapp-8lgm2                           #查看内容信息
curl 10.244.2.23
kubectl delete pods myapp-8lgm2                             #执行此命令之后，则立刻创建一个pod资源，来满足期望数，之后才会删除原有pod
kubectl get pods --show-labels                              #查看标签是否符合pod创建的标签
kubectl label pods nginx app=myapp release=cannry --overwrite   #通过改动标签使之成为副本中的一员，再次get发现 之前的 pod 已然被杀死
kubectl delete pods nginx                                   #通过删除此 pod ，根据副本定义的数量，则会创建一个新的pod
kubectl get pods                                            #查看 pod






# pod 的 扩缩绒

kubectl edit rs myapp
#将副本数改为5个


# pod 的 版本更新
 
kubectl edit rs myapp
#将镜像下的v1 改为 v2
kubectl get pods  -o wide                                   #获得pod资源的IP
curl 10.244.1.22                                            
Hello MyApp | Version: v1 | <a href="hostname.html">Pod Name</a>                #访问发现只是改的控制器模板下的版本，只有pod被重建之后pod的版本才会跟着改变
例如：
kubectl delete pods 
curl 10.244.1.26
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>                #找到被重新创建的pod发现版本已经改变



# 版本更新逻辑：
现在定义的副本数是5，之前是手动更新版本，如果5个刚好满足用户的需求，删除一个则中断，这时需要更新的话需要临时增加一个新的版本pod，
就解决此问题（我们可以将副本设置一个更新策略），在更新的过程中，根据策略pod最多可以临时添加一个，最少可以少一个pod进行更新，我们可以控制更新的粒度，
比如一下临时添加两个pod，然后删除两个pod依次完成，所以这种更新方式自己完全可以控制，而且这种更新方式默认是灰度更新，滚动式的发布








#Deployment 副本清单

vim deploy-demo.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
    name: myapp
    namespace: default

spec:
    replicas: 2
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
              image: ikubernetes/myapp:v1
              ports:
              - name: http
                containerPort: 80
kubectl apply  -f deploy-demo.yaml                                                         # apply 表示声明式更新声明式创建命令
kubectl get deploy                                                                          #发现deploy副本
kubectl get rs                                                                              #发现有一个 rs 副本
NAME                    DESIRED   CURRENT   READY   AGE
myapp-55d4bfd7b9        2         2         2       38s                                     #myapp 是 depoly的名称，55d4bfd7b9表示模板的哈希值，根据模板变化而变化，不是随机数
kubectl get pods
kubectl get pods
NAME                          READY   STATUS    RESTARTS   AGE
myapp-55d4bfd7b9-g586z        1/1     Running   0          4m43s
myapp-55d4bfd7b9-q4j25        1/1     Running   0          4m43s                            #发现myapp-55d4bfd7b9 是rs 模板名称，后面的就是随机数

编辑 deploy-demo.yaml 配置清单 ，将模板数改为 3

kubectl apply  -f deploy-demo.yaml                                                          #这个可以指定多次，用于创建和更新，每次变化都会同步到etcd中，而后apiserver发现当前pod状态与信息不同，从而将现有状态不断去逼近期望状态
kubectl describe deploy myapp-deploy                                                        #查看详细信息
从中可以发现pod数量为三个



#实现版本更新

#打开另一个终端
kubectl get pods  -l app=myapp -w

编辑 deploy-demo.yaml 配置清单 ，将 版本1 改为 版本2


kubectl apply  -f deploy-demo.yaml

#我们根据 kubectl get pods  -l app=myapp -w 这条指令可以得出，先是创建一个pod然后删除一个pod依次顺序执行最终更新完成

kubectl get pods -o wide
curl 10.244.2.28
Hello MyApp | Version: v2 | <a href="hostname.html">Pod Name</a>                #发现版本改完



kubectl get rs -o wide                                                          #再次发现 现在拥有两个 rs ，老的 rs 已然没有运行的pod 但是对应的模板依然保留着，可以随时进行回滚

kubectl rollout history deployment myapp                                        #获取版本进行回滚
kubectl rollout undo 1                                                          #回滚




更新的时候可以直接打补丁  这就利用到了 patch 命令
kubectl patch deployment myapp -p '{"spec":{"replicas":5}}'                     #发现打完补丁有5个pod资源

kubectl patch deployment myapp -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'               #做多有一个可用，最少有零个不可用，这是更新策略
kubectl describe deployment myapp                                               #可以查看详细信息


#金丝雀发布
kubectl set image deployment myapp myapp=ikubernetes/myapp:v3 && kubectl rollout pause deployment myapp

前一条指令表示将镜像版本改为v3（set image 更改镜像版本 ， deployment 指明控制器名称， myapp 表示容器标明的名称）  ，
第二条指令表示暂停副本更新，金丝雀发布表示，先创建一个新版本的pod资源，看看是否有bug或者异常情况，如果正常在通过新的指令取消副本暂停状态继续更新接下来的pod资源
kubectl rollout status deployment myapp                                                     #查看副本更新状态
kubectl rollout resume deployment myapp && kubectl rollout pause deployment myapp           #表示更新一个暂停更新
kubectl rollout resume deployment myapp                                                     #更新所有pod

kubectl get rs -o wide                                                                      #发现三个版本

#金丝雀回滚
kubectl rollout undo deployment myapp --to-revision=1  && kubectl rollout pause deployment myapp     #回滚到版本 1 的状态  ，如果不指定默认回到上一个版本 ，回滚一个暂停一个
kubectl rollout resume deployment myapp                                                     #全部回滚                                             
kubectl rollout history deployment myapp                                                    #再次查看版本状态，发现版本不同
kubectl get rs -o wide                                                                      #查看是否回到v1








#DaemonSet
每一个节点只运行一个pod副本，它运行着系统级的管理功能，可以把节点上的某个目录当做存储卷关联至pod中，让pod实现其管理功能

kubectl explain ds



vim ds-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: redis
    namespace: default
spec:
    replicas: 1
    selector:
        matchLabels:
            app: redis
            role: logstor
    template:
        metadata:
            labels:
                app: redis
                role: logstor
        spec:
            containers:
            - name: redis
              image: redis:4.0-alpine
              ports:
              - name: redis
                containerPort: 6379
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
    name: myapp-ds
    namespace: default
spec:
    selector:
        matchLabels:
            app: filebeat
            release: stable
    template:
        metadata:
            labels:
                app: filebeat
                release: stable
        spec:
            containers:
            - name: filebeat
              image: ikubernetes/filebeat:5.6.5-alpine
              env:
              - name: REDIS_HOST
                value: redis.default.svc.cluster.local
              - name: REDIS_LOG_LEVEL
                value: info

#env 是给容器内部设置环境变量的， redis.default.svc.cluster.local 表示 dns 解析的域名 ，到时候会创建一个service并绑定redis pod 资源则会找到 redis pod 的 IP

kubectl apply -f ds-demo.yaml
kubectl logs myapp-ds-g6v9j                                             #查看日志
kubectl get deployment
kubectl expose deployment redis --port=6379
kubectl get svc

kubectl exec -it myapp-ds-g6v9j -- /bin/sh  #今日filebeat pod 内部
cat /etc/filebeat/filebeat.yml              #查看日志收集
printenv                                    #查看环境变量





#DaemonSet支持滚动更新

#更新策略：
kubectl explain ds.spec.updateStrategy
kubectl explain ds.spec.updateStrategy.rollingUpdate            #先删除在创建，可以删除多个
kubectl set image daemonsets myapp-ds filebeat=ikubernetes/filebeat:5.6.6-alpine



