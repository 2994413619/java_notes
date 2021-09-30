优化有两种：RBO（基于规则的优化）

​                       CBO（基于成本的优化）

Mysql 8.0之前，server中有缓存，为了减少IO。但关系数据库内容修改频繁，所以8.0去除了这个功能。

#  一、性能监控

## 1、show profile

[官网文档](https://dev.mysql.com/doc/refman/8.0/en/show-profile.html)

使用show profile查看sql执行时间。

**注意**：该方式会在新版本中被弃用和替代。

<img src="img\1617172216922.png"/>

**使用方法：**

1. 设置属性

   ```sql
   set profiling=1;
   ```

2. 执行sql

3. 查看profile

   ```sql
   -- 显示sql及执行总时长
   show profiles; 
   -- 显示sql每个步骤所用时长
   show profile;  
   ```

   如下：

   ```sql
   mysql> set profiling = 1;
   Query OK, 0 rows affected, 1 warning (0.00 sec)
   
   mysql> select * from store;
   +----------+------------------+------------+---------------------+
   | store_id | manager_staff_id | address_id | last_update         |
   +----------+------------------+------------+---------------------+
   |        1 |                1 |          1 | 2006-02-15 04:57:12 |
   |        2 |                2 |          2 | 2006-02-15 04:57:12 |
   +----------+------------------+------------+---------------------+
   2 rows in set (0.00 sec)
   
   mysql> show profiles;
   +----------+------------+---------------------+
   | Query_ID | Duration   | Query               |
   +----------+------------+---------------------+
   |        1 | 0.00030825 | select * from store |
   +----------+------------+---------------------+
   1 row in set, 1 warning (0.00 sec)
   
   mysql> show profile;
   +--------------------------------+----------+
   | Status                         | Duration |
   +--------------------------------+----------+
   | starting                       | 0.000039 |
   | Executing hook on transaction  | 0.000003 |
   | starting                       | 0.000005 |
   | checking permissions           | 0.000004 |
   | Opening tables                 | 0.000121 |
   | init                           | 0.000004 |
   | System lock                    | 0.000006 |
   | optimizing                     | 0.000003 |
   | statistics                     | 0.000008 |
   | preparing                      | 0.000012 |
   | executing                      | 0.000035 |
   | end                            | 0.000003 |
   | query end                      | 0.000002 |
   | waiting for handler commit     | 0.000005 |
   | closing tables                 | 0.000004 |
   | freeing items                  | 0.000044 |
   | cleaning up                    | 0.000015 |
   +--------------------------------+----------+
   17 rows in set, 1 warning (0.00 sec)
   ```
   
   查的是query_Id为2的sql的:
   
   ```sql
   mysql> show profiles;
   +----------+------------+---------------------+
   | Query_ID | Duration   | Query               |
   +----------+------------+---------------------+
   |        1 | 0.00030825 | select * from store |
   |        2 | 0.00203925 | select * from staff |
   +----------+------------+---------------------+
   2 rows in set, 1 warning (0.00 sec)
   
   mysql> show profile for query 2;
   +--------------------------------+----------+
   | Status                         | Duration |
   +--------------------------------+----------+
   | starting                       | 0.000064 |
   | Executing hook on transaction  | 0.000004 |
   | starting                       | 0.000005 |
   | checking permissions           | 0.000004 |
   | Opening tables                 | 0.000698 |
   | init                           | 0.000004 |
   | System lock                    | 0.000004 |
   | optimizing                     | 0.000002 |
   | statistics                     | 0.000008 |
   | preparing                      | 0.000011 |
   | executing                      | 0.001179 |
   | end                            | 0.000005 |
   | query end                      | 0.000002 |
   | waiting for handler commit     | 0.000006 |
   | closing tables                 | 0.000007 |
   | freeing items                  | 0.000026 |
   | cleaning up                    | 0.000012 |
   +--------------------------------+----------+
   17 rows in set, 1 warning (0.00 sec)
   ```

查询其他信息，可以制定type，如官网所示:

```sql
SHOW PROFILE [type [, type] ... ]
    [FOR QUERY n]
    [LIMIT row_count [OFFSET offset]]

type: {
    ALL
  | BLOCK IO
  | CONTEXT SWITCHES
  | CPU
  | IPC
  | MEMORY
  | PAGE FAULTS
  | SOURCE
  | SWAPS
}
```

all：显示所有性能信息

block io：显示块io操作次数

coentext switches：显示上下文切换次数，被动和主动（

cpu：显示用户cpu时间、系统cpu时间（）

IPC：显示发送和接受的消息数量（）

Menory：暂未实现

page faults：显示页错误数量（）

source：显示源码中的函数名称与位置（）

swaps：显示swap的次数（）

使用：show  profile [block io | all | coentext switches |...] for query n

## 2、performance schema

[官方文档](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html)

[MYSQL performance schema详解](https://blog.csdn.net/qq_40638598/article/details/117877983)

默认情况，该模式是开启的，查看方式：

```sql
mysql> show variables like 'performance_schema';
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| performance_schema | ON    |
+--------------------+-------+
1 row in set, 1 warning (0.03 sec)
```

手动关闭，提示该变量为一个只读变量：

```sql
mysql> set performance_schema=off;
ERROR 1238 (HY000): Variable 'performance_schema' is a read only variable
```

这时候需要修改mysql的一个配置文件my.cnf，才可以修改这个属性。

详细介绍：

## 3、show processlist

[官网文档](https://dev.mysql.com/doc/refman/8.0/en/show-processlist.html)

查看连接数量：

```sql
mysql> show processlist;
+----+-----------------+-----------------+--------+---------+--------+------------------------+------------------+
| Id | User            | Host            | db     | Command | Time   | State                  | Info             |
+----+-----------------+-----------------+--------+---------+--------+------------------------+------------------+
|  5 | event_scheduler | localhost       | NULL   | Daemon  | 170180 | Waiting on empty queue | NULL             |
|  8 | root            | localhost:60421 | NULL   | Query   |      0 | starting               | show processlist |
|  9 | root            | localhost:61885 | mytest | Sleep   |      3 |                        | NULL             |
+----+-----------------+-----------------+--------+---------+--------+------------------------+------------------+
3 rows in set (0.00 sec)
```

**属性介绍：**

id表示session id

user表示操作的用户

host表示操作的主机

db表示操作的数据库

command表示当前状态

- ​	sleep：线程正在等待客户端发送新的请求

- ​	query：线程正在执行查询或正在将结果发送给客户端

- ​	locked：在mysql的服务层，该线程正在等待表锁

- ​	analyzing and statistics：线程正在收集存储引擎的统计信息，并生成查询的执行计划

- ​	Copying to tmp table：线程正在执行查询，并且将其结果集都复制到一个临时表中

- ​	sorting result：线程正在对结果集进行排序

- ​	sending data：线程可能在多个状态之间传送数据，或者在生成结果集或者向客户端返回数据


info表示详细的sql语句

time表示相应命令执行时间

state表示命令执行状态

目前性能最好的连接池，阿里的Druid：[官方文档](https://github.com/alibaba/druid)



# 二、schema与数据类型优化

## 1、后缀名含义

.frm是表结构文件

.ibd表示表结构为InnoDB的数据和索引文件文件

.myd表示表结构为MyISAM的数据文件

.myi表示数据结构为MyISAM的索引文件

## 2、数据类型优化

### （1）规则

**1）使用最小数据类型**：占用更少的磁盘、内存和CPU缓存，并且处理时需要的CPU周期更少

​	案例：设计两张表，设计不同的数据类型，查看表的容量（读取都是以4k为单位）

**2）简单就好**：简单数据类型的操作通常需要更少的CPU周期

​	例如:

​		a、整型比字符操作代价更低，因为字符集和校对规则是字符比较比整型比较更复杂，

​		b、使用mysql自建类型而不是字符串来存储日期和时间

​		c、用整型存储IP地址

​	案例：创建两张相同的表，改变日期的数据类型，查看SQL语句执行的速度

**3）尽量避免null**：列中包含null，查询难优化，因为可为null的列使得索引、索引统计和值比较都更加复杂

### **（2）具体类型**

#### **1）整型**

定义的长度无关，底层定了他的长度；TINYINT，SMALLINT，MEDIUMINT，INT，BIGINT分别使用8，16，24，32，64位存储空间。

#### **2）字符和字符串类型**

- **varchar**

    - varchar(n)，n<=255时使用额外一个字节保存长度，n>255使用额外两个字节保存长度。

    - varchar(5)与varchar(255)保存同样的内容，硬盘存储空间相同，但内存空间占用不同，是指定的大小 。

    - varchar在mysql5.6之前变更长度，或者从255一下变更到255以上时时，都会导致锁表。

    - 应用场景：

  ​	a、存储长度波动较大的数据，如：文章，有的会很短有的会很长

  ​	b、字符串很少更新的场景，每次更新后都会重算并使用额外存储空间保存长度

  ​	c、适合保存多字节字符，如：汉字，特殊字符等

- **char**

    - 最大长度：255

    - 会自动删除末尾的空格

    - 检索效率、写效率 会比varchar高，以空间换时间

    - 应用场景：

  ​	a、存储长度波动不大的数据，如：md5摘要

  ​	b、存储短字符串、经常更新的字符串

#### **3）BLOB和TEXT类型**

MySQL 把每个 BLOB 和 TEXT 值当作一个独立的对象处理。两者都是为了存储很大数据而设计的字符串类型，分别采用二进制和字符方式存储。基本不会使用该方式，而是使用ftp服务器代替。

#### **4）datetime和timestamp**

- **datetime**

    - 占用8个字节

    - 与时区无关，数据库底层时区配置，对datetime无效

    - 可保存到毫秒

    - 可保存时间范围大

    - 不要使用字符串存储日期类型，占用空间大，损失日期类型函数的便捷性

- **timestamp**

    - 占用4个字节

    - 时间范围：1970-01-01到2038-01-19

    - 精确到秒

    - 采用整形存储

    - 依赖数据库设置的时区

    - 自动更新timestamp列的值

- **date**

    - 占用的字节数比使用字符串、datetime、int存储要少，使用date类型只需要3个字节
    - 使用date类型还可以利用日期时间函数进行日期之间的计算
    - date类型用于保存1000-01-01到9999-12-31之间的日期

#### **5）使用枚举代替字符串类型**

查询和显示的时候是字符串，其实存储的是数字，节约空间，也可以按顺序排序查询

#### **6）IP地址存储**

ip地址和整型之间转换，最大转化为255.255.255.255

```sql
mysql> select INET_ATON('192.168.88.123');
+-----------------------------+
| INET_ATON('192.168.88.123') |
+-----------------------------+
|                  3232258171 |
+-----------------------------+
1 row in set (0.00 sec)

mysql> select INET_NTOA('3232258171');
+-------------------------+
| INET_NTOA('3232258171') |
+-------------------------+
| 192.168.88.123          |
+-------------------------+
1 row in set (0.00 sec)
```

### 3、合理使用范式和反范式

三范式最终目的是为了解决数据冗余

第一范式：列不允许再分

第二范式：属性必须完全依赖主键

第三范式：属性不允许出现传递依赖

使用了limit后order by失效

范式和反范式各有优缺点，实际项目中都是一起使用的



### 4、其他注意点

#### （1）代理主键

主键使用和业务无关的数字序列，优点：

- 不和业务耦合，方便维护。
- 一个大多数表，最好是全部表，通用的键策略能够减少需要编写的源码数量，减少系统的总体拥有成本。

#### （2）字符集选择

纯拉丁字符能表示的内容，没必要选择 latin1 之外的其他字符编码，因为这会节省大量的存储空间。

mysql中utf8只能存两个字节的字符，utf8mb4才能存3个

在linux中使用 man utf8可以查看编码介绍

#### （3）存储引擎的选择

|              | MyISAM     | InnoDB                     |
| ------------ | ---------- | -------------------------- |
| 索引类型     | 非聚簇索引 | 聚簇索引                   |
| 支持事务     | 否         | 是                         |
| 支持表锁     | 是         | 是                         |
| 支持行锁     | 否         | 是                         |
| 支持外键     | 否         | 是                         |
| 支持全文索引 | 是         | 是（5.6后支持）            |
| 适合操作类型 | 大量select | 大量insert、delete、update |



- 建表时不设置存储引擎的话，默认的是INNODB，默认值在my.ini文件中，可修改

- default-storage-engine=INNODB

- INNODB加锁是默认加在索引上的，where条件后的列如果加了索引，则加的是行锁，否则为表锁
- 存储引擎代表的是数据文件的组织形式



聚簇索引：数据文件和索引文件放在一起

非聚簇索引：数据文件和索引文件不放在一起

#### （4）适当的数据冗余

- 被频繁引用且只能通过 Join 2张(或者更多)大表的方式才能得到的独立小字段。
- 这样的场景由于每次Join仅仅只是为了取得某个小字段的值，Join到的记录又大，会造成大量不必要的 IO，完全可以通过空间换取时间的方式来优化。不过，冗余的同时需要确保数据的一致性不会遭到破坏，确保更新的同时冗余字段也被更新。

oracle中有物化视图，有两种方式，一种基表更改，视图更新；另一种，查询的时候才从基表更新。

#### （5）适当拆分

当我们的表中存在类似于 TEXT 或者是很大的 VARCHAR类型的大字段的时候，如果我们大部分访问这张表的时候都不需要这个字段，我们就该义无反顾的将其拆分到另外的独立表中，以减少常用数据所占用的存储空间。这样做的一个明显好处就是每个数据块中可以存储的数据条数可以大大增加，既减少物理 IO 次数，也能大大提高内存中的缓存命中率。

# 三、执行计划

[mysql执行计划](https://blog.csdn.net/qq_40638598/article/details/120051371)



# 四、索引优化

## 1、索引零散知识

### （1）不使用其他数据结构做索引的原因

**hash表**：

- 使用hash表的话，要加载所有的数据文件，比较耗内存空间
- 等值查找快，但是不能进行范围查找
- 哈希索引只包含哈希值和行指针，而不存储字段值，索引不能使用索引中的值来避免读取行
- 哈希索引数据并不是按照索引值顺序存储的，所以无法进行排序
- 哈希索引不支持部分列匹配查找，哈希索引是使用索引列的全部内容来计算哈希值
- 访问哈希索引的数据非常快，除非有很多哈希冲突，当出现哈希冲突的时候，存储引擎必须遍历链表中的所有行指针，逐行进行比较，直到找到所有符合条件的行
- 哈希冲突比较多的话，维护的代价也会很高

memory存储引擎就是使用hash表作为索引文件的。

**二插查找树**：可能造成树过于深，导致查找IO过于庞大。

**AVL树**：由于要保证平衡最短子树和最长子树不能超过1，每次超出标准是要进行左旋、右旋，而导致插入效率低，而且也可能树比较深。

**红黑树**：最长子树不超过最短子树的两倍即可。牺牲了插入效率，来提高查询效率。

**B-Tree**：B-Tree非叶子结点有数据，导致IO的时候需要读入太多数据到内存。

**B* Tree**：B*Tree是非也只节点也有指针，对索引来说没必要

### （2）InnoDB和MyISAM索引结构区别

两者都是使用B+树作为索引结构。

InnoDB：数据和索引在同一个文件，所以索引B+Tree叶子节点存放了数据。

MyISAM：数据和索引不在一个文件，所以索引B+Tree叶子节点存放的是数据文件的数据地址。

### （3）创建表一定要建立主键

InnoDB是通过B+Tree结构对主键创建索引，然后叶子节点中存储记录，如果没有主键，那么会选择唯一键，如果没有唯一键，那么会生成一个6位的row_id来作为主键，该主键在mysql中不可见，在oracle中可见。

### （4）回表

非主键索引的叶子节点存的是主键。那么查询条件为非主键索引的时候，查询费主键索引树后，得到主键，然后还需要通过主键查询主键索引树，从而来查找到内容，这个过程叫回表。

### （5）索引覆盖

- 如果一个索引包含所有需要查询的字段的值，我们称之为覆盖索引
- explain 中的Extra列为Using index表示索引覆盖，没有表示不是索引覆盖
- memory不支持覆盖索引
- 一些存储引擎如MYISAM在内存中只缓存索引，数据则依赖于操作系统来缓存，因此要访问数据需要一次系统调用，这可能会导致严重的性能问题
- 由于INNODB的聚簇索引，覆盖索引对INNODB表特别有用

### （6）索引下推

​	组合索引中有（name,age）

​	sql语句有where name=‘’ and age=‘ ’；

​	老版本先把name匹配出来，把age全部取出来，但是后来在匹配name的时候就把age过滤了（5.7在存储引擎中就已经做了匹配了，而没有优化前的是在service中做的匹配）。

### （7）索引优点

- 大大减少了服务器需要扫描的数据量
- 帮助服务器避免排序和临时表
- 将随机io变成顺序io

### （8）索引用处

- 快速查找匹配WHERE子句的行
- 从consideration中消除行,如果可以在多个索引之间进行选择，mysql通常会使用找到最少行的索引
- 如果表具有多列索引，则优化器可以使用索引的任何最左前缀来查找行
- 当有表连接的时候，从其他表检索行数据
- 查找特定索引列的min或max值
- 如果排序或分组时在可用索引的最左前缀上完成的，则对表进行排序和分组
- 在某些情况下，可以优化查询以检索值而无需查询数据行

### （9）索引分类

- 主键索引
- 唯一索引
- 普通索引
- 全文索引
- 组合索引

### （10）索引匹配的方式

全值匹配：指的是和索引中的所有列进行匹配

```sql
explain select * from staffs where name = 'July' and age = '23' and pos = 'dev';
```

匹配最左前缀：只匹配前面的几列

```sql
explain select * from staffs where name = 'July' and age = '23';
explain select * from staffs where name = 'July';
```

匹配列前缀：可以匹配某一列的值的开头部分

```sql
explain select * from staffs where name like 'J%';
explain select * from staffs where name like '%y';
```

匹配范围值：可以查找某一个范围的数据

```sql
explain select * from staffs where name > 'Mary';
```

精确匹配某一列并范围匹配另外一列：可以查询第一列的全部和第二列的部分

```sql
explain select * from staffs where name = 'July' and age > 25;
```

只访问索引的查询：查询的时候只需要访问索引，不需要访问数据行，本质上就是覆盖索引

```sql
explain select name,age,pos from staffs where name = 'July' and age = 25 and pos = 'dev';
```

## 2、组合索引

当包含多个列作为索引，需要注意的是正确的顺序依赖于该索引的查询，同时需要考虑如何更好的满足排序和分组的需要

案例，建立组合索引a,b,c，不同SQL语句使用索引情况：

| 语句                                    | 索引是否发挥作用 |
| --------------------------------------- | ---------------- |
| where a = 3                             | 是，只使用了a    |
| where a = 3 and b = 5                   | 是，使用了a,b    |
| where a = 3 and b = 5 and c = 4         | 是，使用了a,b,c  |
| where b = 3 or where c = 4              | 否               |
| where a = 3 and c = 4                   | 是，仅使用了a    |
| where a = 3 and b > 10 and c = 7        | 是，使用了a,b    |
| where a = 3 and b like '%xx%' and c = 7 | 使用了a,b        |

## 3、优化小细节

- 当使用索引列进行查询的时候尽量不要使用表达式，把计算放到业务层而不是数据库层

```sql
select actor_id from actor where actor_id=4;
select actor_id from actor where actor_id+1=5;
```

- 尽量使用主键查询，而不是其他索引，因此主键查询不会触发回表查询

- 使用前缀索引

 ​	[前缀索引实例说明](https://blog.csdn.net/qq_40638598/article/details/120147647)

- 使用索引扫描来排序

- union all,in,or都能够使用索引，但是推荐使用in

```sql
explain select * from actor where actor_id = 1 union all select * from actor where actor_id = 2;
explain select * from actor where actor_id in (1,2);
explain select * from actor where actor_id = 1 or actor_id =2;
```

- 范围列可以用到索引

    - 范围条件是：<、<=、>、>=、between

    - 范围列可以用到索引，但是范围列后面的列无法用到索引，索引最多用于一个范围列
- 强制类型转换会全表扫描

```sql
explain select * from user where phone=13800001234;#不会触发索引
explain select * from user where phone='13800001234';#触发索引
```

- 更新十分频繁，数据区分度不高的字段上不宜建立索引

    - 更新会变更B+树，更新频繁的字段建议索引会大大降低数据库性能

    - 类似于性别这类区分不大的属性，建立索引是没有意义的，不能有效的过滤数据，、

    - 一般区分度在80%以上的时候就可以建立索引，区分度可以使用 count(distinct(列名))/count(*) 来计算

- 创建索引的列，不允许为null，可能会得到不符合预期的结果
- 当需要进行表连接的时候，最好不要超过三张表，因为需要join的字段，数据类型必须一致
- 能使用limit的时候尽量使用limit
- 单表索引建议控制在5个以内
- 单索引字段数不允许超过5个（组合索引）

## 4、索引监控

查看参数：

```sql
show status like 'Handler_read%';
```

参数解释：

Handler_read_first：读取索引第一个条目的次数

Handler_read_key：通过index获取数据的次数

Handler_read_last：读取索引最后一个条目的次数

Handler_read_next：通过索引读取下一条数据的次数

Handler_read_prev：通过索引读取上一条数据的次数

Handler_read_rnd：从固定位置读取数据的次数

Handler_read_rnd_next：从数据节点读取下一条数据的次数

## 5、[索引优化分析案例](https://blog.csdn.net/qq_40638598/article/details/120147363)

# 五、查询优化

## 1、查询慢的原因

- 网络
- CPU
- IO
- 上下文切换
- 系统调用
- 生成统计信息
- 锁等待时间

## 2、优化数据访问

（1）查询性能低下的主要原因是访问的数据太多，某些查询不可避免的需要筛选大量的数据，我们可以通过减少访问数据量的方式进行优化

- 确认应用程序是否在检索大量超过需要的数据
- 确认mysql服务器层是否在分析大量超过需要的数据行

（2）是否向数据库请求了不需要的数据

- 查询不需要的记录

> 我们常常会误以为mysql会只返回需要的数据，实际上mysql却是先返回全部结果再进行计算，在日常的开发习惯中，经常是先用select语句查询大量的结果，然后获取前面的N行后关闭结果集。
>
> 优化方式是在查询后面添加limit

- 多表关联时返回全部列

```sql
select * from actor inner join film_actor using(actor_id) inner join film using(film_id) where film.title='Academy Dinosaur';

select actor.* from actor...;
```

- 总是取出全部列

> 在公司的企业需求中，禁止使用select *,虽然这种方式能够简化开发，但是会影响查询的性能，所以尽量不要使用

- 重复查询相同的数据

> 如果需要不断的重复执行相同的查询，且每次返回完全相同的数据，因此，基于这样的应用场景，我们可以将这部分数据缓存起来，这样的话能够提高查询效率

## 3、执行过程的优化

### （1）查询缓存

> 在解析一个查询语句之前，如果查询缓存是打开的，那么mysql会优先检查这个查询是否命中查询缓存中的数据，如果查询恰好命中了查询缓存，那么会在返回结果之前会检查用户权限，如果权限没有问题，那么mysql会跳过所有的阶段，就直接从缓存中拿到结果并返回给客户端

### （2）查询优化处理

#### 1）语法解析器和预处理

> mysql通过关键字将SQL语句进行解析，并生成一颗解析树，mysql解析器将使用mysql语法规则验证和解析查询，例如验证使用使用了错误的关键字或者顺序是否正确等等，预处理器会进一步检查解析树是否合法，例如表名和列名是否存在，是否有歧义，还会验证权限等等

#### 2）查询优化器

> 当语法树没有问题之后，相应的要由优化器将其转成执行计划，一条查询语句可以使用非常多的执行方式，最后都可以得到对应的结果，但是不同的执行方式带来的效率是不同的，优化器的最主要目的就是要选择最有效的执行计划
>
> 
>
> mysql使用的是基于成本的优化器，在优化的时候会尝试预测一个查询使用某种查询计划时候的成本，并选择其中成本最小的一个

##### 1.一个案例

```sql
select count(*) from film_actor;
show status like 'last_query_cost';
```

可以看到这条查询语句大概需要做1104个数据页才能找到对应的数据，这是经过一系列的统计信息计算来的

- 每个表或者索引的页面个数
- 每个表或者索引的页面个数
- 索引和数据行的长度
- 索引的分布情况

##### 2.mysql在有些情况下会选择错误的执行计划

原因：

- 统计信息不准确

> InnoDB因为其mvcc的架构，并不能维护一个数据表的行数的精确统计信息

- 执行计划的成本估算不等同于实际执行的成本

> 有时候某个执行计划虽然需要读取更多的页面，但是他的成本却更小，因为如果这些页面都是顺序读或者这些页面都已经在内存中的话，那么它的访问成本将很小，mysql层面并不知道哪些页面在内存中，哪些在磁盘，所以查询之际执行过程中到底需要多少次IO是无法得知的

- mysql的最优可能跟你想的不一样

> mysql的优化是基于成本模型的优化，但是有可能不是最快的优化

- mysql不考虑其他并发执行的查询
- mysql不会考虑不受其控制的操作成本

> 执行存储过程或者用户自定义函数的成本

##### 3.优化器的优化策略

- 静态优化：直接对解析树进行分析，并完成优化
- 动态优化：动态优化与查询的上下文有关，也可能跟取值、索引对应的行数有关
- mysql对查询的静态优化只需要一次，但对动态优化在每次执行时都需要重新评估

##### 4.优化器的优化类型

- 重新定义关联表的顺序

> 数据表的关联并不总是按照在查询中指定的顺序进行，决定关联顺序时优化器很重要的功能

- 将外连接转化成内连接，内连接的效率要高于外连接
- 使用等价变换规则，mysql可以使用一些等价变化来简化并规划表达式
- 优化count(),min(),max()

> 索引和列是否可以为空通常可以帮助mysql优化这类表达式：例如，要找到某一列的最小值，只需要查询索引的最左端的记录即可，不需要全文扫描比较

- 预估并转化为常数表达式，当mysql检测到一个表达式可以转化为常数的时候，就会一直把该表达式作为常数进行处理

```sql
explain select film.film_id,film_actor.actor_id from film inner join film_actor using(film_id) where film.film_id = 1
```

- 索引覆盖扫描，当索引中的列包含所有查询中需要使用的列的时候，可以使用覆盖索引
- 子查询优化

> mysql在某些情况下可以将子查询转换一种效率更高的形式，从而减少多个查询多次对数据进行访问，例如将经常查询的数据放入到缓存中

- 等值传播

如果两个列的值通过等式关联，那么mysql能够把其中一个列的where条件传递到另一个上：

```sql
explain 
select film.film_id 
from film 
inner join film_actor 
using(film_id) 
where film.film_id > 500;
```

这里使用film_id字段进行等值关联，film_id这个列不仅适用于film表而且适用于film_actor表

```sql
explain 
select film.film_id 
from film 
inner join film_actor 
using(film_id) 
where film.film_id > 500 
and film_actor.film_id > 500;

3
```



##### 5.关联查询

**1.join的实现方式原理：**

**A**、Simple Nested-Loop Join：

<img src="img\join1.png"/>

**B**、Index Nested-Loop Join：

<img src="img\join2.png" />

**C**、Block Nested-Loop Join：

<img src="img\join3.png" />

- Join Buffer会缓存所有参与查询的列而不是只有Join的列。
- 可以通过调整join_buffer_size缓存大小
- join_buffer_size的默认值是256K，join_buffer_size的最大值在MySQL 5.1.22版本前是4G-1，而之后的版本才能在64位操作系统下申请大于4G的Join Buffer空间。
- 使用Block Nested-Loop Join算法需要开启优化器管理配置的optimizer_switch的设置block_nested_loop为on，默认为开启。

```sql
show variables like '%optimizer_switch%'
```

**2.案例演示：**

查看不同的顺序执行方式对查询性能的影响：

```sql
explain 
select film.film_id,film.title,film.release_year,actor.actor_id,actor.first_name,actor.last_name 
from film 
inner join film_actor 
using(film_id) 
inner join actor 
using(actor_id);
```

查看执行的成本：

```sql
show status like 'last_query_cost'; 
```

按照自己预想的规定顺序执行：

```sql
explain 
select straight_join film.film_id,film.title,film.release_year,actor.actor_id,actor.first_name,actor.last_name 
from film 
inner join film_actor 
using(film_id) 
inner join actor 
using(actor_id);
```

查看执行的成本：

```sql
show status like 'last_query_cost'; 
```

##### 6.排序优化

> 无论如何排序都是一个成本很高的操作，所以从性能的角度出发，应该尽可能避免排序或者尽可能避免对大量数据进行排序。
>
> 推荐使用利用索引进行排序，但是当不能使用索引的时候，mysql就需要自己进行排序，如果数据量小则再内存中进行，如果数据量大就需要使用磁盘，mysql中称之为filesort。
>
> 如果需要排序的数据量小于排序缓冲区(show variables like '%sort_buffer_size%';),mysql使用内存进行快速排序操作，如果内存不够排序，那么mysql就会先将树分块，对每个独立的块使用快速排序进行排序，并将各个块的排序结果存放再磁盘上，然后将各个排好序的块进行合并，最后返回排序结果

排序的算法:

- 两次传输排序

> 第一次数据读取是将需要排序的字段读取出来，然后进行排序，第二次是将排好序的结果按照需要去读取数据行。
>
> 这种方式效率比较低，原因是第二次读取数据的时候因为已经排好序，需要去读取所有记录而此时更多的是随机IO，读取数据成本会比较高
>
> 两次传输的优势，在排序的时候存储尽可能少的数据，让排序缓冲区可以尽可能多的容纳行数来进行排序操作

- 单次传输排序

> 先读取查询所需要的所有列，然后再根据给定列进行排序，最后直接返回排序结果，此方式只需要一次顺序IO读取所有的数据，而无须任何的随机IO，问题在于查询的列特别多的时候，会占用大量的存储空间，无法存储大量的数据

- 当需要排序的列的总大小超过max_length_for_sort_data定义的字节，mysql会选择双次排序，反之使用单次排序，当然，用户可以设置此参数的值来选择排序的方式

## 4、优化特定类型的查询

### （1）优化count()查询

> count()是特殊的函数，有两种不同的作用，一种是某个列值的数量，也可以统计行数

- 总有人认为myisam的count函数比较快，这是有前提条件的，只有没有任何where条件的count(*)才是比较快的

- 使用近似值

> 在某些应用场景中，不需要完全精确的值，可以参考使用近似值来代替，比如可以使用explain来获取近似的值
>
> 其实在很多OLAP的应用中，需要计算某一个列值的基数，有一个计算近似值的算法叫hyperloglog。

- 更复杂的优化

> 一般情况下，count()需要扫描大量的行才能获取精确的数据，其实很难优化，在实际操作的时候可以考虑使用索引覆盖扫描，或者增加汇总表，或者增加外部缓存系统。

### （2）优化关联查询

- 确保on或者using子句中的列上有索引，在创建索引的时候就要考虑到关联的顺序

> 当表A和表B使用列C关联的时候，如果优化器的关联顺序是B、A，那么就不需要再B表的对应列上建上索引，没有用到的索引只会带来额外的负担，一般情况下来说，只需要在关联顺序中的第二个表的相应列上创建索引

- 确保任何的groupby和order by中的表达式只涉及到一个表中的列，这样mysql才有可能使用索引来优化这个过程

> 确保任何的groupby和order by中的表达式只涉及到一个表中的列，这样mysql才有可能使用索引来优化这个过程

### （3）优化子查询

>  子查询的优化最重要的优化建议是尽可能使用关联查询代替

### （4）优化limit分页

> 在很多应用场景中我们需要将数据进行分页，一般会使用limit加上偏移量的方法实现，同时加上合适的orderby 的子句，如果这种方式有索引的帮助，效率通常不错，否则的化需要进行大量的文件排序操作，还有一种情况，当偏移量非常大的时候，前面的大部分数据都会被抛弃，这样的代价太高。
>
> 要优化这种查询的话，要么是在页面中限制分页的数量，要么优化大偏移量的性能

优化此类查询的最简单的办法就是尽可能地使用覆盖索引，而不是查询所有的列。

查看执行计划查看扫描的行数：

```sql
select film_id,description 
from film 
order by title 
limit 50,5

explain 
select film.film_id,film.description 
from film 
inner join 
(select film_id 
 from film 
 order by title 
 limit 50,5) as lim 
 using(film_id);
```

### （5）优化union查询

> mysql总是通过创建并填充临时表的方式来执行union查询，因此很多优化策略在union查询中都没法很好的使用。经常需要手工的将where、limit、order by等子句下推到各个子查询中，以便优化器可以充分利用这些条件进行优化

除非确实需要服务器消除重复的行，否则一定要使用union all，因此没有all关键字，mysql会在查询的时候给临时表加上distinct的关键字，这个操作的代价很高。

### （6）推荐使用用户自定义变量

> 用户自定义变量是一个容易被遗忘的mysql特性，但是如果能够用好，在某些场景下可以写出非常高效的查询语句，在查询中混合使用过程化和关系话逻辑的时候，自定义变量会非常有用。
>
> 用户自定义变量是一个用来存储内容的临时容器，在连接mysql的整个过程中都存在。

#### 1）自定义变量的使用

```sql
set @one :=1
set @min_actor :=(select min(actor_id) from actor)
set @last_week :=current_date-interval 1 week;
```

#### 2）自定义变量的限制

- 无法使用查询缓存
- 不能在使用常量或者标识符的地方使用自定义变量，例如表名、列名或者limit子句
- 用户自定义变量的生命周期是在一个连接中有效，所以不能用它们来做连接间的通信
- 不能显式地声明自定义变量地类型
- mysql优化器在某些场景下可能会将这些变量优化掉，这可能导致代码不按预想地方式运行
- 赋值符号：=的优先级非常低，所以在使用赋值表达式的时候应该明确的使用括号
- 使用未定义变量不会产生任何语法错误

#### 3）自定义变量的使用案例

##### 1.优化排名语句

在给一个变量赋值的同时使用这个变量：

```sql
select actor_id,@rownum:=@rownum+1 as rownum 
from actor 
limit 10;
```

查询获取演过最多电影的前10名演员，然后根据出演电影次数做一个排名：

```sql
select actor_id,count(*) as cnt 
from film_actor 
group by actor_id 
order by cnt desc 
limit 10;
```

##### 2.避免重新查询刚刚更新的数据

当需要高效的更新一条记录的时间戳，同时希望查询当前记录中存放的时间戳是什么

```sql
update t1 
set lastUpdated=now() 
where id =1;
select lastUpdated from t1 where id =1;
```

```sql
update t1 
set lastupdated = now() 
where id = 1 
and @now:=now();
select @now;
```

##### 3.确定取值的顺序

在赋值和读取变量的时候可能是在查询的不同阶段

```sql
set @rownum:=0;
select actor_id,@rownum:=@rownum+1 as cnt 
from actor 
where @rownum<=1;
# 因为where和select在查询的不同阶段执行，所以看到查询到两条记录，这不符合预期
```

```sql
set @rownum:=0;
select actor_id,@rownum:=@rownum+1 as cnt 
from actor 
where @rownum<=1 
order by first_name
# 当引入了orde;r by之后，发现打印出了全部结果，这是因为order by引入了文件排序，而where条件是在文件排序操作之前取值的  
```

```sql
# 解决这个问题的关键在于让变量的赋值和取值发生在执行查询的同一阶段：
set @rownum:=0;
select actor_id,@rownum as cnt 
from actor 
where (@rownum:=@rownum+1)<=1;
```

# 六、分区表

加"#"号的文件为分区文件

## 1、分区表的应用场景

1）表非常大以至于无法全部都放在内存中，或者只在表的最后部分有热点数据，其他均是历史数据

2）分区表的数据更容易维护

- 批量删除大量数据可以使用清除整个分区的方式
- 对一个独立分区进行优化、检查、修复等操作

3）分区表的数据可以分布在不同的物理设备上，从而高效地利用多个硬件设备

4）可以使用分区表来避免某些特殊的瓶颈

- innodb的单个索引的互斥访问
- ext3文件系统的inode锁竞争

5）可以备份和恢复独立的分区

## 2、分区表的限制

- 一个表最多只能有1024个分区，在5.7版本的时候可以支持8196个分区

> 此限制和linux有关：linux一切皆文件，做的一切操作都会对文件进行读取，而linux同时打开文件是有限制的,打开的数量和内存相关。

查询到支持文件打开数量，参数open files：

```shell
ulimited -a
```

- 在早期的mysql中，分区表达式必须是整数或者是返回整数的表达式，在mysql5.5中，某些场景可以直接使用列来进行分区
- 如果分区字段中有主键或者唯一索引的列，那么所有主键列和唯一索引列都必须包含进来
- 分区表无法使用外键约束

## 3、[分区表的原理](https://blog.csdn.net/qq_40638598/article/details/120186128)

## 4、分区表的类型

### 1）范围分区

根据列值在给定范围内将行分配给分区

案例：[范围分区](https://blog.csdn.net/qq_40638598/article/details/120211266)

### 2）列表分区

> 类似于按range分区，区别在于list分区是基于列值匹配一个离散值集合中的某个值来进行选择

```sql
CREATE TABLE employees (
    id INT NOT NULL,
    fname VARCHAR(30),
    lname VARCHAR(30),
    hired DATE NOT NULL DEFAULT '1970-01-01',
    separated DATE NOT NULL DEFAULT '9999-12-31',
    job_code INT,
    store_id INT
)
PARTITION BY LIST(store_id) (
    PARTITION pNorth VALUES IN (3,5,6,9,17),
    PARTITION pEast VALUES IN (1,2,10,11,19,20),
    PARTITION pWest VALUES IN (4,12,13,14,18),
    PARTITION pCentral VALUES IN (7,8,15,16)
);
```

### 3）列分区

> mysql从5.5开始支持column分区，可以认为i是range和list的升级版，在5.5之后，可以使用column分区替代range和list，但是column分区只接受普通列不接受表达式

```sql
 CREATE TABLE `list_c` (
 `c1` int(11) DEFAULT NULL,
 `c2` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50500 PARTITION BY RANGE COLUMNS(c1)
(PARTITION p0 VALUES LESS THAN (5) ENGINE = InnoDB,
 PARTITION p1 VALUES LESS THAN (10) ENGINE = InnoDB) */


 CREATE TABLE `list_c` (
 `c1` int(11) DEFAULT NULL,
 `c2` int(11) DEFAULT NULL,
 `c3` char(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50500 PARTITION BY RANGE COLUMNS(c1,c3)
(PARTITION p0 VALUES LESS THAN (5,'aaa') ENGINE = InnoDB,
 PARTITION p1 VALUES LESS THAN (10,'bbb') ENGINE = InnoDB) */


 CREATE TABLE `list_c` (
 `c1` int(11) DEFAULT NULL,
 `c2` int(11) DEFAULT NULL,
 `c3` char(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1
/*!50500 PARTITION BY LIST COLUMNS(c3)
(PARTITION p0 VALUES IN ('aaa') ENGINE = InnoDB,
 PARTITION p1 VALUES IN ('bbb') ENGINE = InnoDB) */
```

### 4）hash分区

> 基于用户定义的表达式的返回值来进行选择的分区，该表达式使用将要插入到表中的这些行的列值进行计算。这个函数可以包含myql中有效的、产生非负整数值的任何表达式

```sql
CREATE TABLE employees (
    id INT NOT NULL,
    fname VARCHAR(30),
    lname VARCHAR(30),
    hired DATE NOT NULL DEFAULT '1970-01-01',
    separated DATE NOT NULL DEFAULT '9999-12-31',
    job_code INT,
    store_id INT
)
PARTITION BY HASH(store_id)
PARTITIONS 4;

CREATE TABLE employees (
    id INT NOT NULL,
    fname VARCHAR(30),
    lname VARCHAR(30),
    hired DATE NOT NULL DEFAULT '1970-01-01',
    separated DATE NOT NULL DEFAULT '9999-12-31',
    job_code INT,
    store_id INT
)
PARTITION BY LINEAR HASH(YEAR(hired))
PARTITIONS 4;
```

### 5）key分区

> 类似于hash分区，区别在于key分区只支持一列或多列，且mysql服务器提供其自身的哈希函数，必须有一列或多列包含整数值

```sql
CREATE TABLE tk (
    col1 INT NOT NULL,
    col2 CHAR(5),
    col3 DATE
)
PARTITION BY LINEAR KEY (col1)
PARTITIONS 3;
```

### 6）子分区

> 在分区的基础之上，再进行分区后存储

```sql
CREATE TABLE `t_partition_by_subpart`
(
  `id` INT AUTO_INCREMENT,
  `sName` VARCHAR(10) NOT NULL,
  `sAge` INT(2) UNSIGNED ZEROFILL NOT NULL,
  `sAddr` VARCHAR(20) DEFAULT NULL,
  `sGrade` INT(2) NOT NULL,
  `sStuId` INT(8) DEFAULT NULL,
  `sSex` INT(1) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`, `sGrade`)
)  ENGINE = INNODB
PARTITION BY RANGE(id)
SUBPARTITION BY HASH(sGrade) SUBPARTITIONS 2
(
PARTITION p0 VALUES LESS THAN(5),
PARTITION p1 VALUES LESS THAN(10),
PARTITION p2 VALUES LESS THAN(15)
);
```



## 5、如何使用分区表

### （1）全量扫描数据，不要任何索引

> 使用简单的分区方式存放表，不要任何索引，根据分区规则大致定位需要的数据为止，通过使用where条件将需要的数据限制在少数分区中，这种策略适用于以正常的方式访问大量数据

### （2）索引数据，并分离热点

> 如果数据有明显的热点，而且除了这部分数据，其他数据很少被访问到，那么可以将这部分热点数据单独放在一个分区中，让这个分区的数据能够有机会都缓存在内存中，这样查询就可以只访问一个很小的分区表，能够使用索引，也能够有效的使用缓存

## 6、在使用分区表的时候需要注意的问题

- null值会使分区过滤无效
- 分区列和索引列不匹配，会导致查询无法进行分区过滤

- 选择分区的成本可能很高

- 打开并锁住所有底层表的成本可能很高
- 维护分区的成本可能很高

# 七、日志

ACID的实现：

- 原子性是通过undo log来实现的
- 隔离性是通过锁来实现的
- 持久性是通过redo log来实现的
- 一致性是通过上面3个来实现的

## 1、三种日志

### （1）redo（InnoDB）

- 当发生数据修改的时候，innodb引擎会先将记录写到redo log中，并更新内存，此时更新就算完成了，同时innodb引擎会在合适的时机将记录操作到磁盘中
- redolog是固定大小的，是循环写的过程
- 用了redolog之后，innodb就可以保证即使数据库发生异常重启，之前的记录也不会丢失，叫做crash-safe

### （2）undo（InnoDB）

- Undo Log是为了实现事务的原子性，在MySQL数据库Innodb存储引擎中，还用undo log来实现多版本并发控制（简称MVCC）
- 在操作任何数据之前，首先将数据备份到一个地方（这个存储数据备份的地方成为undo log）。然后进行数据的修改。如果出现了错误或者用户执行了rollback语句，系统可以利用undo log中的备份将数据恢复到事务开始之前的状态
- 注意：undo log是逻辑日志，可以理解为：
  - 当delete一条记录时，undo log 中会记录一条对应的insert记录
  - 当insert一条记录时，undo log中会记录一条对应的delete记录
  - 当update一条记录时，它记录一条对应相反的update记录

<img src="img\innodb_log.png" />

### （3）binlog——服务端的日志文件

log-bin默认关闭，开启会消耗性能，但一般建议开启，如下为开启状态：

```sql
log-bin = master-bin
```

- binlog是server层的日志，主要做mysql功能层面的事情
- 与redo日志的却别：
  - redo是innodb独有的，binlog是所有引擎都可以使用的
  - redo是物理日志，记录的是在某个数据页上做了什么修改，binlog是逻辑日志，记录的是这个语句的原始逻辑
  - redo是循环写的，空间会用完，binlog是可以追加写的，不会覆盖之前的日志信息
- binlog中会记录所有的逻辑，并且采用追加写的方式
- 一般在企业中数据库会有备份系统，可以定期执行备份，备份的周期可以自己设置
- 恢复数据的过程：
  - 找到最近一次的全量备份数据
  - 从备份的时间点开始，将备份的binlog取出来，重放到要恢复的那个时刻

<img src="img\log2.png" />

1最安全，0,2效率更高，2比0好，少一次在内存的数据复制

## 2、数据更新的过程

涉及到一阶段提交、二阶段提交

<img src="img\data_update.png" />

**执行过程**：

1. 执行器先充引擎中找数据，如果在内存中直接返回，如果不在内存中，查询后返回
2. 执行器拿到数据之后会先修改数据，然后调用引擎接口重新写入数据
3. 引擎将数据更新到内存，同事写数据到redo中，此时处于prepare阶段，并通知执行器执行完成，随时可以操作
4. 执行器生成这个操作的binlog
5. 执行器调用引擎的事务提交接口，引擎吧刚刚写完的redo改成commit状态
6. 更新完成。

**Redo log的两阶段提交:**

- <font color=red>先写入redo log后吸入binlog</font>:假设在redo log写完，binlog还没有写完的时候，mysql进程重启。由于我们之前说过，redo log写完之后，系统即使崩溃，仍然能够把数据恢复回来，所以恢复后这一行c的值是1。但是由于binlog没写完就crash了，这时候binlog里面就没有记录这个语句。因此，之后备份日志的时候，存起来的binlog里面就没有这条语句。然后你会发现，如果需要用这个binlog来恢复临时库的话，由于这个语句的binlog丢失，这个临时库就会少一次更新，恢复出来的这一行c的值就是0，与原来的值不同。
- <font color=red>先写入binlog后写redo log</font>：如果在binlog写完之后crash，由于redo log还没写，崩溃恢复以后这个事务无效，所以这一行c的值就是0。但是binlog里面已经记录了“把c从0改为1”这个日志。所以，在之后用binlog来恢复的时候就多了一个事务出来，恢复出来的这一行c的值就是1，与原库的值不同。

# 八、服务器参数设置

修改和查询参数：

```sql
show variables like '%max_connection%';  #查看最大连接数
set global max_connections = 152;  # 修改
```

## 1、general

（1）数据文件存放的目录：

```sql
datadir=/var/lib/mysql
```

（2）mysql.socket表示server和client在同一台服务器，并且使用localhost进行连接，就会使用socket进行连接：

```sql
socket=/var/lib/mysql/mysql.sock
```

（3）存储mysql的pid：

```sql
pid_file=/var/lib/mysql/mysql.pid
```

（4）mysql服务的端口号:

```sql
port=3306
```

（5）mysql存储默认引擎：

```sql
default_storage_engine=InnoDB
```

（6）当忘记mysql的用户名密码的时候，可以在mysql配置文件中配置该参数，跳过权限表验证，不需要密码即可登录mysql：

```sql
skip-grant-tables
```

## 2、character

（1）character_set_client：客户端数据的字符集

（2）character_set_connection：mysql处理客户端发来的信息时，会把这些数据转换成连接的字符集格式

（3）character_set_results：mysql发送给客户端的结果集所用的字符集

（4）character_set_database：数据库默认的字符集

（5）character_set_server：mysql server的默认字符集

## 3、connection

（1）max_connections：mysql的最大连接数，如果数据库的并发连接请求比较大，应该调高该值

（2）max_user_connections：限制每个用户的连接个数（0表示不限制）

（3）back_log：mysql能够暂存的连接数量，当mysql的线程在一个很短时间内得到非常多的连接请求时，就会起作用，如果mysql的连接数量达到max_connections时，新的请求会被存储在堆栈中，以等待某一个连接释放资源，如果等待连接的数量超过back_log,则不再接受连接资源

（4）wait_timeout：mysql在关闭一个非交互的连接之前需要等待的时长

（5）interactive_timeout：关闭一个交互连接之前需要等待的秒数

- wait_timeout长连接

- interactive短连接

- 交互式：命令行

- 非交互式：jdbc

- 连接池：长连接

## 4、log

（1）log_error：指定错误日志文件名称，用于记录当mysqld启动和停止时，以及服务器在运行中发生任何严重错误时的相关信息

（2）log_bin：指定二进制日志文件名称，用于记录对数据造成更改的所有查询语句

（3）binlog_do_db：指定将更新记录到二进制日志的数据库，其他所有没有显式指定的数据库更新将忽略，不记录在日志中

（4）binlog_ignore_db：指定不将更新记录到二进制日志的数据库

（5）sync_binlog：指定多少次写日志后同步磁盘

（6）general_log：是否开启查询日志记录

（7）general_log_file：指定查询日志文件名，用于记录所有的查询语句

（8）slow_query_log：是否开启慢查询日志记录

（9）slow_query_log_file：指定慢查询日志文件名称，用于记录耗时比较长的查询语句

（10）long_query_time：设置慢查询的时间，超过这个时间的查询语句才会记录日志

（11）log_slow_admin_statements：是否将管理语句写入慢查询日志

## 5、cache

（1）key_buffer_size：索引缓存区的大小（只对myisam表起作用）

（2）query cache

- ​	query_cache_size
  - show status like '%Qcache%';查看缓存的相关属性
  - Qcache_free_blocks：缓存中相邻内存块的个数，如果值比较大，那么查询缓存中碎片比较多
  - Qcache_free_memory：查询缓存中剩余的内存大小
  - Qcache_hits：表示有多少此命中缓存
  - Qcache_inserts：表示多少次未命中而插入
  - Qcache_lowmen_prunes：多少条query因为内存不足而被移除cache
  - Qcache_queries_in_cache：当前cache中缓存的query数量
  - Qcache_total_blocks：当前cache中block的数量

- ​	query_cache_limit：超出此大小的查询将不被缓存
- ​	query_cache_min_res_unit：缓存块最小大小
- ​	query_cache_type：缓存类型，决定缓存什么样的查询
  - 0表示禁用
  - 1表示将缓存所有结果，除非sql语句中使用sql_no_cache禁用查询缓存
  - 2表示只缓存select语句中通过sql_cache指定需要缓存的查询

（3）sort_buffer_size：每个需要排序的线程分派该大小的缓冲区

（4）max_allowed_packet=32M：限制server接受的数据包大小

（5）join_buffer_size=2M：表示关联缓存的大小

（6）thread_cache_size：服务器线程缓存，这个值表示可以重新利用保存再缓存中的线程数量，当断开连接时，那么客户端的线程将被放到缓存中以响应下一个客户而不是销毁，如果线程重新被请求，那么请求将从缓存中读取，如果缓存中是空的或者是新的请求，这个线程将被重新请求，那么这个线程将被重新创建，如果有很多新的线程，增加这个值即可。

- Threads_cached：代表当前此时此刻线程缓存中有多少空闲线程
- Threads_connected：代表当前已建立连接的数量
- Threads_created：代表最近一次服务启动，已创建现成的数量，如果该值比较大，那么服务器会一直再创建线程
- Threads_running：代表当前激活的线程数

## 6、INNODB

（1）innodb_buffer_pool_size：该参数指定大小的内存来缓冲数据和索引，最大可以设置为物理内存的80%

（2）innodb_flush_log_at_trx_commit：主要控制innodb将log buffer中的数据写入日志文件并flush磁盘的时间点，值分别为0，1，2

（3）innodb_thread_concurrency：设置innodb线程的并发数，默认为0表示不受限制，如果要设置建议跟服务器的cpu核心数一致或者是cpu核心数的两倍

（4）innodb_log_buffer_size：此参数确定日志文件所用的内存大小，以M为单位

（5）innodb_log_file_size：此参数确定数据日志文件的大小，以M为单位

（6）innodb_log_files_in_group：以循环方式将日志文件写到多个文件中

（7）read_buffer_size：mysql读入缓冲区大小，对表进行顺序扫描的请求将分配到一个读入缓冲区

（8）read_rnd_buffer_size：mysql随机读的缓冲区大小

（9）innodb_file_per_table：此参数确定为每张表分配一个新的文件

# 九、零散知识

1、当有大批量数据导入mysql的时候，可以先把唯一索引去掉，导入完成后再建立索引。这样导入效率更高，因为不用一边导入数据，一边建索引。

2、能用union all和union的情况下，尽量使用union all，因为union有个distinct的过程。

3、如果组合索引是name和age，那么创建索引顺序为（age,name）的空间要更小。

4、exists：用exists后必须为子查询，且外面的select后不能有子表的字段。（需要查两张表的列，用join；只需要查出一张表的内容则用exists，效率更高。）

exists语句相当于两层for循环，外层查出一行，执行一下exists中的子句，如果子句中有结果，则显示当前行。外层再查出另一个行，如果这时候exists中没有值，则该行不显示。所以，可以用外层的条件限制子查询的结果。

5、join使用笛卡尔积，效率较低

先读入的为驱动表；在mysql中，A join B，mysq优化器有个优化，优化后A不一定是驱动表，所以可以手动指定先读取哪张表。join中，最好非驱动表的连接列是索引列。

6、(left | right)join on 条件1 and 条件2，on后面的内容都是对另一张表做筛选，包括and后的条件。

7、如果字段定义为varchar(10)，那么插入null，那么也会占用存储空间。

8、谓词下推

9、@@开头是系统变量，@开头是自定义变量（当前会话有效）

10、子查询优化limit

优化前：

```sql
select * from test limit 1000000,6;
```

优化后：

```sql
select * from test a 
join(select id from test limit 1000000,6) b 
on a.id = b.id;
```

11、行转列用union

oracle：join、union、decode、case when

mysql：join、union、case when

12、垂直拆分：不同的表放到不同服务器中，分担不同服务器压力

水平拆分：一张表的记录分成多张

13、不一定要数据量大才建分区表，数据量小也可以，比如每次查询的都是同一批次的数据。

14、分区表最好不要按id分区，最好按有某些特征的列分区，根据它的特征来分区，比如，按照age分区。

15、mysql最大连接数可以设置的和连接池一样。

16、set只能设置一部分属性，有的属性只能通过配置文件来修改。

17、Innodb加锁是加在索引上，如果有索引，默认加的是行锁，如果没有索引，则加的是表锁。意向锁是InnoDB数据操作之前自动加的，不需要用户干预

- 共享锁Shared Locks（简称S锁，属于行锁）：多个事务共享一把锁，都可以读，但不能修改
- 排他锁Exclusive Locks（简称X锁，属于行锁）：不能与其他所并存，只有一个事务能获取该锁，只有该事务可以读取和修改
- 意向共享锁intention Shared Locks（简称IS锁，属于表锁）：表示事务准备给数据行加入共享锁，也就是说一个数据行在加共享锁之前必须先取得该表的IS锁
- 意向排他锁Inteneion Exclusive Locks（简称IX锁，索引表锁）：表示事务准备给数据行加入拍他锁，也就是说一个数据行加排他锁之前必须先取得该锁的IX锁
- 自增锁AUTO-INC Locks：针对自增列自增长的一个特殊的表级锁

```sql
show variables like 'innodb_autoinc_lock_mode';
# 默认值1，代表连续，事务未提交则id永久丢失
```

18、mysql可以开启自动释放死锁。

**参考文档**

1、[MYSQL performance schema详解](https://blog.csdn.net/qq_40638598/article/details/117877983)

2、[mysql执行计划](https://blog.csdn.net/qq_40638598/article/details/120051371)

3、[索引优化分析案例](https://blog.csdn.net/qq_40638598/article/details/120147363)

4、[前缀索引实例说明](https://blog.csdn.net/qq_40638598/article/details/120147647)

5、[分区表的底层原理](https://blog.csdn.net/qq_40638598/article/details/120186128)

6、[范围分区](https://blog.csdn.net/qq_40638598/article/details/120211266)

7、[mysql的锁机制](https://blog.csdn.net/qq_40638598/article/details/120258782)

