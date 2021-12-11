python一切都是对象，对象的三个特征：id、value、type。

python安装好后，自带一个IDEL shell

```python
>>> print('hello,world')
hello,world
```

# 一、python的基础数据类型

## 1、Number：数字

### （1）int：整数

```python
>>> type(1)
<class 'int'>
```

### （2）float：浮点数

```python
>>> type(1.2)
<class 'float'>
```

### （3）long

python3中没有，python2中有

### （4）bool：布尔类型

**1)bool表示**

首字母必须大写，非零为True，零表示为False

```python
>>> True
True
>>> False
False
>>> true
Traceback (most recent call last):
  File "<pyshell#34>", line 1, in <module>
    true
NameError: name 'true' is not defined
>>> type(False)
<class 'bool'>
```

**2）bool与其他数值类型转换**

```python
>>> int(True)
1
>>> int(False)
0
>>> bool(1)
True
>>> bool(0)
False
>>> bool(2)
True
>>> bool(0xf)
True
```

**3)bool与其他类型之间的应用**

```python
>>> bool('abc')
True
>>> bool('')
False
>>> bool([1,2,3])
True
>>> bool([])
False
>>> bool({1,2,3})
True
>>> bool({})
False
>>> bool(None)
False
```

### （5）xomplex：复数

```python
>>> 36j
36j
```

### （6）浮点数和整数计算

```python
>>> type(1+1.1)
<class 'float'>
>>> type(1+1)
<class 'int'>
>>> type(1+1.0)
<class 'float'>
>>> type(2/2)
<class 'float'>
>>> type(2//2)
<class 'int'>
```

注意，与Java不同的是，整形相除，为浮点类型，若要得到整形用两个除号，两个除号得到的结果只保留整数位

## 2、str：字符串

### （1）字符串表示

表示字符串的方式：单引号，双引号，三引号

```python
>>> 'let\' go'
"let' go"
>>> "let's go"
"let's go"
```

python建议每行代码不超过79个字符，超过就加回车，三引号中可以加回车

```python
>>> '''
hello
hello
helll
'''
'\nhello\nhello\nhelll\n'
>>> """
hello
hello
hello
"""
'\nhello\nhello\nhello\n'
>>> print('hello\nhello\nhello\n')
hello
hello
hello
>>> 'hello\
world'
'helloworld'
>>> print(r'hello\nworld')
hello\nworld
```

字符串前加r（也可大写），表示原始字符串，不会把反斜杠当转移字符串

### （2）字符串操作

字符串可以看做序列

拼接字符串

```python
>>> 'hello'+' world'
'hello world'
>>> 'hello' * 3
'hellohellohello
```

截取单个字符串

```python
>>> 'hello world'[0]
'h'
>>> 'hello world'[2]
'l'
>>> 'hello world'[-1]
'd'
```

截取字符串

**切片**：两个参数都为字符下标，包前不包后

```python
>>> 'hello word'[0:5]
'hello'
>>> 'hello world'[1:-1]
'ello worl'
>>> 'hello world'[6:20]
'world'
>>> 'hello world'[6:]
'world'
>>> 'hello world'[:-6]
'hello'
>>> 'hello world'[:-5]
'hello '
>>> 'hello word'[0:8:2]
'hlow'
```

## 3、序列

### （1）列表的表示

```python
>>> type([1,2,3,4])
<class 'list'>
>>> type(['hello',1,False])
<class 'list'>
>>> type([[1,2,3],[False,True]])
<class 'list'>
```

### （2）列表的操作

```python
>>> ["张飞","刘备","关羽"]+["项羽","刘邦"]
['张飞', '刘备', '关羽', '项羽', '刘邦']
>>> ["项羽","刘邦"]*3
['项羽', '刘邦', '项羽', '刘邦', '项羽', '刘邦']
```

添加元素

```python
>>> a = [1,2,3]
>>> a.append(4)
>>> a
[1, 2, 3, 4]
```

### （3）元组tuple

```python
>>> type((1,2,3))
<class 'tuple'>
>>> (1,"st",True)
(1, 'st', True)
>>> (1,2,3,4)[0]
1
>>> (1,2,3,4)[0:2]
(1, 2)
>>> (1,2,3)+(4,5,6)
(1, 2, 3, 4, 5, 6)
>>> (1,2,3)*3
(1, 2, 3, 1, 2, 3, 1, 2, 3)
```

单个元素的元组表示：

```python
>>> type((1))
<class 'int'>
>>> type(('str'))
<class 'str'>
>>> type((1,))
<class 'tuple'>
>>> type(())
<class 'tuple'>
```

元组是不可改变的，但如果元组的元素有列表，列表中的元素是可以改变的

```python
>>> a = (1,2,3,[1,2,6])
>>> a[3][0] = '9'
>>> print(a)
(1, 2, 3, ['9', 2, 6])
```



### （4）序列的其他操作

判断一个元素是否在一个序列中

```python
>>> 'hello word'[0:8:2]
'hlow'
>>> 3 in[1,2,3,4,5]
True
>>> 10 in[1,2,3,4,5]
False
>>> 3 not in [1,2,3,4,5]
False
```

获得序列的长度

```python
>>> len([1,2,3,4,5])
5
```

获得序列中最大,最小的元素

```python
>>> max([1,3,5])
5
>>> min([1,3,4])
1
>>> max('hello world')
'w'
>>> min('hello world')
' '
```

获得字符的ASCII码

```python
>>> ord('w')
119
>>> ord('a')
97
>>> ord(' ')
32
```

## 4、set：集合 

无序，不重复

set的操作：

```python
>>> {1,2,3,4,5,6} - {1,2}
{3, 4, 5, 6}
>>> {1,2,3,4,5,6} & {3,4}
{3, 4}
>>> {1,2,3,4,5,6} | {3,4,9}
{1, 2, 3, 4, 5, 6, 9}
```



```python
>>> type(set())
<class 'set'>
>>> type({})
<class 'dict'>
```

## 5、dict：字典

key只能为不可变的类型：int、str

字典表示

```python
>>> type({'a':'abc','b':'bcs','c':'cat'})
<class 'dict'
```

操作dict

```python
>>> {'a':'abc','b':'bcs','c':'cat'}['a']
'abc'
```



# 二、各进制的表示和转换

## 1、进制表示

以0b开头为二进制：0b10

```python
>>> 0b10
2
>>> 0b111
7
```

以0o开头为八进制：0o11

```pyton
>>> 0o11
9
```

以ox开头为16进制：ox1F

```python
>>> 0x1f
31
```

## 2、进制转换

自动转换，如上。

（1）转换为二进制：bin()

```python
>>> bin(10)
'0b1010'
>>> bin(0o11)
'0b1001'
>>> bin(0xE)
'0b1110'
```

（2）转换为十进制：int()

```python
>>> int(0b11)
3
>>> int(0o11)
9
>>> int(0x11)
17
```

（3）转换为十六进制：hex()

```python
>>> hex(0b11)
'0x3'
>>> hex(11)
'0xb'
>>> hex(0o11)
'0x9'
```

# 三、变量与运算符

## 1、变量

变量名只能以字母、数字、下划线组成，且不能以数字开头。

变量是没有类型的

```python
>>> a = 1
>>> a = '1'
>>> a = (1,2,3)
```

注意，因为有以下问题，尽量不要使用经常调用的方法的方法名作为变量名

```python
>>> type = 1
>>> type(1)
Traceback (most recent call last):
  File "<pyshell#128>", line 1, in <module>
    type(1)
TypeError: 'int' object is not callable
```

不可改变，值类型：int、str、tuple

可变、引用类型：list、set、dict

id()函数：显示某个变量在内存中的地址

```python
>>> a = "hello"
>>> id(a)
1690057236272
```

## 2、运算符

### （1）算术运算符

python中没有自增、自减运算符

平方

```python
>>> 3**3
27
```

比较运算符：可以比较str，列表、元组

### （2）逻辑运算符

and、or、not（and的优先级大于or，not最大）

```python
>>> not True
False
>>> not False
True
>>> not not False
False
```

#### 1）其他类型与bool类型的转换关系

int、float：0被认为False，非0表示True

```python
>>> bool(0)
False
>>> bool(1.1)
True
```

str：空字符串为False

```python
>>> bool('')
False
>>> bool('0')
True
```

列表（tuple、set、dict）：空列表为False

```python
>>> bool([])
False
>>> bool([1,2])
True
```

#### 2）逻辑运算符与其他类型

not与其他类型之间返回True、False

```python
>>> not '1'
False
>>> not 0
True
```

and：

- 结果为false，返回代表false的值
- 结果为true，返回第二个值（计算机需要读取两个值才能确定结果）

```python
>>> 1 and 0
0
>>> 0 and 1
0
>>> 1 and 2
2
>>> 2 and 1
1
```

or：返回第一个值（or只需要读取一个值就可以确定结果）

```python
>>> 0 or 1
1
>>> 1 or 0
1
>>> 1 or 2
1
>>> 2 or 1
2
```



### （3）成员运算符

in、not in；可用于列表、str、元组、集合、字典（字典判断的是key）

### （4）身份运算符

is、is not

```python
>>> a = 1
>>> b = 2
>>> a is b
False
>>> a = 1
>>> b = 1
>>> a is b
True
>>> a = 'a'
>>> b = 'b'
>>> a is b
False
>>> a = 'a'
>>> b = 'a'
>>> a is b
True
```

==比较的是连个两变量的值是否相等，is比较的是身份（内存地址）是否相等

```python
>>> a = 1
>>> b = 1.0
>>> a is b
False
>>> a == b
True
>>> id(a)
1690038397232
>>> id(b)
1690055617040
```

集合和元组的比较

```python
>>> a = {1,2,3}
>>> b = {2,1,3}
>>> a == b
True
>>> a is b
False
>>> c = (1,2,3)
>>> d = (2,1,3)
>>> c == d
False
>>> c is d
False
```

类型判断，推荐用isinstance，因为type不能判断子类型

```python
>>> a = 'a'
>>> isinstance(a,str)
True
>>> isinstance(a,(int,str,float))
True
```

# 四、语法

在cmd中执行hello.py

```python
python hello.py
```

- 所有字母大写，表示该变量为常量

- :号前不要用空格

- 文件最后加一个空行

- 占位语句pass


```python
if True:
    pass #站位语句
```

## 1、if_else

```python
print("输入数字，得出该数字的平方值")
num = int(input())
print(num ** 2)
if num > 2:
    print("num大于2")
else:
    print("num不大于2")
```

**if_elif_else**

```python
a = 1
if a == 3:
    print("a = 3")
elif a == 2:
    print("a = 2")
else:
    print("a = 1")
```



## 2、while循环

while循环,当条件为false时，执行else中的语句，然后跳出

```python
a = True
while a:
    print('this is tom')
    a = False
else:
    print("EOF")
```

## 3、for循环

for循环、break、continue

**break后不会执行else**

```python
a = ['张飞', '刘备', '关羽', '项羽', '刘邦']
for x in a:
    if x == '张飞':
        continue
    if x == '项羽':
        break
    print(x, end = ' ')
else:
    print("end")
```

## 4、for_range

```python
 # 10是偏移量
for x in range(0,10):
    print(x, end=" ")
else:
    print()

for x in range(0,10,2):
    print(x, end=" ")
else:
    print()


for x in range(10,0,-2):
    print(x,end=" ")
else:
    print()
```

for range练习:打印出[1,2,3,4,5,6,7,8,]中的1,3,5...

```python
a = [1,2,3,4,5,6,7,8]
for i in range(0,8,2):
    print(a[i], end=" ")
else:
    print()
```

