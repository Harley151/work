资源：对象
    workload(工作负载)
        Pod，ReplicaSet,Deployment,StatefulSet,DaemonSet,Job,Cronjob
    服务发现以及负载均衡
        service，ingress，....
    配置与存储：Volume，CSI（容器存储接口，来存储各种各样的第三方存储卷）
        ConfigMap，Secret(保存敏感数据的配置中心，其中需要加密和解密)
    集群及资源
        NmaeSpace（名称空间），Node，Role(角色)，clusterRole（集群角色）Rolebinding（角色绑定），ClusterRolebingding（集群角色绑定）
    元数据型资源
        HPA（可以调整其他资源元数据信息），PodTemplate（用于控制器创建pod时使用的模板），limitRange（定义资源限制）



kubectl get pod nginx-app2-7b78bfb8c8-7277d -o yaml                             #输出资源清单{
    apiVersion: v1                                                              #API群组集群版本,版本分为内侧版，公测版（beta），稳定版
    kind: Pod                                                                   #致命资源类，例如，service类，pod类，控制器
    metadata：元数据（后面嵌套很多二级字段）
    spce：定义我们所期望的拥有怎样特性的资源
}

创建资源的方法:{
    apiserver仅接受JSON格式的资源定义；
    yaml格式提供配置清单，apiserver可自动将其转化为JSON格式，而后在提交；
}

大部分资源配置清单:{
    apiVersion：组名/版本                                                        #API群组集群,kubectl  api-versions，显示支持的群组
    kind：资源类别                                                               #资源类别，比如你需要创建service资源那么kind 就定义为service，创建pod资源pod，就定义pod
    metadata：元数据，提供的主要字段{
        name：在同一类别当中name是唯一的
        namespace：
        lables
        annotations                                                             #资源注解，可以证明这个配置清单所写者

        每个资源的引用PATH
            /api/GROUP/VERSION/namespaces/NAMESPACE/TYPE/NAME
    }
    spce：(这是一个很重要的字段，用来规格我们所期望的资源应该拥有什么样的特性，而后靠控制器能否被满足)

    status：当前状态，current state ，本字段有kubernetes集群维护；   让当前状态无线向期望状态靠近（如一个副本生成5个pod那么删除一个，这是就要根据status状态，让期望状态满足）
    kubectl explain pods                                                        #显示pod资源该怎么定义
    kubectl explain pods.spec                                                   #显示pod一下的spec可用的对象字段

    #注意：资源配置清单之所以会写成yaml格式，是因为apiserverr组件只接受JSON格式的定义，并将yaml文件自动转为JSON，而后在提交在执行
}



创建资源清单{
mkdir mainpod
cd mmainpod

vim pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
  - name: busybox
    image: busybox:latest
    command:
    - "/bin/sh"
    - "-c"
    - "echo $(date) >> /usr/share/nginx/html/indexx.html; sleep 300"
    #或者
    #command:["/bin/sh","-c","echo $(date) >> /usr/share/nginx/html/indexx.html; sleep 300"]
这个资源定义了，一个po跑了两个容器



kubectl create -f pod-demo.yaml                                                             #生成配置模板
kubectl get pods
kubectl describe pods pod-demo                                                              #获取这个pod-demo运行后的详细信息，包括日志
kubectl get logs pod-demo myapp                                                             #获取pod-demo下myapp容器的日志
kubectl get logs pod-demo busybox                                                           #获取pod-demo下busybox容器的日志
kubectl delete pods pod-demo
kubectl create -f pod-demo.yaml
kubectl exec -it pod-demo -c myapp -- /bin/sh                                               #exec -it（进行交互前台运行） 指定进入那个pod ，-c 指的是进入指定容器 -- 不用管 /bin/sh 给个环境进入
}












kubectl api-versions                                                        #显示可选的apiVersion 版本


#定义字段说明：
#pod 资源清单
kubectl explain pods:{

    apiVersion: v1
    kind: Pod
    metadata:{
        annotations:{
            资源注解，可以证明这个配置清单所写者
            }
        labels:{
            通常是给pod资源打上标签，是方便service根据标签选择器根据pod标签名字选择pod，并导出对应的端点，就是给客户提供一个固定的访问端点，
            需要通过标签名选择对应的pod资源，提供服务（因为pod资源的IP不是固定的，pod资源经常会更新或者弹性伸缩资源，所以通过service给出一个固定的IP代理多个pod资源访问）
            }

        name:{
            定义这个pod资源的名称，要和spce字段下的容器字段对应
            }

        namespace:{
            名称空间给出default默认即可
            }

        }



    spec:{

        containers:{      <object>表示会有多个子字段，-requite-表示必选字段，<string>表示字符串
            通常会嵌套多个字段：
            name:{

                }

            image:{

                }

            ports:{
                #容器对外暴露的端口
                name:{
                    暴露端口的名称
                }
                containerPort:{
                    暴露的端口
                }
                #案例：(同时暴露多个端口)
                - name: http
                containerPort: 80
                -name: https
                containerPort: 443
                这个作用并不能真正意义上暴露端口的作用，其目的是通过配置清单看到我需要暴露的端口，以方便创建service指定pod端口名暴露映射端口，没给协议默认是TCP协议
                }

            imagePullPolicy:{
                #镜像的获取策略:
                Always（不管本地有还是没有镜像，都要到公网仓库下载）, Never（本地有就下载，没有就不用）, IfNotPresent（如果本地没有镜像则去公网仓库下载）
                #Defaults to Always if :latest tag is specified, or IfNotPresent otherwise.
                }

            lables:{
                #一个pod可以同时打上多个标签，也可以说同样的标签可以打在多个pod资源上，标签可以在对象创建时指定，也可创建之后通过命令来管理(增删改查)
                }

            args:{
                args 类似于 docker 中的 cmd
                #表示需要传递的参数
                #参考链接：https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/
                
                }

            command:{
                command 类似于 docker 中的 entrypoint
                #表示要运行的程序
                command:["/bin/sh","-c","echo $(date) >> /usr/share/nginx/html/indexx.html; sleep 300"]
                或者
                command:
                - "/bin/sh"
                - "-c"
                - "echo $(date) >> /usr/share/nginx/html/indexx.html; sleep 300"
                }

            env:{

                }

            evnFrom:{

                }

            priority:{
                生命周期
                }
            livenessProbe:{
                #下面有三种探针
                exec:
                httpGet:
                TCPSocket:

                failureThreshold:           默认是三个周期，表示探测三次次表示容器启动是失败的
                periodSeconds:              周期间隔时长，默认是10秒探测一次
                timeoutSeconds:             每次的超时时间，发出探测始终没有相应，需要等多久，默认是1秒
                initialDelaySeconds:        初始化延迟探测时间，别还没等容器初始化完成呢，探针就开始工作了，这样就回导致错误，默认是容器已启动就探测
                }
            readinessProbe:{
                #就绪性探测，和 livenessProbe 相同
                }
            lifecycle:{
                #生命周期，主要是定义启动后终止前的钩子
                postStart: 启动后，容器被启动创建之后而立即执行的操作，如果操作失败了，那么这个容器将被终止并且重启，而重启与否会根据容器的重启策略
                    {
                        #也是指定的三种行为；
                        exec:
                        httpGet:
                        TCPSocket:
                    }
                preStop:   终止前对应的pod终止之前，立即执行测操作
                    {
                        #也是指定的三种行为；
                        exec:
                        httpGet:
                        TCPSocket:                          
                    }
            priorityClassName:{
                存活性探测
                }
            
            readinessGates:{
            #就绪状态探测
                }
        nodeSelector:{
            #通过指定节点标签指定pod必须在哪个节点上运行
            disktype: sshd      #通过这个字段指定标签
            }
        nodeName:
        restartPolicy: (三种重启策略)
            Always（总是重启）,Never（从不）,OnFailure



    
    
        }

    status:{
        #
        }

    }

# 














#ReplicaSet 副本

kubectl explain rs:{

    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:{
        name:
        namespace:
        }
    spec:{
        replicas:
        selector:
            matchLabels:
                #下面案例是以键值对形式选择pod资源作为副本数
                app: myapp
                release: cannry
        template:
            metadata:
                name: myapp-pod #没有作用
                labels:  # 创建的这个标签一定要满足matchLabels:下面的标签，如果不一样，那么永远都不符合副本所选择的pod标签，pod也会一直创建下去，宁可比它多
                    app: myapp
                    release: cannry
                    environment: tx
            spec:                                           #是template模板下的字段spec，下面就是用户期望创建的pod资源
                containers:
                - name:
                  image:
                  ports:
                  - name:
                    containerPort:
        }


    }
#










#Deployment副本

kubectl explain deploy:{
    apiVersion:
    kind:
    metadata:
    spec:{
        
        replicas:
        selector:
        template:
        strategy:   #最终要的一个字段，叫做更新策略{
            type:
                #更新策略类型
                Recreate: 重建式更新，就是删一个建立一个pod
                RollingUpdate: 用来控制更新粒度，这个取决于strategy下的rollingUpdate字段
            
            rollingUpdate:{
                maxSurge: 表示在对应的更新过程当中，最多能超出用户所指定的pod副本数为几个，有两种取值方式一个是指定的数值，一个是百分比
                maxUnavailable: 表示最多有几个不可用，意思是在更新的过程中最多删除几个pod进行更新
                }
            }
        revisionHistoryLimit:
        

        minReadySeconds: 表示用户在做滚动更新以后，最多在历史当中保存过去多少个历史版本，默认是10个
        paused: 暂停，当我们启动更新的时候，没有立即更新，而是一启动就暂停了





        }































    }













