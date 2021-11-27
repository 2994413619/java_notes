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



identityHashCode的问题：当一个对象计算过identityHashCode之后，不能进入偏向锁状态

https://cloud.tencent.com/developer/article/1480590

https://cloud.tencent.com/developer/article/1484167

https://cloud.tencent.com/developer/article/1485795

https://cloud.tencent.com/developer/article/1482500



## 4、Runtime Data Area

<img src="img\run-time_data_areas.png" />

<img src="img\线程共享区域.png" />



### （1）PC 程序计数器

> 存放指令位置
>
> 虚拟机的运行，类似于这样的循环：
>
> while( not end ) {
>
> ​	取PC中的位置，找到对应位置的指令；
>
> ​	执行该指令；
>
> ​	PC ++;
>
> }

### （2）JVM stacks

线程私有；每个线程对应一个栈，每个方法对应一个栈帧（fream）。

fream:

- Local Variable Table（局部变量）
- Operand Stack（操作数栈）
  对于long的处理（store and load），多数虚拟机的实现都是原子的
  jls 17.7，没必要加volatile
- Dynamic Linking
  https://blog.csdn.net/qq_41813060/article/details/88379473 
  jvms 2.6.3
- return address
  a() -> b()，方法a调用了方法b, b方法的返回值放在什么地方

### （3）native method stacks

### （4）Direct meronry（直接内存）

> JVM可以直接访问的内核空间的内存 (OS 管理的内存)
>
> NIO ， 提高效率，实现zero copy

NIO相关；相当于是JVM可以访问内核的内存，不用中间拷贝一次（IO本来是网络传输过来，放到内核内存中，然后JVM使用必须先拷贝一份过来，但是NIO省了这个过程，可以直接访问了——零拷贝）

### （5）method area

线程共享

方法区是一个概念，以下是具体实现

**1）Perm Space (<1.8) 永久区**

- 字符串常量位于PermSpace
- FGC不会清理
- 大小启动的时候指定，不能变

**2）Meta Space (>=1.8)**

- 字符串常量位于堆
- 会触发FGC清理
- 不设定的话，最大就是物理内存

思考：

> 如何证明1.7字符串常量位于Perm，而1.8位于Heap？
>
> 提示：结合GC， 一直创建字符串常量，观察堆，和Metaspace

包含run-time constant pool

### （6）heap

线程共享

## 5、Instruction Set

<clinit>：静态语句块

<init>：构造方法

### （1）一个面试题

```java
public static void main(String[] args) {
    int i = 8;
    i = i++;//输出8
    //i = ++i;//输出9
    System.out.println(i);
}
```

查看上述程序编译后的main方法：

```java
 0 bipush 8			//把8push到操作数栈
 2 istore_1			//把i存入局部变量表下标为1的位置
 3 iload_1			//把下标为1的局部变量push到操作数栈中
 4 iinc 1 by 1		//把局部变量表下标为1的加1
 7 istore_1			//把栈中的8赋值给局部变量表下标为1的变量
 8 getstatic #2 <java/lang/System.out : Ljava/io/PrintStream;>
11 iload_1
12 invokevirtual #3 <java/io/PrintStream.println : (I)V>
15 return
```



<img src="img\fream_info.png"/>

### （2）例子

#### 例1

当数值大于127时，上例中的bipush变为sipush

局部变量表第一个是this（只要不是static方法），第二个是k，第三个是i.

```java
public void m2(int k) {
    int i = 300;
}
```

```java
0 sipush 300
3 istore_2
4 return
```

#### 例2

```java
package com.mashibing.jvm.c4_RuntimeDataAreaAndInstructionSet;

public class Hello_02 {
    public static void main(String[] args) {
        Hello_02 h = new Hello_02();
        h.m1();
    }

    public void m1() {
        int i = 200;
    }

    public void m2(int k) {
        int i = 300;
    }

    public void add(int a, int b) {
        int c = a + b;
    }

    public void m3() {
        Object o = null;
    }

    public void m4() {
        Object o = new Object();
    }


}
```

main：

```java
 0 new #2 <com/mashibing/jvm/c4_RuntimeDataAreaAndInstructionSet/Hello_02>
 3 dup
 4 invokespecial #3 <com/mashibing/jvm/c4_RuntimeDataAreaAndInstructionSet/Hello_02.<init> : ()V>
 7 astore_1
 8 aload_1
 9 invokevirtual #4 <com/mashibing/jvm/c4_RuntimeDataAreaAndInstructionSet/Hello_02.m1 : ()V>
12 return
```

0：在堆中创建对象，变量赋默认值，压栈一个指针到stack中

3：在stack中赋值一个指向对象的指针（这时候有两个指针）

4：复制的指针弹栈，执行构造方法，这时候成员变量就是初始值

如果这时候m1有返回值，return指令上面会有个pop，把返回值弹栈；如果有返回值，且有变量接受，这不会有弹栈指令，但有个istore_指令

m1：

```java
0 sipush 200
3 istore_1
4 return
```

#### 例3

递归

```java
package com.mashibing.jvm.c4_RuntimeDataAreaAndInstructionSet;

public class Hello_04 {
    public static void main(String[] args) {
        Hello_04 h = new Hello_04();
        int i = h.m(3);
    }

    public int m(int n) {
        if(n == 1) return 1;
        return n * m(n-1);
    }
}
```

m():

```java
 0 iload_1
 1 iconst_1			//压栈1
 2 if_icmpne 7 (+5)	//比较连个int,如果不等，跳到7
 5 iconst_1
 6 ireturn
 7 iload_1
 8 aload_0			//load this
 9 iload_1
10 iconst_1
11 isub				//弹出 3（n） 和 1
12 invokevirtual #4 <com/mashibing/jvm/c4_RuntimeDataAreaAndInstructionSet/Hello_04.m : (I)I>	//需要两个参数，2和this
15 imul
16 ireturn
```

### （5）invoke指令

**InvokeStatic**：调用静态方法

**InvokeVirtual**：自带多态

**InvokeInterface**：

```java
public static void main(String[] args) {
    List<String> list = new ArrayList<String>();
    list.add("hello");//InvokeInterface 

    ArrayList<String> list2 = new ArrayList<>();
    list2.add("hello2");//InvokeVirtual
}
```

**InovkeSpecial**：

- 可以直接定位，不需要多态的方法
- private 方法 ， 构造方法

**InvokeDynamic**：	

- 1.7才有
- JVM最难的指令
- lambda表达式或者反射或者其他动态语言scala kotlin，或者CGLib ASM，动态产生的class，会用到的指令
- 只要使用了lamda表达式，就会产生内部类



```java
for(;;){I i = C::n}//1.8之前会发生OOM，因为会一直创建class到方法区，但是1.8之前不会发生FGC
```



扩展：指令集的设计

- 基于栈的指令集（JVM）：设计简单（无论如何设计，底层硬件都是寄存器的）
- 基于寄存器的指令集（汇编）：设计复杂，但执行快

Hotspot的local variable table类似于寄存器

# 五、GC

Garbage Collertor tuning

## 1、如何定位垃圾

引用计数（ReferenceCount）

根可达算法(RootSearching)，四种root

- 线程栈变量
- 静态变量
- 常量池
- JNI指针

## 2、常见的垃圾回收算法

- 标记清除(mark sweep) - 位置不连续 产生碎片 效率偏低（两遍扫描）
- 拷贝算法 (copying) - 没有碎片，浪费空间
- 标记压缩(mark compact) - 没有碎片，效率偏低（两遍扫描，指针需要调整）

## 3、JVM内存分代模型

（1）部分垃圾回收器使用的模型

> 除Epsilon ZGC Shenandoah之外的GC都是使用逻辑分代模型
>
> G1是逻辑分代，物理不分代
>
> 除此之外不仅逻辑分代，而且物理分代

（2）新生代 + 老年代 + 永久代（1.7）Perm Generation/ 元数据区(1.8) Metaspace

- 永久代 元数据 - Class
- 永久代必须指定大小限制 ，元数据可以设置，也可以不设置，无上限（受限于物理内存）
- 字符串常量 1.7 - 永久代，1.8 - 堆
- MethodArea逻辑概念 - 永久代、元数据

（3）新生代 = Eden + 2个suvivor区 

- YGC回收之后，大多数的对象会被回收，活着的进入s0
- 再次YGC，活着的对象eden + s0 -> s1
- 再次YGC，eden + s1 -> s0
- 年龄足够 -> 老年代 （15 CMS 6）
- s区装不下 -> 老年代

（4）老年代

- 顽固分子
- 老年代满了FGC Full GC

（5）GC Tuning (Generation)

- 尽量减少FGC
- MinorGC = YGC
- MajorGC = FGC





新生代和老年代的1:2（默认值）是可以通过参数设置的；查看比例：

```shell
java -XX:+PrintFlagsFinal -version | findstr NewRatio
```

- MinorGC/YGC：年轻代空间耗尽时出发（-Xmn）

- MajorGC/FullGC：在老年代无法继续分配空间时触发，新生代老年代同时进行回收（-Xms -Xmx）






**细节问题**

栈上分配

- 线程私有小对象
- 无逃逸（只有我这段代码使用，没有别的地方使用了）
- 支持标量替换（基本类型代替对象，比如对象T，有两个int属性，那么可以使用这两个对象代替他）
- 无需调整

线程本地分配TLAB（Thread Local Allocation Buffer）

- 占用eden，默认1%

- 多线程的时候不用竞争Eden就可以申请空间，提高效率

- 小对象

- 无需调整

  

**例子**：加上和去掉逃逸分析 标量替换，查看程序跑了多长时间

```java
//-XX:-DoEscapeAnalysis -XX:-EliminateAllocations -XX:-UseTLAB -Xlog:c5_gc*
// 逃逸分析 标量替换 线程专有对象分配

public class TestTLAB {
    //User u;
    class User {
        int id;
        String name;

        public User(int id, String name) {
            this.id = id;
            this.name = name;
        }
    }

    void alloc(int i) {
        new User(i, "name " + i);
    }

    public static void main(String[] args) {
        TestTLAB t = new TestTLAB();
        long start = System.currentTimeMillis();
        for(int i=0; i<1000_0000; i++) t.alloc(i);
        long end = System.currentTimeMillis();
        System.out.println(end - start);

        //for(;;);
    }
}
```

## 4、一些问题

### （1）对象何时进入老年代

超过XX:MaxTenuring Threshold 制定次数（YGC）

- Parallel Scavenge 15
- CMS 6
- G1 15

动态年龄

- s1 -> s2超过50%
- 把年龄最大的放入O

**对象分配详细过程**：

<img src="img\对象分配过程详解.png" />

### （2）jvm误区--动态对象年龄判定

（不重要）https://www.jianshu.com/p/989d3b06a49d

### （3）分配担保：

（不重要）

YGC期间 survivor区空间不够了 空间担保直接进入老年代
参考：https://cloud.tencent.com/developer/article/1082730

## 5、常见的垃圾回收器

<img src="img\Garbage_Collectors.png" />

图中红线表示可以组合；1.8默认的垃圾回收：PS + ParallelOld；epsilon debug用的；G1只有逻辑上分代，（调优简单）；ZGC没有分代

### （1）垃圾回收常见组合(三种)

- Serial + Serial Old
- Parallel Scavenge + Parallel Old（默认的）
- ParNew + CMS

### （2）垃圾收集器跟内存大小的关系

- Serial 几十兆
- PS 上百兆 - 几个G
- CMS - 20G
- G1 - 上百G
- ZGC - 4T - 16T（JDK13）

### （3）基础概念

**历史**：JDK诞生 Serial追随 提高效率，诞生了PS，为了配合CMS，诞生了PN，CMS是1.4版本后期引入，CMS是里程碑式的GC，它开启了并发回收的过程，但是CMS毛病较多，因此目前没有任何一个JDK版本默认是CMS，并发垃圾回收是因为无法忍受STW。

**STW**：stop the world；就是说垃圾回收的时候其他线程都得停止，给我让道，safe point：说的是不是说挺就会停，而是会找一个安全点停；这个时间叫做**停顿时间**。目前垃圾回收都有STW，ZGC号称10ms以内

- 内存泄漏memory leak；泄露：一块内存被占了，一致用不了
- 内存溢出out of memory

ZGC目前只支持linux

### （4）常见的垃圾回收器

1）Serial 年轻代 串行回收

刚开始的时候，JVM内存不大（几十M的样子），所以用这个。

2）PS 年轻代 并行回收

3）ParNew 年轻代 配合CMS的并行回收（在PS上做了增强，以便配合CMS）

4）SerialOld （Serial用于老年代）

5）ParallelOld

5）Concurrent Mark Sweep 老年代 并发的， 垃圾回收和应用程序同时运行，降低STW的时间(200ms)
CMS问题比较多，所以现在没有一个版本默认是CMS，只能手工指定
CMS既然是MarkSweep，就一定会有碎片化的问题，碎片到达一定程度，CMS的老年代分配对象分配不下的时候，使用SerialOld 进行老年代回收
想象一下：
PS + PO -> 加内存 换垃圾回收器 -> PN + CMS + SerialOld（几个小时 - 几天的STW）
几十个G的内存，单线程回收 -> G1 + FGC 几十个G -> 上T内存的服务器 ZGC
算法：三色标记 + Incremental Update

7）G1(10ms)
算法：三色标记 + SATB

8）ZGC (1ms) PK C++
算法：ColoredPointers + LoadBarrier

9）Shenandoah
算法：ColoredPointers + WriteBarrier

10）Eplison

11）PS 和 PN区别的延伸阅读：
[https://docs.oracle.com/en/java/javase/13/gctuning/ergonomics.html#GUID-3D0BB91E-9BFF-4EBB-B523-14493A860E73](https://docs.oracle.com/en/java/javase/13/gctuning/ergonomics.html)

### （5）CMS

（重要）concurrent mark sweep

<img src="img\CMS.png" />

- 初始标记（initial mark）：标记根节点（roots），有STW。
- 并发标记（concurrent mark）：占总时间的80%，所以这个步骤并发执行。
- 重新标记（remark）：第二个过程是并发执行的，可能产生新的垃圾，或者垃圾变成不是垃圾，所以要从新标记；有STW。
- 并发清理（concurrent sweep）：过程中产生的垃圾叫浮动垃圾，下一次处理。

#### 1）CMS的问题：

- 内存碎片化（Memory Fragmentation）：后来会用一个单线程来回收（FGC），效率低
- 浮动垃圾（Floating Garbage）

> Concurrent Mode Failure
> 产生：if the concurrent collector is unable to finish reclaiming the unreachable objects before the tenured generation fills up, or if an allocation cannot be satisfiedwith the available free space blocks in the tenured generation, then theapplication is paused and the collection is completed with all the applicationthreads stopped
>
> 解决方案：降低触发CMS的阈值
>
> PromotionFailed（晋升失败）
>
> 解决方案类似，保持老年代有足够的空间
>
> –XX:CMSInitiatingOccupancyFraction 92% 可以降低这个值，让CMS保持老年代足够的空间（到达这个值就会发生FGC）

#### 2）CMS日志分析

执行命令：java -Xms20M -Xmx20M -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC com.mashibing.jvm.gc.T15_FullGC_Problem01

[GC (Allocation Failure) [ParNew: 6144K->640K(6144K), 0.0265885 secs] 6585K->2770K(19840K), 0.0268035 secs] [Times: user=0.02 sys=0.00, real=0.02 secs] 

> ParNew：年轻代收集器
>
> 6144->640：收集前后的对比
>
> （6144）：整个年轻代容量
>
> 6585 -> 2770：整个堆的情况
>
> （19840）：整个堆大小



```java
[GC (CMS Initial Mark) [1 CMS-initial-mark: 8511K(13696K)] 9866K(19840K), 0.0040321 secs] [Times: user=0.01 sys=0.00, real=0.00 secs] 
	//8511 (13696) : 老年代使用（最大）
	//9866 (19840) : 整个堆使用（最大）
[CMS-concurrent-mark-start]
[CMS-concurrent-mark: 0.018/0.018 secs] [Times: user=0.01 sys=0.00, real=0.02 secs] 
	//这里的时间意义不大，因为是并发执行
[CMS-concurrent-preclean-start]
[CMS-concurrent-preclean: 0.000/0.000 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
	//标记Card为Dirty，也称为Card Marking
[GC (CMS Final Remark) [YG occupancy: 1597 K (6144 K)][Rescan (parallel) , 0.0008396 secs][weak refs processing, 0.0000138 secs][class unloading, 0.0005404 secs][scrub symbol table, 0.0006169 secs][scrub string table, 0.0004903 secs][1 CMS-remark: 8511K(13696K)] 10108K(19840K), 0.0039567 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
	//STW阶段，YG occupancy:年轻代占用及容量
	//[Rescan (parallel)：STW下的存活对象标记
	//weak refs processing: 弱引用处理
	//class unloading: 卸载用不到的class
	//scrub symbol(string) table: 
		//cleaning up symbol and string tables which hold class-level metadata and 
		//internalized string respectively
	//CMS-remark: 8511K(13696K): 阶段过后的老年代占用及容量
	//10108K(19840K): 阶段过后的堆占用及容量

[CMS-concurrent-sweep-start]
[CMS-concurrent-sweep: 0.005/0.005 secs] [Times: user=0.00 sys=0.00, real=0.01 secs] 
	//标记已经完成，进行并发清理
[CMS-concurrent-reset-start]
[CMS-concurrent-reset: 0.000/0.000 secs] [Times: user=0.00 sys=0.00, real=0.00 secs]
	//重置内部结构，为下次GC做准备
```

并发标记算法：三色标记

### （6）G1

JDK1.8之后开始用比较好

Garbage First：垃圾优先；先回收存活对象最少的Region

[入门文章](https://www.oracle.com/technical-resources/articles/java/g1gc.html)

<img src="img\G1_memory.png" />

#### 1）特点

- 逻辑分代，物理不分代；
- 分而治之：分为一小块一小块的region，一块一块的处理垃圾；
  - old、survivor、eden都分为了一个一个Region（1M——32M）
  - 手工指定大小：-XX:G1HeapRegionSize
  - 大对象，占两个以上的region的叫做Humongous
  - 每一个region可以属于老年代也可以属于年轻代，但在同一时刻只能属于一个代。
- 比起PS，吞吐量降低10%—15%；响应速度提升了（200ms以内）
- 新老年代是动态的（年轻代：5%—60%；YGC频繁就会调大）
  - 一般不用手工指定
  - 也不要手工指定，因为这是G1预测停顿时间的基准
- 何时GC：
  - YGC
    - Eden空间不足
    - 多线程并发执行
  - FGC
    - Old空间不足
    - System.gc()

#### 2）基本概念

- CSet（Collection Set）：一组可被回收的分区集合。在CSet中存活的数据会在GC过程中被移动到另一个可用分区，CSet中的分区可以来自Eden、survivor、old。CSet会占用不到整个堆空间的1%。
- RSet（RememberedSet）：记录了其他Region中的对象到本Region的引用。（RSet的价值在于垃圾回收不需要扫描整个堆找到谁引用了当前分区中的对象，只需要扫描RSet即可；每个Region格外使用一块内存存这个信息，ZGC中没有这个）
  - RSet于赋值的效率：由于RSet的存在，每次给对象赋引用的时候，就得做一些额外的操作，指的是在RSet中做一些额外的记录（在GC中被称为写屏障，这个写屏障不等于内存屏障）
- card table：把内存分为一个一个card；当老年代的card中有对象指向年轻代，则整个card标记为dirty；使用bitMap（位图）标记card，也就是用1、0来标记。（由于做YGC时，需要扫描整个OLD区，效率非常低，所以JVM设计了CardTable， 如果一个OLD区CardTable中有对象指向Y区，就将它设为Dirty，下次扫描时，只需要扫描Dirty Card）

#### 3）MixedGC

相当于CMS：Old区内存使用超过阈值（默认45%）时，启动MixedGC。（-XX:InitiatingHeapOccupacyPercent）

- 初始标记 STW
- 并发标记
- 最终标记 STW
- 筛选回收 STW（并行）

java 10以前是串行FullGC，之后是并行FullGC（G1调优的目标：尽量不要有FullGC，但不容易达到）

问题：G1有FullGC吗？发送FullGC怎么办？（调小阈值）

#### 4）并发标记算法

- 三色标记
  - 白色：未被标记的对象
  - 灰色：自身被标记，成员变量未被标记
  - 黑色：自身和成员变量均已被标记
- 可能出现漏标的情况，发生的两个必要条件（被标记就不是垃圾，漏标会导致不是垃圾的对象被回收）
  - 黑色指向白色
  - 指向白色的灰色不再指向白色
- 避免漏标的方法（打破以上两个条件之一即可）G1使用的是SATB
  - incremental update——增量更新，关注引用的增加，把黑色重新标记为灰色，下次重新扫描属性（CMS使用）；缺点：会重新扫描黑色的所有成员变量
  - SATB（snapshot at the beginning）——关注引用的删除，当灰色指向白色的引用消失的时候，要把这个引用推到GC的堆栈，保证白色还能被GC扫描到

问题：为什么G1使用SATB

答：灰色—>白色 引用消失，如果没有黑色指向白色，引用会被push到堆栈。下次扫描时拿到这个引用，由于有RSet的存在，不需要扫描整个堆去查找指向白色的引用，效率比较高。

<img src="img\三色标记_1.png" />

<img src="img\三色标记_2.png" />



#### 5）G1日志详解

```java
[GC pause (G1 Evacuation Pause) (young) (initial-mark), 0.0015790 secs]
//young -> 年轻代 Evacuation-> 复制存活对象 
//initial-mark 混合回收的阶段，这里是YGC混合老年代回收
   [Parallel Time: 1.5 ms, GC Workers: 1] //一个GC线程
      [GC Worker Start (ms):  92635.7]
      [Ext Root Scanning (ms):  1.1]
      [Update RS (ms):  0.0]
         [Processed Buffers:  1]
      [Scan RS (ms):  0.0]
      [Code Root Scanning (ms):  0.0]
      [Object Copy (ms):  0.1]
      [Termination (ms):  0.0]
         [Termination Attempts:  1]
      [GC Worker Other (ms):  0.0]
      [GC Worker Total (ms):  1.2]
      [GC Worker End (ms):  92636.9]
   [Code Root Fixup: 0.0 ms]
   [Code Root Purge: 0.0 ms]
   [Clear CT: 0.0 ms]
   [Other: 0.1 ms]
      [Choose CSet: 0.0 ms]
      [Ref Proc: 0.0 ms]
      [Ref Enq: 0.0 ms]
      [Redirty Cards: 0.0 ms]
      [Humongous Register: 0.0 ms]
      [Humongous Reclaim: 0.0 ms]
      [Free CSet: 0.0 ms]
   [Eden: 0.0B(1024.0K)->0.0B(1024.0K) Survivors: 0.0B->0.0B Heap: 18.8M(20.0M)->18.8M(20.0M)]
 [Times: user=0.00 sys=0.00, real=0.00 secs] 
//以下是混合回收其他阶段
[GC concurrent-root-region-scan-start]
[GC concurrent-root-region-scan-end, 0.0000078 secs]
[GC concurrent-mark-start]
//无法evacuation，进行FGC
[Full GC (Allocation Failure)  18M->18M(20M), 0.0719656 secs]
   [Eden: 0.0B(1024.0K)->0.0B(1024.0K) Survivors: 0.0B->0.0B Heap: 18.8M(20.0M)->18.8M(20.0M)], [Metaspace: 38
76K->3876K(1056768K)] [Times: user=0.07 sys=0.00, real=0.07 secs]

```

在G1中发生了Full GC得看看是否有问题，特别是如上回收前后内存大小一样，看看是否内存泄露了



**GC定论**：No Silver Bullet（一切问题的通用解决方案，没有）



### （7）ZGC

不分代

颜色指针（colored pointers）



# 六、JVM参数

## 1、常见垃圾回收器组合参数设定(1.8)

* -XX:+UseSerialGC = Serial New (DefNew) + Serial Old
  * 小型程序。默认情况下不会是这种选项，HotSpot会根据计算及配置和JDK版本自动选择收集器
* -XX:+UseParNewGC = ParNew + SerialOld
  * 这个组合已经很少用（在某些版本中已经废弃）
  * https://stackoverflow.com/questions/34962257/why-remove-support-for-parnewserialold-anddefnewcms-in-the-future
* -XX:+UseConc<font color=red>(urrent)</font>MarkSweepGC = ParNew + CMS + Serial Old
* -XX:+UseParallelGC = Parallel Scavenge + Parallel Old (1.8默认) 【PS + SerialOld】
* -XX:+UseParallelOldGC = Parallel Scavenge + Parallel Old
* -XX:+UseG1GC = G1
* Linux中没找到默认GC的查看方法，而windows中会打印UseParallelGC 
  * java +XX:+PrintCommandLineFlags -version
  * 通过GC的日志来分辨

* Linux下1.8版本默认的垃圾回收器到底是什么？

  * 1.8.0_181 默认（看不出来）Copy MarkCompact
  * 1.8.0_222 默认 PS + PO

## 2、常用参数

查看所有参数（差不多有七八百个）：

```shell
java -XX:+PrintFlagsFinal -version
```

- JVM的命令行参数参考：https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html

- HotSpot参数分类

  > 标准： - 开头，所有的HotSpot都支持
  >
  > 非标准：-X 开头，特定版本HotSpot支持特定命令（有的版本有，有的版本没有）
  >
  > 不稳定：-XX 开头，下个版本可能取消


java 命令看参数列表：java -version

查看参数描述：java -X

试验用程序：

```java
import java.util.List;
import java.util.LinkedList;

public class HelloGC {
  public static void main(String[] args) {
    System.out.println("HelloGC!");
    List list = new LinkedList();
    for(;;) {
      byte[] b = new byte[1024*1024];
      list.add(b);
    }
  }
}
```

**相关参数以及运行结果**：

- 区分概念：内存泄漏memory leak，内存溢出out of memory

- java -XX:+PrintCommandLineFlags HelloGC

  ```shell
  -XX:InitialHeapSize=266930560 -XX:MaxHeapSize=4270888960 -XX:+PrintCommandLineFlags -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:-UseLargePagesIndividualAllocation -XX:+UseParallelGC 
  HelloGC!
  Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
  	at com.ityc.test.demo.HelloGC.main(HelloGC.java:11)
  ```

- java -Xmn10M -Xms40M -Xmx60M -XX:+PrintCommandLineFlags -XX:+PrintGC  HelloGC（可手动设置初始heap、最大heap大小，建议设成一样，不要让堆大小弹来弹去；Xms初始；Xmx最大；Xmn新生代大小；PrintGC打印GC信息）

  ```shell
  -XX:InitialHeapSize=41943040 -XX:MaxHeapSize=62914560 -XX:MaxNewSize=10485760 -XX:NewSize=10485760 -XX:+PrintCommandLineFlags -XX:+PrintGC -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:-UseLargePagesIndividualAllocation -XX:+UseParallelGC 
  HelloGC!
  [GC (Allocation Failure)  7312K->5936K(39936K), 0.0026297 secs]
  [GC (Allocation Failure)  13260K->13024K(39936K), 0.0026803 secs]
  [GC (Allocation Failure)  20506K->20176K(39936K), 0.0024689 secs]
  [GC (Allocation Failure)  27497K->27312K(39936K), 0.0024978 secs]
  [Full GC (Ergonomics)  27312K->27279K(54272K), 0.0101463 secs]
  [GC (Allocation Failure)  34603K->34512K(54272K), 0.0027672 secs]
  [GC (Allocation Failure)  41829K->41680K(53248K), 0.0049966 secs]
  [Full GC (Ergonomics)  41680K->41616K(59392K), 0.0025584 secs]
  [GC (Allocation Failure)  47894K->47856K(59904K), 0.0015992 secs]
  [Full GC (Ergonomics)  47856K->47760K(59904K), 0.0023535 secs]
  [Full GC (Ergonomics)  54032K->53905K(59904K), 0.0032761 secs]
  [Full GC (Ergonomics)  57101K->56977K(59904K), 0.0022696 secs]
  [Full GC (Allocation Failure)  56977K->56958K(59904K), 0.0090463 secs]
  Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
  	at com.ityc.test.demo.HelloGC.main(HelloGC.java:11)
  ```

  打印GC信息的参数：PrintGCDetails（详细细节） PrintGCTimeStamps（信息时间） PrintGCCauses（GC参数的原因）

- java -XX:+UseConcMarkSweepGC -XX:+PrintCommandLineFlags -XX:+PrintGC HelloGC（使用CMS）

  ```shell
  -XX:InitialHeapSize=266930560 -XX:MaxHeapSize=4270888960 -XX:MaxNewSize=348966912 -XX:MaxTenuringThreshold=6 -XX:OldPLABSize=16 -XX:+PrintCommandLineFlags -XX:+PrintGC -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:+UseConcMarkSweepGC -XX:-UseLargePagesIndividualAllocation -XX:+UseParNewGC 
  HelloGC!
  [GC (Allocation Failure)  69090K->65257K(253440K), 0.0201256 secs]
  [GC (Allocation Failure)  134199K->134178K(253440K), 0.0237539 secs]
  [GC (CMS Initial Mark)  135202K(253440K), 0.0001501 secs]
  [GC (Allocation Failure)  203126K->202467K(274000K), 0.0225321 secs]
  [GC (CMS Final Remark)  229441K(274000K), 0.0010508 secs]
  [GC (Allocation Failure)  271800K->270005K(402344K), 0.0206795 secs]
  [GC (CMS Initial Mark)  271029K(402344K), 0.0001351 secs]
  [GC (Allocation Failure)  338960K->338603K(409540K), 0.0251981 secs]
  [GC (Allocation Failure)  407566K->407216K(478416K), 0.0243034 secs]
  [GC (Allocation Failure)  476184K->475827K(547292K), 0.0244236 secs]
  [GC (Allocation Failure)  544800K->544439K(616168K), 0.0239879 secs]
  [GC (Allocation Failure)  613414K->613048K(685044K), 0.0247277 secs]
  [GC (Allocation Failure)  682023K->681658K(753920K), 0.0240500 secs]
  [GC (Allocation Failure)  750634K->750269K(822796K), 0.0247381 secs]
  [GC (Allocation Failure)  819245K->818878K(891672K), 0.0238222 secs]
  [GC (Allocation Failure)  887854K->887492K(960548K), 0.0234550 secs]
  [GC (Allocation Failure)  956469K->956099K(1029424K), 0.0230696 secs]
  [GC (Allocation Failure)  1025075K->1024712K(1098300K), 0.0237283 secs]
  [GC (Allocation Failure)  1093688K->1093322K(1167176K), 0.0236438 secs]
  [GC (Allocation Failure)  1162299K->1161933K(1236052K), 0.0238070 secs]
  [GC (Allocation Failure)  1230909K->1230541K(1304928K), 0.0272628 secs]
  [GC (Allocation Failure)  1299518K->1299154K(1373804K), 0.0275917 secs]
  [GC (Allocation Failure)  1368131K->1367765K(1442680K), 0.0260633 secs]
  [GC (Allocation Failure)  1436741K->1436373K(1511556K), 0.0244981 secs]
  [GC (Allocation Failure)  1505725K->1504002K(1579404K), 0.0236924 secs]
  [GC (Allocation Failure)  1573344K->1571750K(1647252K), 0.0233235 secs]
  [GC (Allocation Failure)  1641166K->1640447K(1716128K), 0.0271724 secs]
  [GC (CMS Final Remark)  1701812K(1716128K), 0.0040128 secs]
  [GC (Allocation Failure)  1710005K->1709143K(1785004K), 0.0312558 secs]
  [GC (Allocation Failure)  1778307K->1777821K(2913312K), 0.0291432 secs]
  [GC (Allocation Failure)  1846788K->1846368K(2913312K), 0.0281520 secs]
  [GC (Allocation Failure)  1915338K->1914963K(2913312K), 0.0246872 secs]
  [GC (CMS Initial Mark)  1915987K(2913312K), 0.0001086 secs]
  [GC (Allocation Failure)  1983936K->1983574K(2913312K), 0.0241278 secs]
  [GC (Allocation Failure)  2052548K->2052184K(2913312K), 0.0262104 secs]
  [GC (Allocation Failure)  2121159K->2120795K(2913312K), 0.0269713 secs]
  [GC (Allocation Failure)  2189770K->2189405K(2913312K), 0.0275171 secs]
  [GC (Allocation Failure)  2258381K->2258014K(2913312K), 0.0276711 secs]
  [GC (Allocation Failure)  2326990K->2326625K(2913312K), 0.0264522 secs]
  [GC (Allocation Failure)  2395601K->2395235K(2913312K), 0.0244709 secs]
  [GC (CMS Final Remark)  2396259K(2913312K), 0.0021075 secs]
  [GC (Allocation Failure)  2464182K->2463817K(3909696K), 0.0278435 secs]
  [GC (Allocation Failure)  2532793K->2532429K(3909696K), 0.0303963 secs]
  [GC (Allocation Failure)  2601406K->2601040K(3909696K), 0.0302705 secs]
  [GC (Allocation Failure)  2670016K->2669648K(3909696K), 0.0320020 secs]
  [GC (Allocation Failure)  2738625K->2738261K(3909696K), 0.0267885 secs]
  [GC (Allocation Failure)  2807238K->2806872K(3909696K), 0.0263661 secs]
  [GC (Allocation Failure)  2875848K->2875480K(3909696K), 0.0273659 secs]
  [GC (Allocation Failure)  2944457K->2944091K(3909696K), 0.0276656 secs]
  [GC (CMS Initial Mark)  2945115K(3909696K), 0.0001246 secs]
  [GC (Allocation Failure)  3013068K->3012701K(3909696K), 0.0281138 secs]
  [GC (Allocation Failure)  3081678K->3081316K(3909696K), 0.0298782 secs]
  [GC (Allocation Failure)  3150293K->3149925K(3909696K), 0.0277309 secs]
  [GC (Allocation Failure)  3218901K->3218533K(3909696K), 0.0268849 secs]
  [GC (Allocation Failure)  3287510K->3287144K(3909696K), 0.0256160 secs]
  [GC (Allocation Failure)  3356121K->3355757K(3909696K), 0.0322203 secs]
  [GC (Allocation Failure)  3424733K->3424367K(3909696K), 0.0307663 secs]
  [GC (Allocation Failure)  3493344K->3492978K(3909696K), 0.0298531 secs]
  [GC (Allocation Failure)  3561954K->3561588K(3909696K), 0.0267539 secs]
  [GC (CMS Final Remark)  3562612K(3909696K), 0.0026871 secs]
  [GC (Allocation Failure)  3630565K->3630197K(3909696K), 0.0262885 secs]
  [GC (Allocation Failure)  3699174K->3698810K(3909696K), 0.0275708 secs]
  [GC (CMS Initial Mark)  3699834K(3909696K), 0.0003198 secs]
  [GC (Allocation Failure)  3767786K->3767420K(3909696K), 0.0294759 secs]
  [GC (Allocation Failure)  3836397K->3901938K(3909696K), 0.0265376 secs]
  [Full GC (Allocation Failure)  3901938K->3836018K(3909696K), 0.6582041 secs]
  [Full GC (Allocation Failure)  4136359K->4136062K(4137728K), 0.0591009 secs]
  [GC (CMS Initial Mark)  4137086K(4137728K), 0.0001600 secs]
  [Full GC (Allocation Failure)  4137330K->4137086K(4137728K), 0.0059986 secs]
  [Full GC (Allocation Failure)  4137086K->4137033K(4137728K), 0.6208778 secs]
  Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
  	at com.ityc.test.demo.HelloGC.main(HelloGC.java:11)
  ```

- java -XX:+PrintFlagsInitial 默认参数值

- java -XX:+PrintFlagsFinal 最终参数值

- java -XX:+PrintFlagsFinal | grep xxx 找到对应的参数

- java -XX:+PrintFlagsFinal -version |grep GC

### （1）GC常用参数

* -Xmn -Xms -Xmx -Xss
  年轻代 最小堆 最大堆 栈空间
* -XX:+UseTLAB
  使用TLAB，默认打开
* -XX:+PrintTLAB
  打印TLAB的使用情况
* -XX:TLABSize
  设置TLAB大小
* -XX:+DisableExplictGC
  System.gc()不管用 ，FGC
* -XX:+PrintGC
* -XX:+PrintGCDetails
* -XX:+PrintHeapAtGC
* -XX:+PrintGCTimeStamps
* -XX:+PrintGCApplicationConcurrentTime (低)
  打印应用程序时间
* -XX:+PrintGCApplicationStoppedTime （低）
  打印暂停时长
* -XX:+PrintReferenceGC （重要性低）
  记录回收了多少种不同引用类型的引用
* -verbose:class
  类加载详细过程
* -XX:+PrintVMOptions
* -XX:+PrintFlagsFinal  -XX:+PrintFlagsInitial
  必须会用（可以用管道来查参数）
* -Xloggc:opt/log/gc.log
* -XX:MaxTenuringThreshold
  升代年龄，最大值15
* 锁自旋次数 -XX:PreBlockSpin 热点代码检测参数-XX:CompileThreshold 逃逸分析 标量替换 ... 
  这些不建议设置

### （2）Parallel常用参数

* -XX:SurvivorRatio
* -XX:PreTenureSizeThreshold
  大对象到底多大
* -XX:MaxTenuringThreshold
* -XX:+ParallelGCThreads
  并行收集器的线程数，同样适用于CMS，一般设为和CPU核数相同
* -XX:+UseAdaptiveSizePolicy
  自动选择各区大小比例

### （3）CMS常用参数

* -XX:+UseConcMarkSweepGC
* -XX:ParallelCMSThreads
  CMS线程数量
* -XX:CMSInitiatingOccupancyFraction
  使用多少比例的老年代后开始CMS收集，默认是68%(近似值)，如果频繁发生SerialOld卡顿，应该调小，（频繁CMS回收）
* -XX:+UseCMSCompactAtFullCollection
  在FGC时进行压缩
* -XX:CMSFullGCsBeforeCompaction
  多少次FGC之后进行压缩
* -XX:+CMSClassUnloadingEnabled
* -XX:CMSInitiatingPermOccupancyFraction
  达到什么比例时进行Perm回收
* GCTimeRatio
  设置GC时间占用程序运行时间的百分比
* -XX:MaxGCPauseMillis
  停顿时间，是一个建议时间，GC会尝试用各种手段达到这个时间，比如减小年轻代

### （4）G1常用参数

* -XX:+UseG1GC
* -XX:MaxGCPauseMillis
  建议值，G1会尝试调整Young区的块数来达到这个值
* -XX:GCPauseIntervalMillis
  ？GC的间隔时间
* -XX:+G1HeapRegionSize
  分区大小，建议逐渐增大该值，1 2 4 8 16 32。
  随着size增加，垃圾的存活时间更长，GC间隔更长，但每次GC的时间也会更长
  ZGC做了改进（动态区块大小）
* G1NewSizePercent
  新生代最小比例，默认为5%
* G1MaxNewSizePercent
  新生代最大比例，默认为60%
* GCTimeRatio
  GC时间建议比例，G1会根据这个值调整堆空间
* ConcGCThreads
  线程数量
* InitiatingHeapOccupancyPercent
  启动G1的堆空间占用比例

## 3、PS GC日志详解

每种垃圾回收器的日志格式是不同的！

PS日志格式：

<img src="img\GC日志详解.png" />

heap dump部分：

```java
eden space 5632K, 94% used [0x00000000ff980000,0x00000000ffeb3e28,0x00000000fff00000)
                            后面的内存地址指的是，起始地址，使用空间结束地址，整体空间结束地址
```

<img src="img\GCHeapDump.png" />

total = eden + 1个survivor

# 七、JVM调优

## 1、调优前的基础概念：

- 吞吐量：用户代码时间 /（用户代码执行时间 + 垃圾回收时间）
- 响应时间：STW越短，响应时间越好

所谓调优，首先确定，追求啥？吞吐量优先，还是响应时间优先？还是在满足一定的响应时间的情况下，要求达到多大的吞吐量...

问题：

科学计算，吞吐量。数据挖掘，thrput。吞吐量优先的一般：（PS + PO）

响应时间：网站 GUI API （1.8 G1）

## 2、什么是调优？

1. 根据需求进行JVM规划和预调优
2. 优化运行JVM运行环境（慢，卡顿）
3. 解决JVM运行过程中出现的各种问题(OOM)

## 3、调优，从规划开始

* 调优，从业务场景开始，没有业务场景的调优都是耍流氓

* 无监控（压力测试，能看到结果），不调优

* 步骤：

  1. 熟悉业务场景（没有最好的垃圾回收器，只有最合适的垃圾回收器）
     1. 响应时间、停顿时间 [CMS G1 ZGC] （需要给用户作响应）
     2. 吞吐量 = 用户时间 /( 用户时间 + GC时间) [PS]
  2. 选择回收器组合
  3. 计算内存需求（经验值 1.5G 16G）
  4. 选定CPU（越高越好）
  5. 设定年代大小、升级年龄
  6. 设定日志参数（循环使用5个文件，最大20M）
     1. -Xloggc:/opt/xxx/logs/xxx-xxx-gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=20M -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCCause
     2. 或者每天产生一个日志文件
  7. 观察日志情况

* 案例1：垂直电商，最高每日百万订单，处理订单系统需要什么样的服务器配置？

  > 这个问题比较业余，因为很多不同的服务器配置都能支撑(1.5G 16G)
  >
  > 1小时36w集中时间段， 100个订单/秒，（找一小时内的高峰期，1000订单/秒）
  >
  > 经验值，
  >
  > 非要计算：一个订单产生需要多少内存？512K * 1000 500M内存
  >
  > 专业一点儿问法：要求响应时间100ms
  >
  > 压测！

* 案例2：12306遭遇春节大规模抢票应该如何支撑？

  > 12306应该是中国并发量最大的秒杀网站：
  >
  > 号称并发量100W最高
  >
  > CDN -> LVS -> NGINX -> 业务系统 -> 每台机器1W并发（10K问题） 100台机器
  >
  > 普通电商订单 -> 下单 ->订单系统（IO）减库存 ->等待用户付款
  >
  > 12306的一种可能的模型： 下单 -> 减库存 和 订单(redis kafka) 同时异步进行 ->等付款
  >
  > 减库存最后还会把压力压到一台服务器
  >
  > 可以做分布式本地库存 + 单独服务器做库存均衡
  >
  > 大流量的处理方法：分而治之

* 怎么得到一个事务会消耗多少内存？

  > 1. 弄台机器，看能承受多少TPS？是不是达到目标？扩容或调优，让它达到
  >
  > 2. 用压测来确定

## 4、优化环境

1. 有一个50万PV的资料类网站（从磁盘提取文档到内存）原服务器32位，1.5G
   的堆，用户反馈网站比较缓慢，因此公司决定升级，新的服务器为64位，16G
   的堆内存，结果用户反馈卡顿十分严重，反而比以前效率更低了
   1. 为什么原网站慢?
      很多用户浏览数据，很多数据load到内存，内存不足，频繁GC，STW长，响应时间变慢
   2. 为什么会更卡顿？
      内存越大，FGC时间越长
   3. 咋办？
      PS -> PN + CMS 或者 G1
2. 系统CPU经常100%，如何调优？(面试高频)
   CPU100%那么一定有线程在占用系统资源，
   1. 找出哪个进程cpu高（top）
   2. 该进程中的哪个线程cpu高（top -Hp）
   3. 导出该线程的堆栈 (jstack)
   4. 查找哪个方法（栈帧）消耗时间 (jstack)
   5. 工作线程占比高 | 垃圾回收线程占比高
3. 系统内存飙高，如何查找问题？（面试高频）
   1. 导出堆内存 (jmap)
   2. 分析 (jhat jvisualvm mat jprofiler ... )
4. 如何监控JVM
   1. jstat jvisualvm jprofiler arthas top...

## 5、解决JVM运行中的问题

### （1）一个案例理解常用工具

1. 测试代码（有问题的代码）：

   ```java
   package com.mashibing.jvm.gc;
   
   import java.math.BigDecimal;
   import java.util.ArrayList;
   import java.util.Date;
   import java.util.List;
   import java.util.concurrent.ScheduledThreadPoolExecutor;
   import java.util.concurrent.ThreadPoolExecutor;
   import java.util.concurrent.TimeUnit;
   
   /**
    * 从数据库中读取信用数据，套用模型，并把结果进行记录和传输
    */
   
   public class T15_FullGC_Problem01 {
   
       private static class CardInfo {
           BigDecimal price = new BigDecimal(0.0);
           String name = "张三";
           int age = 5;
           Date birthdate = new Date();
   
           public void m() {}
       }
   
       private static ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(50,
               new ThreadPoolExecutor.DiscardOldestPolicy());
   
       public static void main(String[] args) throws Exception {
           executor.setMaximumPoolSize(50);
   
           for (;;){
               modelFit();
               Thread.sleep(100);
           }
       }
   
       private static void modelFit(){
           List<CardInfo> taskList = getAllCardInfo();
           taskList.forEach(info -> {
               // do something
               executor.scheduleWithFixedDelay(() -> {
                   //do sth with info
                   info.m();
   
               }, 2, 3, TimeUnit.SECONDS);
           });
       }
   
       private static List<CardInfo> getAllCardInfo(){
           List<CardInfo> taskList = new ArrayList<>();
   
           for (int i = 0; i < 100; i++) {
               CardInfo ci = new CardInfo();
               taskList.add(ci);
           }
   
           return taskList;
       }
   }
   
   ```

2. java -Xms200M -Xmx200M -XX:+PrintGC com.mashibing.jvm.gc.T15_FullGC_Problem01

3. 一般是运维团队首先受到报警信息（CPU Memory）

4. top命令观察到问题：内存不断增长 CPU占用率居高不下

5. top -Hp 观察进程中的线程，哪个线程CPU和内存占比高（线程号10进制）

6. jps定位具体java进程（列出所有java进程）
   jstack 定位线程状况，重点关注：WAITING BLOCKED（线程号16进制）
   eg.
   waiting on <0x0000000088ca3310> (a java.lang.Object)
   假如有一个进程中100个线程，很多线程都在waiting on <xx> ，一定要找到是哪个线程持有这把锁
   怎么找？搜索jstack dump的信息，找<xx> ，看哪个线程持有这把锁RUNNABLE
   作业：1：写一个死锁程序，用jstack观察 2 ：写一个程序，一个线程持有锁不释放，其他线程等待

7. 为什么阿里规范里规定，线程的名称（尤其是线程池）都要写有意义的名称
   怎么样自定义线程池里的线程名称？（自定义ThreadFactory）

8. jinfo pid 

9. jstat -gc 动态观察gc情况 / 阅读GC日志发现频繁GC / arthas观察 / jconsole/jvisualVM/ Jprofiler（最好用）
   jstat -gc 4655 500 : 每个500个毫秒打印GC的情况
   如果面试官问你是怎么定位OOM问题的？如果你回答用图形界面（错误）
   1：已经上线的系统不用图形界面用什么？（cmdline arthas）
   2：图形界面到底用在什么地方？测试！测试的时候进行监控！（压测观察）

10. jmap - histo 4655 | head -20，查找有多少对象产生（对在线服务器影响小，可以用）

11. jmap -dump:format=b,file=xxx pid ：（手动导出到文件，执行这个命令对在线系统影响高）

    线上系统，内存特别大，jmap执行期间会对进程产生很大影响，甚至卡顿（电商不适合）
    1：设定了参数HeapDump，OOM的时候会自动产生堆转储文件
    2：<font color='red'>很多服务器备份（高可用），停掉这台服务器对其他服务器不影响</font>
    3：在线定位(一般小点儿公司用不到)

12. java -Xms20M -Xmx20M -XX:+UseParallelGC -XX:+HeapDumpOnOutOfMemoryError com.mashibing.jvm.gc.T15_FullGC_Problem01

13. 使用MAT / jhat /jvisualvm 进行dump文件分析
     https://www.cnblogs.com/baihuitestsoftware/articles/6406271.html 
    jhat -J-mx512M xxx.dump（分析导出文件 jhat -J-max512M 文件名：参数是制定内存大小，指定内存比文件小的话，它会一点一点分析）
    分析后会打印一个地址，可用于浏览器访问：http://192.168.17.11:7000
    拉到最后：找到对应链接
    可以使用OQL查找特定问题对象

14. 找到代码的问题



### （2）jconsole远程连接

远程连接，需要打开JMX

1. 程序启动加入参数：

   > ```shell
   > java -Djava.rmi.server.hostname=192.168.17.11 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=11111 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false XXX
   > ```

2. 如果遭遇 Local host name unknown：XXX的错误，修改/etc/hosts文件，把XXX加入进去

   > ```java
   > 192.168.17.11 basic localhost localhost.localdomain localhost4 localhost4.localdomain4
   > ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
   > ```

3. 关闭linux防火墙（实战中应该打开对应端口）

   > ```shell
   > service iptables stop
   > chkconfig iptables off #永久关闭
   > ```

4. windows上打开 jconsole远程连接 192.168.17.11:11111

### （3）jvisualvm远程连接

 https://www.cnblogs.com/liugh/p/7620336.html （简单做法）

### （4）jprofiler (收费)

### （5）arthas在线排查工具

[官方文档](https://github.com/alibaba/arthas/blob/master/README_CN.md)

* 为什么需要在线排查？
  在生产上我们经常会碰到一些不好排查的问题，例如线程安全问题，用最简单的threaddump或者heapdump不好查到问题原因。为了排查这些问题，有时我们会临时加一些日志，比如在一些关键的函数里打印出入参，然后重新打包发布，如果打了日志还是没找到问题，继续加日志，重新打包发布。对于上线流程复杂而且审核比较严的公司，从改代码到上线需要层层的流转，会大大影响问题排查的进度。 
* jvm观察jvm信息
* thread定位线程问题
* dashboard 观察系统情况
* heapdump（导出） + jhat分析
* jad反编译
  动态代理生成类的问题定位
  第三方的类（观察代码）
  版本问题（确定自己最新提交的版本是不是被使用）
* redefine 热替换（实现：classLoad 的 redefine方法）
  目前有些限制条件：只能改方法实现（方法已经运行完成），不能改方法名， 不能改属性
  m() -> mm()
* sc  - search class
* watch  - watch method
* 没有包含的功能：jmap
* jvm查看信息



# 八、OOM案例汇总

OOM产生的原因多种多样，有些程序未必产生OOM，不断FGC(CPU飙高，但内存回收特别少) （上面案例）

1. 硬件升级系统反而卡顿的问题（见上）

2. 线程池不当运用产生OOM问题（见上）
   不断的往List里加对象（实在太LOW）

3. smile jira问题
   实际系统不断重启
   解决问题 加内存 + 更换垃圾回收器 G1
   真正问题在哪儿？不知道

4. tomcat server.http-header-size过大问题（Hector）

5. lambda表达式导致方法区溢出问题(MethodArea / Perm Metaspace)
   LambdaGC.java     -XX:MaxMetaspaceSize=9M -XX:+PrintGCDetails

   ```java
   "C:\Program Files\Java\jdk1.8.0_181\bin\java.exe" -XX:MaxMetaspaceSize=9M -XX:+PrintGCDetails "-javaagent:C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2019.1\lib\idea_rt.jar=49316:C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2019.1\bin" -Dfile.encoding=UTF-8 -classpath "C:\Program Files\Java\jdk1.8.0_181\jre\lib\charsets.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\deploy.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\access-bridge-64.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\cldrdata.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\dnsns.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\jaccess.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\jfxrt.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\localedata.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\nashorn.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunec.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunjce_provider.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunmscapi.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\sunpkcs11.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\ext\zipfs.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\javaws.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jce.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jfr.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jfxswt.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\jsse.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\management-agent.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\plugin.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\resources.jar;C:\Program Files\Java\jdk1.8.0_181\jre\lib\rt.jar;C:\work\ijprojects\JVM\out\production\JVM;C:\work\ijprojects\ObjectSize\out\artifacts\ObjectSize_jar\ObjectSize.jar" com.mashibing.jvm.gc.LambdaGC
   [GC (Metadata GC Threshold) [PSYoungGen: 11341K->1880K(38400K)] 11341K->1888K(125952K), 0.0022190 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
   [Full GC (Metadata GC Threshold) [PSYoungGen: 1880K->0K(38400K)] [ParOldGen: 8K->1777K(35328K)] 1888K->1777K(73728K), [Metaspace: 8164K->8164K(1056768K)], 0.0100681 secs] [Times: user=0.02 sys=0.00, real=0.01 secs] 
   [GC (Last ditch collection) [PSYoungGen: 0K->0K(38400K)] 1777K->1777K(73728K), 0.0005698 secs] [Times: user=0.00 sys=0.00, real=0.00 secs] 
   [Full GC (Last ditch collection) [PSYoungGen: 0K->0K(38400K)] [ParOldGen: 1777K->1629K(67584K)] 1777K->1629K(105984K), [Metaspace: 8164K->8156K(1056768K)], 0.0124299 secs] [Times: user=0.06 sys=0.00, real=0.01 secs] 
   java.lang.reflect.InvocationTargetException
   	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
   	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
   	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
   	at java.lang.reflect.Method.invoke(Method.java:498)
   	at sun.instrument.InstrumentationImpl.loadClassAndStartAgent(InstrumentationImpl.java:388)
   	at sun.instrument.InstrumentationImpl.loadClassAndCallAgentmain(InstrumentationImpl.java:411)
   Caused by: java.lang.OutOfMemoryError: Compressed class space
   	at sun.misc.Unsafe.defineClass(Native Method)
   	at sun.reflect.ClassDefiner.defineClass(ClassDefiner.java:63)
   	at sun.reflect.MethodAccessorGenerator$1.run(MethodAccessorGenerator.java:399)
   	at sun.reflect.MethodAccessorGenerator$1.run(MethodAccessorGenerator.java:394)
   	at java.security.AccessController.doPrivileged(Native Method)
   	at sun.reflect.MethodAccessorGenerator.generate(MethodAccessorGenerator.java:393)
   	at sun.reflect.MethodAccessorGenerator.generateSerializationConstructor(MethodAccessorGenerator.java:112)
   	at sun.reflect.ReflectionFactory.generateConstructor(ReflectionFactory.java:398)
   	at sun.reflect.ReflectionFactory.newConstructorForSerialization(ReflectionFactory.java:360)
   	at java.io.ObjectStreamClass.getSerializableConstructor(ObjectStreamClass.java:1574)
   	at java.io.ObjectStreamClass.access$1500(ObjectStreamClass.java:79)
   	at java.io.ObjectStreamClass$3.run(ObjectStreamClass.java:519)
   	at java.io.ObjectStreamClass$3.run(ObjectStreamClass.java:494)
   	at java.security.AccessController.doPrivileged(Native Method)
   	at java.io.ObjectStreamClass.<init>(ObjectStreamClass.java:494)
   	at java.io.ObjectStreamClass.lookup(ObjectStreamClass.java:391)
   	at java.io.ObjectOutputStream.writeObject0(ObjectOutputStream.java:1134)
   	at java.io.ObjectOutputStream.defaultWriteFields(ObjectOutputStream.java:1548)
   	at java.io.ObjectOutputStream.writeSerialData(ObjectOutputStream.java:1509)
   	at java.io.ObjectOutputStream.writeOrdinaryObject(ObjectOutputStream.java:1432)
   	at java.io.ObjectOutputStream.writeObject0(ObjectOutputStream.java:1178)
   	at java.io.ObjectOutputStream.writeObject(ObjectOutputStream.java:348)
   	at javax.management.remote.rmi.RMIConnectorServer.encodeJRMPStub(RMIConnectorServer.java:727)
   	at javax.management.remote.rmi.RMIConnectorServer.encodeStub(RMIConnectorServer.java:719)
   	at javax.management.remote.rmi.RMIConnectorServer.encodeStubInAddress(RMIConnectorServer.java:690)
   	at javax.management.remote.rmi.RMIConnectorServer.start(RMIConnectorServer.java:439)
   	at sun.management.jmxremote.ConnectorBootstrap.startLocalConnectorServer(ConnectorBootstrap.java:550)
   	at sun.management.Agent.startLocalManagementAgent(Agent.java:137)
   
   ```

6. 直接内存溢出问题（少见）
   《深入理解Java虚拟机》P59，使用Unsafe分配直接内存，或者使用NIO的问题

7. 栈溢出问题
   -Xss设定太小

8. 比较一下这两段程序的异同，分析哪一个是更优的写法：

   ```java 
   Object o = null;
   for(int i=0; i<100; i++) {
       o = new Object();
       //业务处理
   }
   ```

   ```java
   for(int i=0; i<100; i++) {
       Object o = new Object();
   }
   ```

9. 重写finalize引发频繁GC
   小米云，HBase同步系统，系统通过nginx访问超时报警，最后排查，C++程序员重写finalize引发频繁GC问题
   为什么C++程序员会重写finalize？（new delete）
   finalize耗时比较长（200ms）

10. 如果有一个系统，内存一直消耗不超过10%，但是观察GC日志，发现FGC总是频繁产生，会是什么引起的？
    System.gc() (这个比较Low)

11. Distuptor有个可以设置链的长度，如果过大，然后对象大，消费完不主动释放，会溢出 (来自 死物风情)

12. 用jvm都会溢出，mycat用崩过，1.6.5某个临时版本解析sql子查询算法有问题，9个exists的联合sql就导致生成几百万的对象（来自 死物风情）

13. new 大量线程，会产生 native thread OOM，（low）应该用线程池，
    解决方案：减少堆空间（太TMlow了）,预留更多内存产生native thread
    JVM内存占物理内存比例 50% - 80%

# 九、纤程（协程）

<img src="img\纤程.png" />

在linux中，线程切换发生在内核空间（重量级）；纤程切换发生在用户空间（切换起来相对轻松）；一个线程打开要1M，操作系统是开不了多少线程，比如开1万个线程，可能会非常慢，大量时间花在了切换线程上；纤程则可以启几万个

直到JDK13也没有官方支持纤程，所以要用纤程得用第三方库，如：quasar（该类库不是很成熟）。go、python语言支持

**quasar使用**

maven导入：

```xml
<!-- https://mvnrepository.com/artifact/co.paralleluniverse/quasar-core -->
<dependency>
    <groupId>co.paralleluniverse</groupId>
    <artifactId>quasar-core</artifactId>
    <version>0.8.0</version>
</dependency>
```

​	启1万个纤程（可以启一万个线程做对比执行时间）

```java
for(int i = 0; i < 10000; i++){
    Fiber<Void> fiber = new Fiber<Void>(new SuspendableRunnable(){
        public void run() throws SuspendExecution, InterruptedException{
            calc();//自定义的计算逻辑
        }
    });//Void表示没有返回值
    fiber.start();
}
```

启动时设置-javaagent（class加载如JVM中间agent做了处理，为每个agent做了一个栈来维护）





# 十、面试题

## 1、某厂面试

1. 请解释一下对象的创建过程？

2. 对象在内存中的存储布局？

3. 对象头具体包含什么？

4. 对象怎么定位？https://blog.csdn.net/clover_lily/article/details/80095580

   （1）句柄池

   （2）直接指针（Hotspot）

5. 对象怎么分配？（GC相关内容）

6. Object o = new Object()在内存中占用多少字符？（16个字节）

默认开启压缩classpoint；最终大小为8的倍数

## 2、思考题

1. -XX:MaxTenuringThreshold控制的是什么？
   A: 对象升入老年代的年龄
     	B: 老年代触发FGC时的内存垃圾比例

2. 生产环境中，倾向于将最大堆内存和最小堆内存设置为：（为什么？）
   A: 相同 B：不同

3. JDK1.8默认的垃圾回收器是：
   A: ParNew + CMS
     	B: G1
     	C: PS + ParallelOld
     	D: 以上都不是

4. 什么是响应时间优先？

5. 什么是吞吐量优先？

6. ParNew和PS的区别是什么？

7. ParNew和ParallelOld的区别是什么？（年代不同，算法不同）

8. 长时间计算的场景应该选择：A：停顿时间 B: 吞吐量

9. 大规模电商网站应该选择：A：停顿时间 B: 吞吐量

10. HotSpot的垃圾收集器最常用有哪些？

11. 常见的HotSpot垃圾收集器组合有哪些？

12. JDK1.7 1.8 1.9的默认垃圾回收器是什么？如何查看？

13. 所谓调优，到底是在调什么？

14. 如果采用PS + ParrallelOld组合，怎么做才能让系统基本不产生FGC

15. 如果采用ParNew + CMS组合，怎样做才能够让系统基本不产生FGC

     1.加大JVM内存

     2.加大Young的比例

     3.提高Y-O的年龄

     4.提高S区比例

     5.避免代码内存泄漏

16. G1是否分代？G1垃圾回收器会产生FGC吗？

17. 如果G1产生FGC，你应该做什么？

        1. 扩内存
        2. 提高CPU性能（回收的快，业务逻辑产生对象的速度固定，垃圾回收越快，内存空间越大）
        3. 降低MixedGC触发的阈值，让MixedGC提早发生（默认是45%）

 18. 问：生产环境中能够随随便便的dump吗？
     小堆影响不大，大堆会有服务暂停或卡顿（加live可以缓解），dump前会有FGC

 19. 问：常见的OOM问题有哪些？
     栈 堆 MethodArea 直接内存

# 十一、参考资料

1. [https://blogs.oracle.com/](https://blogs.oracle.com/jonthecollector/our-collectors)[jonthecollector](https://blogs.oracle.com/jonthecollector/our-collectors)[/our-collectors](https://blogs.oracle.com/jonthecollector/our-collectors)
2. https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html
3. http://java.sun.com/javase/technologies/hotspot/vmoptions.jsp
4. JVM调优参考文档：https://docs.oracle.com/en/java/javase/13/gctuning/introduction-garbage-collection-tuning.html#GUID-8A443184-7E07-4B71-9777-4F12947C8184 
5. https://www.cnblogs.com/nxlhero/p/11660854.html 在线排查工具
6. https://www.jianshu.com/p/507f7e0cc3a3 arthas常用命令
7. Arthas手册：
   1. 启动arthas java -jar arthas-boot.jar
   2. 绑定java进程
   3. dashboard命令观察系统整体情况
   4. help 查看帮助
   5. help xx 查看具体命令帮助
8. jmap命令参考： https://www.jianshu.com/p/507f7e0cc3a3 
   1. jmap -heap pid
   2. jmap -histo pid
   3. jmap -clstats pid
