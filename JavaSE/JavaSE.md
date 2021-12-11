# 一、JDK8新特性

## 1、lambda表达式

使用 Lambda 表达式可以替代只有一个抽象函数的接口实现，告别匿名内部类，代码看
起来更简洁易懂。Lambda表达式同时还提升了对集合、框架的迭代、遍历、过滤数据的操作。

**特点：**

- 函数式编程
- 参数类型自动推断
- 代码量少，简洁

自己写函数式接口的时候，可以加上这个注解，帮助检查是否是函数式接口

```java
@FunctionalInterface
```

方法引用：

```java
public class Lambda1 {
    static String getName(){
        return "LuFei";
    }
    public static void main(String[] args) {
        //方式一：lambda表达式
        Supplier<String> s1 = ()-> Lambda1.getName();
        System.out.println(s1.get());
        //方式二:方法引用
        Supplier<String> s2 = Lambda1::getName;
        System.out.println(s2.get());
    }
}
```

**jdk内置函数式接口**

Supplier 代表一个输出
Consumer 代表一个输入
BiConsumer 代表两个输入
Function 代表一个输入，一个输出（一般输入和输出是不同类型的）
UnaryOperator 代表一个输入，一个输出（输入和输出是相同类型的）
BiFunction 代表两个输入，一个输出（一般输入和输出是不同类型的）
BinaryOperator 代表两个输入，一个输出（输入和输出是相同类型的）

**方法引用的分类**

| 类型         | 语法                    | 对应labda表达式                         |
| ------------ | ----------------------- | --------------------------------------- |
| 静态方法引用 | className::staticMethod | (args)->className.staticMethod(args)    |
| 实例方法引用 | instance::method        | (args)->instance.mehtod                 |
| 对象方法引用 | className::method       | (instance,args)->className.method(args) |
| 构造方法引用 | className::new          | (args)->new className(args)             |



## 2、stream api

stream性能不如for循环

IntStream是Stream的子类

Stream分为 源source，中间操作，终止操作

### （1）生成stream的5中方式

#### **1）数组生成stream**

```java
String[] strs = {"a","b","c","d"};
Stream<String> strsStream = Stream.of(strs);
strsStream.forEach(System.out::println);
```

输出：

a
b
c
d

#### **2）集合生成stream**

```java
List<String> strs = Arrays.asList("1", "2", "3", "4", "5");
Stream<String> strStream = strs.stream();
strStream.forEach(System.out::println);
```

输出：

1
2
3
4
5

#### 3）generate

```java
//无限输出1
Stream<Integer> generate = Stream.generate(() -> 1);
generate.forEach(System.out::print);
System.out.println();
```

输出：

11111111111....无限输出1

#### 4）iterate

```java
//生成1到10的流
Stream<Integer> iterate = Stream.iterate(1, x -> x + 1);
iterate.limit(10).forEach(System.out::println);
```

输出：

1
2
3
4
5
6
7
8
9
10

#### 5）其他API生成stream

```java
String str = "abcdef";
IntStream chars = str.chars();
chars.forEach(System.out::println);
```

输出：

97
98
99
100
101
102

### （2）其他例子

#### 1）limit

```java
//限制输出9个1
Stream<Integer> generate = Stream.generate(() -> 1);
generate.limit(9).forEach(System.out::print);
```

输出：

111111111

#### 2）filter

**筛选出偶数：**

```java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);       
list.stream().filter((x) -> x % 2 == 0).forEach(System.out::println);
```

输出：

2
4
6
8

**选出偶数并求和:**

```Java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
int sum = list.stream().filter(x -> x % 2 == 0).mapToInt(x -> x).sum();
System.out.println(sum);
```

输出：

20

#### 3）max

```java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
Optional<Integer> max = list.stream().max((a, b) -> a - b);
System.out.println(max.get());
```

输出：

9

#### 4）min

```java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
System.out.println(list.stream().min((a, b) -> a - b).get());
```

输出：

1

#### 5）findAny

```java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
System.out.println(list.stream().filter(x -> x % 2 == 0).findAny().get());
```

输出：

2

#### 6）findFirst

```java
//如果filter后没有元素，findFirst会报错
System.out.println(list.stream().filter(x -> {
    System.out.println("执行" + x);
    return x % 2 == 0;
}).findFirst().get());
```

输出：

执行1
执行2
2

#### 7）排序

```java
List<String> strings = Arrays.asList("java", "C#", "javascript", "python", "scala");
strings.stream().sorted().forEach(System.out::println);
```

输出：

C#
java
javascript
python
scala

**自定义排序规则**

```java
List<String> strings = Arrays.asList("java", "C#", "javascript", "python", "scala");
strings.stream().sorted((a, b) -> b.length() - a.length()).forEach(System.out::println);
```

输出：

javascript
python
scala
java
C#

#### 8）collect

```java
//将集合过滤后返回成集合
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
List<Integer> collect = list.stream().filter(x -> x % 2 == 0).collect(Collectors.toList());
collect.forEach(System.out::println);
```

输出：

2
4
6
8

#### 9）distinct

```java
//去重操作,也可以用toSet()
List<Integer> integers = Arrays.asList(1, 2, 12, 12, 1, 2, 4, 5, 4);
List<Integer> collect1 = integers.stream().distinct().collect(Collectors.toList());
collect1.forEach(System.out::println);
```

输出：

1
2
12
4
5

#### 10）skip

```java
//打印21到30
Stream.iterate(1, x -> x + 1).limit(50).skip(20).limit(10).forEach(System.out::println);
```

输出：

21
22
23
24
25
26
27
28
29
30

#### 11）sum

```java
String str2 = "11,22,33,44,55";
System.out.println(Stream.of(str2.split(",")).mapToInt(x -> Integer.valueOf(x)).sum());
System.out.println(Stream.of(str2.split(",")).mapToInt(Integer::valueOf).sum());
```

输出：

165
165

#### 12）创建一组自定义对象

```java
class Person{
    String name;

    public Person() {}

    public Person(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return "Person{" +
                "name='" + name + '\'' +
                '}';
    }
}
```

```java
String str3 = "java,C#,scala,python";
Stream.of(str3.split(",")).map(Person::new).forEach(System.out::println);
```

输出：

Person{name='java'}
Person{name='C#'}
Person{name='scala'}
Person{name='python'}

#### 13）peek

```java
//将str2中每一个数值打印出来，并输出求和
String str2 = "11,22,33,44,55";
System.out.println(Stream.of(str2.split(",")).peek(System.out::println).mapToInt(Integer::valueOf).sum());
```

输出：

11
22
33
44
55
165

#### 14）allMatch

```java
List<Integer> list = Arrays.asList(1, 2, 3, 4, 5, 6, 7, 8, 9);
System.out.println(list.stream().allMatch(x -> x > 0));
```

输出：

true



# 二、容器

1、List

- ArrayList：线程不安全，效率高。查询快，修改，插入，删除慢。扩充默认原来1.5倍。
- LinkedList：线程不安全，效率高。查询快，修改，删除，插入块
- Vector：线程安全，效率高。扩充默认原来2倍。

2、Map

# 三、java图形界面

布局：

​	JAVA 中panel的默认布局就是流式布局，类就是FlowLayout.所谓流式布局意思是从左到右对该容器里面的控件进行布局，当一行不能容纳时候自动换行。 
该布局是从左到右，然后从上到下。JFrame的默认布局就是BorderLayout.这个布局跟流式布局不同。分为中南西北中，五种控件位置摆放方式。 
可以通过setLayout(new FlowLayout())方式把布局管理器设置为流式布局。
所谓网格布局就好像表格那样子设置布局，该布局可以设置大小一致的行列的格子放置空间。可以通过setLayout(new GridLayout(4,4))设置4*4的网格布局。如果想把行列里面的格子大小设置为大小不一致的话可以利用网格组布局。该方法比较复杂，可以参考相关资料

# 四、多线程

## 1、实现多线程的几种方法

（1）继承Thread类

（2）实现Runnable接口

使用了静态代理，代理类就是Thread，共同实现的接口就是Runable

对比使用Thread的好处：

避免了单继承的局限性

方便共享资源

（3）实现callabe接口，实现calll方法

接口所在包：java.util.concurrent

优点：可以返回值，抛异常

缺点：比较繁琐

## **2、线程状态**

新生状态

就绪状态

运行状态

阻塞状态

死亡状态

## **3、停止线程**

自然终止：线程体执行完毕

外部干涉：自己写方法。因为stop()、destory不推荐使用，已过时。

## **4、阻塞**

（1）join()：线程合并（是主线程阻塞，先执行该线程）；成员方法

​	还是会调度

（3）sleep()：休眠，不释放锁

## **5、线程信息**

currentThread():静态方法，获得当前线程的引用

setName():设置线程名称，不设置，就从0开始设置编号

getName():获得线程名称

isAlive():判断线程是否存活

## **6、线程优先级**

优先级：代表概率，不代表绝对的优先级

MAX_PRIORITY  10

NORM_PRIORITY  5（默认）

MIN_PRIORITY   1

setPriority(int priority)：设置优先级

## **7、synchronized同步**

（1）同步块

synchronized(应用类型|this|类.class){
	}

当在静态方法中使用同步块的时候，由于没有this，所以使用类.class

（2）同步方法

## **8、死锁——生产者消费者模式（信号灯法）**

wait()：等待；会释放锁

notify()/notifyAll()：唤醒

这两个方法必须和synchronized一起使用





# 零散知识点

- java中switch只识别int类型的值，boolean类型，char,short,byte会自动装换为int类型。
- 内部类：
  - 成员内部类：静态内部类、非静态内部类
  - 匿名内部类
  - 局部内部类：定义在方法内部，作用于仅限于本方法

# **基本数据转换**

1）boolean类型不可转换为其他数据类型。

2）整形、字符型、浮点型的数据在混合运算中互相装换，转换时遵循以下规则：

容量小的类型自动转换为容量大的数据类型；数据类型按容量大小排为：Byte,short,char->int->long->float->double

Byte,short,char之间不会相互转换，他们三者在计算是首先会转换为int类型。

​     容量大的数据类型转换为容量小的数据类型时，要加上强制转换符，但可能造成精度降低或溢出；使用时要格外注意。

有多种类型的数据混合运算时，系统首先自动的将所有数据装换成容量最大的那种数据类型，然后进行计算。

实数常量默认为double。

整数常量默认为int。

byte表数范围最大为127

long类型常量赋值时超过int类型表数范围是必须在最后面加L如（Long l = 30000000000000L）。

把float类型强制转换为Long类型直接去掉小数部分。

double类型强制装换为float类型时会产生溢出。

(float)0.1与0.1f不等价。前者先是double类型，然后强制转换为float类型；后者为直接储存float类型。



# 反射

**Class对象的生成方式如下：**

**1、类名.class**

JVM将使用类装载器, 将类装入内存(前提是:类还没有装入内存),不做类的初始化工作.返回Class的对象

**2、Class.forName("类名字符串") （注：类名字符串是包名+类名）**

装入类,并做类的静态初始化，返回Class的对象

**3、实例对象.getClass()**  

对类进行静态初始化、非静态初始化；返回引用运行时真正所指的对象(因为:子对象的引用可能会赋给父对象的引用变量中)所属的类的Class的对象



未完待续。。。。

