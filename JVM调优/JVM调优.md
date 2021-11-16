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

乱序问题也是**单例模式的双重检查锁**——必须加volatile关键字的原因。



CPU为了提高指令执行效率，会在一条指令执行过程中（比如去内存读数据，大概慢100倍），去同时执行另一条指令，前提是，两条指令没有依赖关系。

[乱序问题博客](https://www.cnblogs.com/liushaodong/p/4777308.html)

读指令的同时执行不影响其他指令，而写的同时可以进行合并写，**合并写**使用WCBuffer，WCBuffer比L1速度还快，且一般只有4个位置。

### （1）乱序证明

程序来自美团的工程师

```java
public class T04_Disorder {
    private static int x = 0, y = 0;
    private static int a = 0, b =0;

    public static void main(String[] args) throws InterruptedException {
        int i = 0;
        for(;;) {
            i++;
            x = 0; y = 0;
            a = 0; b = 0;
            Thread one = new Thread(new Runnable() {
                public void run() {
                    //由于线程one先启动，下面这句话让它等一等线程two. 读着可根据自己电脑的实际性能适当调整等待时间.
                    //shortWait(100000);
                    a = 1;
                    x = b;
                }
            });

            Thread other = new Thread(new Runnable() {
                public void run() {
                    b = 1;
                    y = a;
                }
            });
            one.start();other.start();
            one.join();other.join();
            String result = "第" + i + "次 (" + x + "," + y + "）";
            if(x == 0 && y == 0) {
                System.err.println(result);
                break;
            } else {
                //System.out.println(result);
            }
        }
    }


    public static void shortWait(long interval){
        long start = System.nanoTime();
        long end;
        do{
            end = System.nanoTime();
        }while(start + interval >= end);
    }
}
```

最后输出的x和y都等于0，表示发送了乱序

### （2）保证有序性

jvm的有序性实现不一定要依赖硬件级别的内存屏障，还可以依赖硬件级别的lock指令

#### 1）硬件上保证有序

使用CPU内存屏障，不同CPU的内存屏障指令不同

Inter X86：

> sfence:  store| 在sfence指令前的写操作当必须在sfence指令后的写操作前完成。
> lfence：load | 在lfence指令前的读操作当必须在lfence指令后的读操作前完成。
> mfence：modify/mix | 在mfence指令前的读写操作当必须在mfence指令后的读写操作前完成。

> 原子指令，如x86上的”lock …” 指令是一个Full Barrier，执行时会锁住内存子系统来确保执行顺序，甚至跨多个CPU。Software Locks通常使用了内存屏障或原子指令来实现变量可见性和保持程序顺序

lock指令：

例子：lock add；lock是一个指令，add是一个指令。lock加在这里的意思是，当add完成之前，锁住这块内存，不让其他人改变

#### 2）JVM级别如何规范（JSR133）

依赖于cpu硬件的实现。以下四种屏障就是依赖于sfence、lfence的组合

> LoadLoad屏障：
> 	对于这样的语句Load1; LoadLoad; Load2， 
>
> 	在Load2及后续读取操作要读取的数据被访问前，保证Load1要读取的数据被读取完毕。
>
> StoreStore屏障：
>
> 	对于这样的语句Store1; StoreStore; Store2，
> 		
> 	在Store2及后续写入操作执行前，保证Store1的写入操作对其它处理器可见。
>
> LoadStore屏障：
>
> 	对于这样的语句Load1; LoadStore; Store2，
> 		
> 	在Store2及后续写入操作被刷出前，保证Load1要读取的数据被读取完毕。
>
> StoreLoad屏障：
> 	对于这样的语句Store1; StoreLoad; Load2，
>
> ​	 在Load2及后续所有读取操作执行前，保证Store1的写入对所有处理器可见。



**volatile实现细节**

1. 字节码层面
   ACC_VOLATILE

2. JVM层面
   volatile内存区的读写 都加屏障

   > StoreStoreBarrier
   >
   > volatile 写操作
   >
   > StoreLoadBarrier

   > LoadLoadBarrier
   >
   > volatile 读操作
   >
   > LoadStoreBarrier

3. OS和硬件层面
   https://blog.csdn.net/qq_26222859/article/details/52235930
   使用工具：hsdis（HotSpot Dis Assembler）hotSpot虚拟机的反汇编
   windows lock 指令实现 | MESI实现

**synchronized的实现细节**

1. 字节码层面
   方法上：ACC_SYNCHRONIZED
   同步语句块：monitorenter monitorexit
2. JVM层面
   C C++ 调用了操作系统提供的同步机制
3. OS和硬件层面
   X86 : lock cmpxchg / xxx
   [https](https://blog.csdn.net/21aspnet/article/details/88571740)[://blog.csdn.net/21aspnet/article/details/](https://blog.csdn.net/21aspnet/article/details/88571740)[88571740](https://blog.csdn.net/21aspnet/article/details/88571740)



java8大原子操作（虚拟机规范）

（已弃用，了解即可）

最新的JSR-133已经放弃这种描述，但JMM没有变化

《深入理解Java虚拟机》P364

lock：主内存，标识变量为线程独占

unlock：主内存，解锁线程独占变量

read：工作内存，读取内容到工作内存

load：工作内存，read后的值放入线程本地变量副本

use：工作内存，传值给执行引擎

assign：工作内存，执行引擎结果赋值给线程本地变量

store：工作内存，村值到主内存给write备用

write：主内存，写变量值



**hanppens-before原则**（JVM规定重排序必须遵守的规则）

JLS17.4.5

- 程序次序规则：一个线程内，按照代码顺序，书写在前面的操作先行发生于书写在后面的操作；
- 锁定规则：一个unLock操作先行发生于后面对同一个锁额lock操作；
- volatile变量规则：对一个变量的写操作先行发生于后面对这个变量的读操作；
- 传递规则：如果操作A先行发生于操作B，而操作B又先行发生于操作C，则可以得出操作A先行发生于操作C；
- 线程启动规则：Thread对象的start()方法先行发生于此线程的每个一个动作；
- 线程中断规则：对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生；
- 线程终结规则：线程中所有的操作都先行发生于线程的终止检测，我们可以通过Thread.join()方法结束、Thread.isAlive()的返回值手段检测到线程已经终止执行；
- 对象终结规则：一个对象的初始化完成先行发生于他的finalize()方法的开始；

 as if serial：不管如何重排序，单线程执行结果不会改变



java_agent：class读入到内存过程中，agent（自己实现）可以截获class，并任意修改

## 3、对象在内存中的存储布局

### （1）对象内存大小

#### 1）观察虚拟机配置

```shell
java -XX:+PrintCommandLineFlags -version
```

#### 2）普通对象

1. 对象头：markword  8
2. ClassPointer指针：-XX:+UseCompressedClassPointers 为4字节 不开启为8字节
3. 实例数据
   1. 引用类型：-XX:+UseCompressedOops 为4字节 不开启为8字节 
      Oops Ordinary Object Pointers
4. Padding对齐，8的倍数

#### 3）对象数组

1. 对象头：markword 8
2. ClassPointer指针同上
3. 数组长度：4字节
4. 数组数据
5. 对齐 8的倍数

#### 4）实验

1. 新建项目ObjectSize （1.8）

2. 创建文件ObjectSizeAgent

   ```java
   package com.mashibing.jvm.agent;
   
   import java.lang.instrument.Instrumentation;
   
   public class ObjectSizeAgent {
       private static Instrumentation inst;
   
       public static void premain(String agentArgs, Instrumentation _inst) {
           inst = _inst;
       }
   
       public static long sizeOf(Object o) {
           return inst.getObjectSize(o);
       }
   }
   ```

3. src目录下创建META-INF/MANIFEST.MF

   ```java
   Manifest-Version: 1.0
   Created-By: mashibing.com
   Premain-Class: com.mashibing.jvm.agent.ObjectSizeAgent
   ```

   注意Premain-Class这行必须是新的一行（回车 + 换行），确认idea不能有任何错误提示

4. 打包jar文件

5. 在需要使用该Agent Jar的项目中引入该Jar包
   project structure - project settings - library 添加该jar包

6. 运行时需要该Agent Jar的类，加入参数：

   ```java
   -javaagent:C:\work\ijprojects\ObjectSize\out\artifacts\ObjectSize_jar\ObjectSize.jar
   ```

7. 如何使用该类：

   ```java
   package com.mashibing.jvm.c3_jmm;
      
   import com.mashibing.jvm.agent.ObjectSizeAgent;
   
   public class T03_SizeOfAnObject {
      public static void main(String[] args) {
   	   System.out.println(ObjectSizeAgent.sizeOf(new Object()));
   	   System.out.println(ObjectSizeAgent.sizeOf(new int[] {}));
   	   System.out.println(ObjectSizeAgent.sizeOf(new P()));
      }
   
      private static class P {
   					   //8 _markword
   					   //4 _oop指针
   	   int id;         //4
   	   String name;    //4
   	   int age;        //4
   
   	   byte b1;        //1
   	   byte b2;        //1
   
   	   Object o;       //4
   	   byte b3;        //1
   
      }
   }
   ```

### （2）对象头信息（JDK1.8）

内容在JVM源码中，markOop.hpp文件

32位：

<img src="img\markword_32.png"/>

64位：

<img src="img\markword_64.png"/>

**1）hashCode部分**：

31位hashCode -> System.identityHashcode(...)

按原始内容计算的hashcode,重新过的hashCode方法计算的结果不会存在这里。

> 如果对象没有重写hashcode方法，name默认是调用os::random产生hashcode，可以通过System.identityHashCode获取；os::random产生的规则为：next_rand = (16807 seed) mod (2<sup>31</sup> - 1)，因此可以使用31位存储，另外一旦生产力hashCode，JVM会将其记录在markwork中。
>

什么时候会产生hashCode?当然是调用未重写的hashCode()方法以及System.identityHashCode()的时候



为什么GC默认最大年龄是15？markword中仅为其分配了4位



6    14:49













**面试题**

1. 请解释一下对象的创建过程？
2. 对象在内存中的存储布局？
3. 对象头具体包含什么？
4. 对象怎么定位？
5. 对象怎么分配？（GC相关内容）
6. Object o = new Object()在内存中占用多少字符？（16个字节）

默认开启压缩classpoint；最终大小为8的倍数