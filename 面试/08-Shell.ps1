bash -x                             #打开执行跟踪功能
set -x                              #放置脚本内，表示打开跟踪指令
set +x                              #放置脚本内，表示关闭跟踪指令



#预定义变量
$0                                  #表示将脚本的名称保存到内置变量$0内，不是脚本中进行的硬编码
$?                                  #得到上-个指令运行后的返回值
$#                                  #表示在执行脚本时，显示带有位置变量的个数
$!                                  #运行在后台的最后-个作业的 PID
$$                                  #Shell本身的PID
$_                                  #表示执行的命令的最后-个参数的值
$*                                  #表示所有位置参数的内容
"$*"                                #把所有参数看作-个字符串
$@                                  #和$*类似，表示所有位置参数的内容
"$@"                                #和"$*"类似

&& 符 和 || 符 的区别：
&& 判断前面运行的内容返回值是否为0，如果是0 表示继续运行下面指令，如果返回值为非0，表示不执行
|| 判断前面运行的内容是否为非0，如果为非0则运行-下指令，如果为0则不运行




#if 判断
if [ condition ]; then
     # body
if

#if 分支判断
if [ condition ]; then
     # body
else
     # body 
fi

#if 多分支判断
if [ condition ]; then
     # body
elif [ condition ]; then
     # body
elif [ condition ]; then
     # body
else
     # body
fi


#运算符：
运算符
如果...则为真
-f file                    #file为-般文件
-d directory               #判断指定目录是否存在
-e name                    #判断是否存在这个名称，不管是文件还是目录
-b file                    #file是块设备文件
-c file                    #file是字符串设备文件
-r file                    #file是可读的  
-w file                    #file是可写入的
-x file                    #file是可执行的，或file是可被查找的目录

-g file                    #file有设置它的setgid位
-h file                    #file是-符号连接
-L file                    #file是-符号连接（等同于-n）
-n string                  #string是非oull
-p file                    #file是-命名的管道（FIFO文件）
-S file                    #file是socket
-s file                    #file不是空的
-t n                       #文件描述符n指向-共端
-u file                    #file有设置它的setuid位
-z string                  #string为null

s1 = s2                    #字符串s1与s2相同
s1  = s2                   #字符串51与s2不相同
n1 -eq n2                  #整数n1等于n2
n1 -ne n2                  #整数n1不等于n2
n1 -lt n2                  #n1小于n2
n1 -gt n2                  #n1大于n2
n1 -le n2                  #n1小于或等于n2
n1 -ge n2                  #n1大于或等于n2



# for 循环

for((i=0;i<5;i++)); do
    echo "$i"
done

或者
for col in {1..5}
do
    echo "$col" 
    echo "$col" 
done

再或者
for((i=0;i<n;i++)); do
    for((j=0;j<m;j++)); do
        echo "$i, $j"
    done
done







#case 语句（一般用来多个脚本合并）
case "$1" in
    1)
        echo "case 1"
    ;;
    2|3)
        echo "case 2 or 3"
    ;;
    *)
        echo "default"
    ;;
esac


for((i=1;i<5;i++)); do
    case "${i}" in
        1)
            echo "case 1"
        ;;
        2)
            echo "case 2 or 3"
        ;;
        *)
            echo "default"
        ;;
    esac
done





while 与 until循环
# while 循环
while [ condition ]; do
    # body
done

i=0
while ((i < 9))                                #注意算数运算要用左右双括号
do 
echo $i
((i++))
done

# until
until [ condition ]; do
    # body
done

#!/bin/bash
i=0

until [[ "$i" -gt 5 ]]    #大于5
do
    let "square=i*i"
    echo "$i * $i = $square"
    let "i++"
done


总结：whie循环在条件为真时继续执行循环而until则在条件为假时执行循环



函数

function han(){
    #指令
    n=$((12+1))
    echo $n
}
han
han






