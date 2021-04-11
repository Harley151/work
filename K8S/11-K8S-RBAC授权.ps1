授权插件: Node,ABAC,RBAC,webhook
    RBAC: Role-based AC


用户  角色  权限（Permissions（Operations，Objects）） 这三者关系

用户可以扮演不同的角色，（用户绑定角色）
角色可以拥有不同的权限。（角色绑定权限）

名称空间的角色绑定
role:（角色）
    Operations
    Objects

rolebinding:(绑定)
    user account 或者 service account
    role

集群级别的角色绑定
clusterrole（集群角色）  ， clusterrolebinding（集群的账户绑定某种角色）

角色绑定权限关联的三种形式：

user --> RoleBinding --> Role                       # 拥有名称空间角色的权限

user --> clusterrolebinding --> clusterRole         # 拥有集群角色的权限

user --> rolebinding --> clusterRole                # 拥有名称空间角色的集群权限


# 创建Role

kubectl create  role pods-reader --verb=get,list,watch --resource=pods --dry-run -o yaml > role-demo.yaml           
vim role-demo.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pods-reader
  namespace: default
rules:
- apiGroups:
  - ""
  resources:
  - pods    # 针对的资源对象
  verbs:    # 针对的操作
  - get
  - list
  - watch
kubectl apply -f role-demo.yaml                 # 创建一个角色，并给这个角色定义怎样的权限
kubectl get role                                # 获取角色内容
kubectl describe role name-reader
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
  pods[资源类]       []          [资源类下的名字]  [get list watch]


# 创建Rolebinding
kubectl create rolebinding magedu-read-pods --role=pods-reader --user=magedu  -o yaml --dry-run=client  > rolebinding-demo.yaml
kubectl apply -f rolebinding-demo.yaml          # 已经实现完全绑定
kubectl describe rolebinding magedu-read-pods
Name:         magedu-read-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pods-reader（绑定到这个角色上了）
Subjects:
  Kind  Name    Namespace
  ----  ----    ---------
  User  magedu（用户）  

kubectl config use-context magedu@kubernetes

kubectl get pods        # 发现这次获取了许多的pods资源
kubectl get pods -n kube-system             # 这次要突破别的名称空间是不允许的，只能对当前名称空间生效



useradd ik8s
cp -r ~/.kube/ /home/ik8s/
chown -R ik8s.ik8s /home/ik8s/
su ik8s
kubectl config use-context magedu@kubernetes
kubectl get pods
这样用普通用户可以获取资源


# 创建clusterRole
kubectl create  clusterrole cluster-reader --verb=get,list,watch --resource=pods  -o yaml --dry-run=client > clusterRole-demo.yaml
vim clusterRole-demo.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-reader
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
kubectl apply -f clusterRole-demo.yaml



# 创建clusterrolebinding
kubectl create clusterrolebinding magedu-read-all-pods --clusterrole=cluster-reader --user=magedu  -o yaml --dry-run=client  > clusterrolebinding-demo.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: magedu-read-all-pods
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: magedu
kubectl apply -f clusterrolebinding-demo.yaml 

kubectl describe clusterrolebinding magedu-read-all-pods
Name:         magedu-read-all-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  cluster-reader
Subjects:
  Kind  Name    Namespace
  ----  ----    ---------
  User  magedu 


测试magedu这个用户权限

su ik8s
kubectl config use-context magedu@kubernetes
kubectl get pods -n kube-system                     # 发现这次也能读了
kubectl get pods -n ingress-nginx
kubectl delete pods myapp-deploy-5b6987f576-5sts6       # 发现删除不掉，只有读权限



# 测试 rolebinding 绑定 clusterrole
kubectl delete clusterrolebinding magedu-read-all-pods
kubectl create rolebinding magedu-read-pods --clusterrole=cluster-reader --user=magedu --dry-run=client -o yaml > rolebinding-clusterrole-demo.yaml
vim rolebinding-clusterrole-demo.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: magedu-read-pods
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-reader
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: magedu
kubectl apply -f rolebinding-clusterrole-demo.yaml 

kubectl describe rolebinding  magedu-read-pods
Name:         magedu-read-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  ClusterRole
  Name:  cluster-reader
Subjects:
  Kind  Name    Namespace
  ----  ----    ---------
  User  magedu  


kubectl get pods -n ingress-nginx               # 这次访问其他名称空间报错


kubectl get clusterrole admin -o yaml           # 这个是admin 用户角色使用的操作


kubectl create rolebinding default-ns-admin --clusterrole=admin --user=magedu           # 给这个magedu用户绑定到了admin集群角色上了


kubectl delete pods myapp-deploy-5b6987f576-5sts6       # 具有删除权限了
kubectl get deployment                                  # 能够获取到资源了
kubectl get pods -n ingress-nginx                       # 不能获取其他名称空间的内容


