StatefulSet:(有状态应用副本集)
    无状态的只关注群体
特性：
1、需要每一个节点、每一个Pod、稳定且唯一的网络标识符；
2、稳定且持久的存储；（pod删除，存储卷不能被回收）
3、要求有序、平滑的部署和扩展；（例如redis集群，先启动主节点、然后从节点）
4、有序、平滑的终止和删除；（缩减整个redis集群的规模，串行启动，串行关闭，逆序关闭）
5、有序的滚动更新；（一般先更新从节点，而且是逆序的，将所有的从节点更新完毕，才更新主节点）

StatefulSet由三个组件组成：
    headless service（无头服务）、StatefulSet控制器、volumeClaimTemplate（存储卷申请模板）

对于有状态集而言，每个节点的名字是不能动的，他相当于表示符



以redis 集群为例，不同的redis他们存储的数据都不相同，那么每个节点上的redis都有自己专用的存储卷，一定不能共享给其他节点

对于无状态的pod副本而言，他们使用副本的模板创建的存储卷是共享的，那么有声明式的pod就提出了一个组件 volumeClaimTemlate

这样我们在创建每一个pod时会自动创建一个 PVC ，从而绑定一个 PV ，有自己专用的存储卷


kubectl explain sts.spec:
replicas: 有几个副本
selector: 选择哪些pod有自己管理
serviceName: 必须要关联到一个无头服务上，并基于这个无头服务才能给一个pod分配一个唯一的持久的固定的表示符
template: 每个pod中的存储卷是由template定义的，PVC 是由volumeClaimTemplate 来创建的





cd /root/mainpod/state

vim kubectl apply -f stateful-demo.yaml 

apiVersion: v1
kind: Service
metadata:
  name: myapp
  labels:
    app: myapp-svc
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: myapp-pod
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: myapp
spec:
  serviceName: myapp
  replicas: 3
  selector: 
    matchLabels:
      app: myapp-pod # has to match .spec.template.metadata.labels
  template:
    metadata:
      labels:
        app: myapp-pod
    spec:
      containers:
      - name: myapp
        image: ikubernetes/myapp:v1
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: myappdata
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:   #可看作pvc的模板
  - metadata:
      name: myappdata
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 2Gi

如果报错先删除对应PVC名称，在进行创建
kubectl delete pvc myappdata-myapp-0
kubectl delete pvc --all                                    # 删除所有 PVC

kubectl apply -f stateful-demo.yaml 

kubectl get sts
myapp   3/3     2m5s

kubectl get pvc
NAME                STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
myappdata-myapp-0   Bound    pv001    2Gi        RWO,RWX                       2m31s
myappdata-myapp-1   Bound    pv002    5Gi        RWO,RWX                       2m26s
myappdata-myapp-2   Bound    pv005    10Gi       RWO,RWX                       2m21s

kubectl get pv
NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                       STORAGECLASS   REASON   AGE
pv001   2Gi        RWO,RWX        Retain           Bound       default/myappdata-myapp-0                           10h
pv002   5Gi        RWO,RWX        Retain           Bound       default/myappdata-myapp-1                           10h
pv003   20Gi       RWO,RWX        Retain           Available                                                       10h
pv004   10Gi       RWO,RWX        Retain           Released    default/mypvc                                       10h
pv005   10Gi       RWO,RWX        Retain           Bound       default/myappdata-myapp-2                           10h

kubectl get pods
myapp-0                         1/1     Running   0          4m25s
myapp-1                         1/1     Running   0          4m20s
myapp-2                         1/1     Running   0          4m15s



# 查看终止过程
kubectl get pods -w
kubectl delete -f stateful-demo.yaml    # 发现会按照逆序进行删除



每一个pod的名字都可以被解析
kubectl exec -it myapp-0 -- /bin/sh
nslookup myapp-0
Address 1: 10.244.1.84 myapp-0.myapp.default.svc.cluster.local

nslookup myapp-1.myapp.default.svc.cluster.local            # 要想解析，那么就必须要跟上service的名字myapp
Address 1: 10.244.2.67 myapp-1.myapp.default.svc.cluster.local

pod_name.servoce_name.ns_name.cluster.local                 # 解析固定格式


# pod 扩缩容
kubectl scale sts myapp --replicas=5                        # 直接扩容为5个
kubectl patch sts myapp -p '{"spec":{"replicas":2}}'        # 直接缩容为2个副本


ikubernetes



# 滚动更新
kubectl explain sts.spec.updateStrategy
rollingUpdate: 可以实现自己的更新策略是怎么替换的
    partition:  他支持分区更新，默认值就是0，分区就是pod标识
type:  

kubectl patch sts myapp -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":4}}}}'      # 打补丁更新，标识根据pod的标识符（名称数字），大于等于4 的标识符，就更新

kubectl describe sts  myapp | grep RollingUpdate -A 1
Partition:        4
发现Partition定义的为4

kubectl set image sts/myapp myapp=ikubernetes/myapp:v2                  # myapp 是容器名字后面跟的是镜像版本

kubectl get sts -o wide
myapp   5/5     176m   myapp        ikubernetes/myapp:v2                # 发现镜像版本为2

kubectl get pods myapp-3 -o yaml | grep -w "image:"                     # 发现这个容器使用的版本还是v1的
kubectl get pods myapp-4 -o yaml | grep -w "image:"                     # 发现最后一个容器使用的版本已经是v2了
他也支持金丝雀发布
kubectl patch sts myapp -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'  # 所有pod 一并更新了

kubectl get pods myapp-0 -o yaml | grep -w "image:"                     # 发现最后一个容器使用的版本已经是v2了






























