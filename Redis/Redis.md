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
./install_server.sh
# 执行完后看输出的信息，写了在/etc/init.d/下创建了redis_6379的脚本。并启动了服务
#查看服务状态
service redis_6379 status
```

下载下来解压后是c语言源码，需要安装，安装方式其实在README.MD中有。以上操作README.MD中都有

一个机器上可以跑多个redis，用port区分，并且执行utils/install server.sh是可以配置



# 三、原理

## 1、epoll

windows有，linux没有AIO，epoll也是NIO

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

## 2、redis原理

redis操作数据是单进程、单线程、单实例（他可能还有其他的线程）；那么并发，请求很多的时候，是如何变得很快的？

使用了epoll。



Nginx也使用了epoll

JVM：一个线程的成本：1MB（栈），可以调低

（1）线程多了调度成本CPU良妃

（2）内存消耗大

# 四、使用

- redis默认有16个库，从0-15
- redis的方法是和value的类型绑定的，当客户端调一个方法的时候，Redis会使用type命令查看value的类型，发现类型不一致，会直接返回错误。这也是Redis的一个优化点
- 使用的命令是哪个分组的，value的类型就是哪个
- key是一个object，包含
  - value的type
  - encoding
  - value的长度
- 命令object encoding k1结果：
  - int
  - embstr
  - raw
  - 类型改变
    - append后会变成raw
    - incr后会变成int
- 二进制安全（只有字节流，没有字符流；把内容变成字节存入redis中）
  - 执行incr时，先取出转换成int，再加一，然后把encoding改为int；下一次就可以直接加。
  - set k1 中（strlen k1  显示的是3；原因是xshell的编码设置的是UTF-8；改成GBK的话，长度就是2个字节）
- redis对cpu亲和性的支持

```shell
# 连接redis
redis-cli
# 如果linux上启了多个redis，可以通过端口号连接不同的
redis-cli -p 端口号
#直接连接redis的8号库
redis-cli -p 端口号 -n 8
#查看redis-cli具体参数
redis-cli -h

#连接redis后，也可以通过select 命令来切换库
select 8

#连接redis后，通过help命令来查学习
help

#输入 help 和字母，然后按tab键，redis会给你补全命令
help SE 

#查看命令分组@开头；查看generic命令
help @generic
help @string
help @hash

#查看object命令
object help

#object后面可以接一个子命令 如果k1为99，则返回int,
object encoding k1

#-----------------------------------------string------------------------------------#

#设置值 
#nx参数，表示key不存在的时候才能设置（分布式锁的时候用）
#xx参数，key存在的时候才可以设置
set key value [nx | xx]

#取值
get key

# 查询 匹配符合的key  keys pattern
keys *

# 清库 运维一般会把这个命令重命名
FLUSHDB
FLUSHALL

#批量设置
mset k1 a k2 b
#批量获取
mget k1 k2

#原子操作,有一个失败，全失败
msetnx k1 a k2 b

#追加
#appen k1 " world"
#截取string
GETRANGE k1 6 10
#正负索引
GETRANGE k1 6 -1
#重下标6开始覆盖
SETRANGE k1 6 'yuchao'
#获取长度
strlen k1

#set新值，get老值
getset k1 yyy

#查看value的方法
type k1

#数值类型加一
incr k1

#数值类型加一个数
incrby k1 20

#减一
decr k1

#减一个数值
decrby k1 20

#加小数
INCRBYFLOAT k1 0.5

#取出的k1长度，取决于xshell的编码；在UTF-8中“中”是3个字符，在GBK中是2个字符
set k1 中
setlen k1
#显示的是16进制（超过了ASCII码）
get k1
#在这种状态下，查看k1,就是“中”，不是16进制
redis-cli --raw
#-----------------------------------------string------------------------------------#
```



# 1、String(byte)

- 字符串
  - set
  - get
  - append
  - setrange
  - getrange
  - strlen
- 数值
  - incr（抢购，秒杀，详情页，点赞，评论；规避并发下，对数据库的事务操作完全由redis内存代替操作）
- bitmap
  - setbit key offset value（offset是二进制位偏移量，不是二进制数组）缺图 三——5 3:45（位图）
  - bitcount key bit [start] [end]
  - bitpos key bit [start] [end]（这里的start、end是字节的偏移量） 查询start到end中bit出现的第一个位置，具体看以下命令
  - bitop operation destkey key [key ...]

```shell
redis-cli --raw

#--------------------------------------------- setbit操作
# 0100 0000
127.0.0.1:6379> setbit k1 1 1
0
127.0.0.1:6379> get k1
@
# 0100 0001
127.0.0.1:6379> setbit k1 7 1
0
127.0.0.1:6379> get k1
A
127.0.0.1:6379> strlen k1
1

# 0100 0001 0100 0000
127.0.0.1:6379> setbit k1 9 1
0
127.0.0.1:6379> strlen k1
2
127.0.0.1:6379> get k1
A@


#linux查看ascii
man ascii


#--------------------------------------------- bitpos查询
127.0.0.1:6379> bitpos k1 1 0 0
1
127.0.0.1:6379> bitpos k1 1 1 1
9

#--------------------------------------------- BITCOUNT统计
127.0.0.1:6379> BITCOUNT k1 0 1
3
127.0.0.1:6379> BITCOUNT k1 0 0
2
127.0.0.1:6379> BITCOUNT k1 1 1
1


#--------------------------------------------- bitop位运算
# k1:0100 0010			A
# k2:0100 0100			B
# andkey:0100 0000		@
# orkey:0100 0110		C
127.0.0.1:6379> setbit k1 1 1
0
127.0.0.1:6379> setbit k1 7 1
0
127.0.0.1:6379> get k1
A
127.0.0.1:6379> setbit k2 1 1
0
127.0.0.1:6379> setbit k2 6 1
0
127.0.0.1:6379> get k2
B
127.0.0.1:6379> bitop and andkey k1 k2
1
127.0.0.1:6379> get andkey
@
127.0.0.1:6379> bitop or orkey k1 k2
1
127.0.0.1:6379> get orkey
C

```

**常识**：

字符集：ascii（开头以为一定是0  0xxxxxxx）

其他一般叫扩展字符集

扩展：其他字符集复用ascii的，不在ascii的重编码。

读出一个字节，是0开头可以直接转为ascii对应的字符；如果是三个1，表示还有读出两个字节，然后去掉开头的三个1，去找对应字符集的字符。



bitma使用场景：

（1）有用户系统，统计用户登录天数，且窗口随机（一位表示一天）

（2）登录送礼，用户有2亿，大库要备多少货（计算活跃用户，日期为key，用户id对应位；如果要计算3天内登录的，只要bitop or 最近三天的key，然后统计即可）



僵尸用户

冷热用户/忠诚用户





缺图 三——8 3:38 list结构

同向命令实现栈

反向命令实现队列

使用index操作，数组

阻塞，单薄队列（FIFO）

```shell
127.0.0.1:6379> lpush k1 a b c d e f
(integer) 6
127.0.0.1:6379> lpop k1
"f"
127.0.0.1:6379> lpop k1
"e"
127.0.0.1:6379> LRANGE k1 0 -1
1) "d"
2) "c"
3) "b"
4) "a"

#通过下标操作
127.0.0.1:6379> LINDEX k1 0
"d"
127.0.0.1:6379> LSET k1 0 dd
OK
127.0.0.1:6379> LINDEX k1 0
"dd"


# 从左删除两个a
127.0.0.1:6379> lpush k2 1 a 2 b 3 a 4 c 5 a 6 d
(integer) 12
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "a"
 8) "3"
 9) "b"
10) "2"
11) "a"
12) "1"
127.0.0.1:6379> LREM k2 2 a
(integer) 2
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "5"
 4) "c"
 5) "4"
 6) "3"
 7) "b"
 8) "2"
 9) "a"
10) "1"

# 在6的后面插入一个a
127.0.0.1:6379> LINSERT k2 after 6 a
(integer) 11
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "3"
 8) "b"
 9) "2"
10) "a"
11) "1"
# 在3的前面插入一个a
127.0.0.1:6379> LINSERT k2 before 3 a
(integer) 12
127.0.0.1:6379> LRANGE k2 0 -1
 1) "d"
 2) "6"
 3) "a"
 4) "5"
 5) "c"
 6) "4"
 7) "a"
 8) "3"
 9) "b"
10) "2"
11) "a"
12) "1"
#查询元素个数
127.0.0.1:6379> llen k2
(integer) 12

# 阻塞弹出 0-表示一致阻塞（阻塞时间）
blpop k2 0
```



list——25