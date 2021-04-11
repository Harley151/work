mkdir /root/mainpod/schedule
cd /root/mainpod/schedule

vim pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: frontend
  annotations:
    magedu.com/create-by: "cluster admin"
spec:
  containers:
  - name: myapp
    image: ikubernetes/myapp:v1
    ports:
    - name: http
      containerPort: 80
  nodeSelector:
    gpu: sshd           # gpu 这个标签 是 sshd









