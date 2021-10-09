# 一、JVM基础

## 1、java从编码到执行

<img src="img\java从编译到执行.png"/>

**JVM是一种规范**

java virtual machine specifications

JVM是跨语言的平台，java、scala、kotlin、groovy...(上百种语言)都可以在jvm上运行。jvm和java无关。任何语言“编译”成class都可以用jvm。

[javase文档](https://docs.oracle.com/en/java/javase/index.html)

[java语言和虚拟机规范文档](https://docs.oracle.com/javase/specs/index.html)

- 虚构出来的一台计算机
- 字节码指令集（汇编语言）
- 内存管理

JRE = jvm + core lib

JDK = jre + development kit

## 2、常见的JVM实现

- Hotspot
  - oracle官方，我们做实验用的JVM
  - java -version
- Jrockit
  - BEA，曾经号称全世界最快的JVM
  - 被oracle 收购，合并于Hotspot
- J9-IBM
- Microsoft VM
- TaoBaoVM
  - hotspot深度定制版
- LiquidVM
  - 直接对硬件
- azul zing
  - 2019年最新垃圾回收的业界标杆
  - www.azul.com

# 二、class文件

binEd可以看class文件的16进制信息

javap -c可以查看class文件的详细信息；idea中view -> show bytecode也可以看到相同的内容。

其次可以用jclasslib插件看

class最多256条指令集



编译各个只有类声明的方法，其中字节码表示的含义：

2a：aload_0：压栈this

b7：invokespecisal，穿两个参数00,01——调用调用object方法

b1：return



开始4个字节表示Magic number，表示文件类型位class——CA FE BA BE

Minor Version：第5、6个字节

Major Version：第7、8个字节

constant_pool_count：第9、10个字节；表示常量池有多少个常量，编号从1开始，比如0010表示常量池有15个常量

之后是具体常量

access flags：两个字节

this class：2个字节，指向常量池中类名的引用

super class

interface count：该类实现了多少个接口

intefaces：一个个接口，记录的还是指向常量池的引用

filds_count：

fields

methods_count

method_info

attribute_count

attribute



# 三、类加载

## 1、过程

（1）Loading

（2）Linking

1. Verification：验证文件是否符合jvm规范
2. Preparation：静态成员变量赋默认值
3. Resolution：将类、方法、属性等符号引用解析为直接引用；常量池中的各种符号引用解析为指针，偏移量等内存地址的直接引用


（3）Initializing

## 2、类加载器

### （1）双亲委派机制

加载类过程：加载器看自己的缓存里有没有加载过，没有则在问父加载器缓存中是否有...如果到bootstrap中都没有，则自顶向下尝试加载。如果最后谁都没加载，则抛出异常：ClassNotFoundException。

使用双亲委派机制是为了安全。

打破双亲委派机制：重写loadclass()

- jdk1.2之前，自定义classLoader都必须重写
- ThreadContextClassLoader可以实现基础类调用实现类代码，通过thread.setContextClassLoader指定
- 热部署、热启动：osgi tomcat都有自己的模块指定classloader（可以加载同一类库的不同版本）

### （2）lazyloading

lazyInitializing：懒加载，大多数jvm都是使用该类是才初始化。JVM规范没有规定何时加载

但是严格规定了什么时候必须初始化:

- new getstatic putstatic invokestatic指令，访问final变量除外
- java.lang.reflect对类进行反射调用时
- 初始化子类的时候，父类首先初始化
- 虚拟机启动时，被执行的主类必须初始化
- 动态语言支持java.lang.invoke.MethodHandle解析的结果为REF_getatic REF_putstatic REF_invokestatic的方法句柄时，该类必须初始化

### （3）类加载器加载范围

- Bootstrap：加载lib/rt.jar charset.jar等核心类，C++实现
- Extension：加载扩展jar包；jre/lib/ext/*.jar；或由-DJava。ext.dirs指定
- App：加载classpath指定内容
- Custom ClassLoader

父加载器不是继承关系

3个类加载器其实都是cun.misc.Launcher类的内部类。而每个加载器加载的路径都在里面写死了。

### （4）自定义类加载器

- 继承ClassLoader
- 重写模板方法findClass
  - 调用defineClass
- 自定义类加载器加载自加密的class
  - 防止反编译
  - 防止篡改

什么时候需要用到自定义类加载器：

- spring生成的代理

- 热部署：重写classloader可以跳过查询之前加载过的class

- 可以给自己的class文件加密（比如，异或一个数进行加密，再次异或可以解密）


### （5）混合模式

- JIT：just in-time complier
- 混合模式
  - 混合使用解释器 + 热点代码编译
  - 起始阶段采用解释执行
  - 热点代码监测
    - 多次被调用的方法（方法计数器：监测方法执行频率）
    - 多次被调用的循环（循环计数器：监测循环执行频率）
    - 进行编译
- -Xmixed 默认为混合模式；开始解释执行，启动速度较快，对热点代码进行检测和编译
- -Xint 使用解释模式，启动快，执行慢
- -Xcomp 使用纯编译模式，执行很快，启动很慢

检测热点代码：-XXCompileThreshold = 10000

# 四、JMM

## 1、硬件层的并发优化基础知识

**缓存等级：**

- CPU：寄存器（L0） 高速缓存（L1、L2）
- CPU共享：高速缓存（L3） 主存（L4）磁盘（L5） 远程文件存储（L6）



**cache line**缓存行：

- cpu读取缓存以cache line为单位，多为64个字节
- 缓存行是为了提高读取效率
- 伪共享：缓存行带来的问题——变量x，y在同一缓存行，被读入到不同cpu，各自更改数据都会影响对方



多线程一致性的硬件层支持

- 老cpu加锁：总线锁会锁住总线，使其他CPU甚至不能访问内存中其他的地址，因而效率较低
- 现在cpu会使用各种各样的cache一致性协议来解决，比如：MESI cache协议（称为缓存锁）
- 现代CPU的数据一致性实现 = 缓存锁 + 总线锁

[MESI博客](https://www.cnblogs.com/z00377750/p/9180644.html)

## 2、乱序问题

CPU为了提高指令执行效率，会在一条指令执行过程中（比如去内存读数据，大概慢100倍），去同时执行另一条指令，前提是，两条指令没有依赖关系。

[乱序问题博客](https://www.cnblogs.com/liushaodong/p/4777308.html)

读指令的同时执行不影响其他指令，而写的同时可以进行合并写，**合并写**使用WCBuffer，WCBuffer比L1速度还快，且一般只有4个位置。

6乱序证明

