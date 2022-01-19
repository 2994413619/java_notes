# 一、零散记录

1、管道会创建子进程

父进程可以让子进程看到数据



小例子：父子进程的数据互相看不到

```shell
[root@iZwz91n56f8y4m7ta0i7xoZ ~]# num=0
[root@iZwz91n56f8y4m7ta0i7xoZ ~]# echo $num
0
[root@iZwz91n56f8y4m7ta0i7xoZ /]# ((num++))
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $num
1
[root@iZwz91n56f8y4m7ta0i7xoZ /]# ((num++)) | echo ok
ok
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $num
1

```

查看pid

```shell
# 查看当前输入行的进程 $$的优先级高于 |
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $$
222211
#查看当前base的进程号
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $BASHPID
222211
#查看子进程的pid
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $BASHPID | more
222261
[root@iZwz91n56f8y4m7ta0i7xoZ /]# echo $BASHPID | more
222263
```



```shell
# 开启一个新的bash
/bin/bash
# 查看父子进程关系
pstree
# 退出
exit

# 父进程可以让子进程看到数据,但是子进程修改这个变量不会影响父进程的，这时候，父进程修改值不会影响到子进程
export num

# 后台执行脚本
./test.sh &
```

fork 创建子进程的时候，并不是所有变量都复制一边，只是复制引用。如果父进程被改变某个变量，会重新分配一个空间存储改变后的值，子进程依旧指向老的值（copy on write）