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





未完待续。。。。

