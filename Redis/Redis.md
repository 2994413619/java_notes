# 一、常识

## 1、内存和硬盘对比

磁盘：

- 寻址：毫秒ms
- 硬盘带宽：G/M

内存：

- 寻址：纳秒ns
- 硬盘带宽：很大

秒>毫秒>微秒>纳秒

磁盘比内存在寻址上慢了10W倍

## 2、I/O buffer的成本问题

磁盘划分：从磁盘到磁道，到扇区，再到每个扇区512byte，划分成一个一个的区域后，索引变大。

格式化的时候，会有个对其选择，一般选4k，选择后，通过操作系统读数据时，无论你读多少数据，一次都是读取4K



**问题**：java读取文件，文件变大，速度变慢，为什么？

硬盘I/O成为瓶颈



## 3、mysql的存储

mysql里也是使用文件存储的，取数据的时候也是按data page（4K）取的。索引就是把“相近”的数据存一起，B+ Tree的树干是存在内存中的。索引目的就是减少IO次数。

**问题**：数据表很大的时候，性能下降？

如果表有索引的话

- 增删改变慢，因为要维护索引；
- 查询速度分情况
  - 1个或少量查询依然很快
  - 并发的的时候会受硬盘带宽影响速度



## 4、为何使用redis

**常识**：数据在内存和磁盘体积不一样

SAP HANA 是内存级别的关系型数据库，收费的。那么买不起内存级别的关系型数据库怎么办，这时候可以用缓存。（memcached、redis）

**memcached、redis的一点区别**：

- memcached的value没有类型的概念
- redis的value有String、hashes、Lists、Sets、sorted sets

**问题**：为什么redis要有数据类型，我直接使用json不就好了？

场景：client要取value中的某个值，如果用json，那么要把value一下全取出来返回client，并且再写代码自己解析。

使用redis的数据类型的好处：redis提供了对应数据结构的方法，我们不需要自己写代码解析，并且不需要把整个value返回给client，减少了网络IO。

用大数据里词汇来说：计算向数据移动



[数据库引擎排名、介绍](https://db-engines.com/en/)

[中文官网](http://www.redis.cn/)             

[官网](http://redis.io)



# 二、下载安装

可以使用wget来下载

```shell
yum install wget

wget https://download.redis.io/releases/redis-6.2.6.tar.gz

# 进入目录执行make,make会找本目录下的MakeFile文件，成功后src下会生成可执行文件
make

# 执行make后报错 缺少cc（c语言环境）
# g是单词“全局”的缩写
yum install gcc

# 清理之前make报错的后的垃圾文件, 然后再make
make distclean

# 启动
./redis-server

# 安装到指定目录 执行完后到该目录下，可以看到只有执行文件，就没有和源码混在一起
make install PREFIX=/opt/yuchao/redis6

#添加redis的环境变量
vi /etc/profile
# 添加一行
export REDIS_HOME=/opt/yuchao/redis6
export PATH=$PATH:$REDIS_HOME/bin

#更新配置
source /etc/profile

#查看path
echo $PATH

# 把它变成一个服务 utils下有个脚本，执行即可
cd utils
./install server.sh
# 执行完后看输出的信息，写了在/etc/init.d/下创建了redis_6379的脚本。并启动了服务
#查看服务状态
service redis_6379 status
```

下载下来解压后是c语言源码，需要安装，安装方式其实在README.MD中有。以上操作README.MD中都有

一个机器上可以跑多个redis，用port区分，并且执行utils/install server.sh是可以配置





epoll

```shell
#查看文件描述符
ps -ef | grep reids
cd /proc/进程id/fd
ll
```

BIO -> NIO（同步非阻塞） -> 多路复用NIO（减少用户态和内核态切换） -> AIO

**IO**:



<img src="img\IO.png" />



**零拷贝**：



<img src="img\zero_copy.png" />

