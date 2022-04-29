# 一、大纲

spring版本：5.2.12

<img src="img\spring- resource-gailan.jpg" />

## 1、概述

### （1）大致流程

- 加载xml
- 解析xml
- 封装BeanDefinition
- 实例化
- 放入容器中
- 从容器中获取



### （2）容器结构（Map）

- key-String	value-Object
- key-Class	value-Object
- key-String	value-ObjectFactory
- key-Strig	value-BeanDefinition

解决循环依赖的方式：三级缓存



修改源码：可以下载spring源码，然后本地编译就可以自己改源码，比如写自己的注释

### （3）重要接口、类

- BeanFactory：bean工厂、整个容器的root接口，也是容器的入口

  - DefaultListableBeanFactory

- BeanDefinition：封装bean定义信息

- BeanDefinitionRegistry：对BeanDefinition信息进行增删改

- Environment接口

  - StandardEnvironment实现类
    - System.getenv()
    - System.getProperties()

- BeanFactoryPostProcessor：修改beanDefinition信息（接口）

  - PlaceholderConfigurerSupport：：实现类，处理占位符

- BeanPostProcessor：修改Bean信息，其中有一个before方法，一个after方法

  - AbstractAutoProxyCreator：实现类，aop的
    - org.springframework.aop.framework.AopProxy#getProxy(java.lang.ClassLoader)：该方法有两个实现，一个cglib，一个jdk（是上面那个类的after方法里的调用）

- Aware接口：实现原理——invokeAwareMethods方法中判断bean类型并set相关的对象

  - ```java
    private void invokeAwareMethods(String beanName, Object bean) {
        if (bean instanceof Aware) {
            if (bean instanceof BeanNameAware) {
                ((BeanNameAware) bean).setBeanName(beanName);
            }
            if (bean instanceof BeanClassLoaderAware) {
                ClassLoader bcl = getBeanClassLoader();
                if (bcl != null) {
                    ((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
                }
            }
            if (bean instanceof BeanFactoryAware) {
                ((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
            }
        }
    }
    ```

  - BeanName：继承Aware接口，可以在对象中获得该bean的id

- FactoryBean

- AbstractApplicationContext

### （4）解析并封装DeanDefinition

bean定义信息可以从xml、json、properties、json等等文件中取出解析到BeanDefinition中，改过程使用BeanDefinitionReader（接口）来解析的，解析xml使用XmlBeanDefinitionReader；解析properties使用PropertiesBeanDefinitionReader。

### （5）实例化（IOC）

spring bean有作用域scope

- singleton（默认单例）
- prototype
- request
- session

使用反射的方式来实例化的



在容器创建过程中动态改变bean的信息：

PostProcessor（后置处理器）：

- BeanFactoryPostProcessor（修改BeanDefinition信息）
- BeanPostProcessor（修改Bean信息）



创建对象（bean的生命周期）：

- 实例化：在堆中开辟一片空间，对象属性值都是默认值
- 初始化：给属性设置值
  - 填充属性(populate)
  - 设置Aware接口属性；
  - BeanPostProcessor.before
  - 执行初始化方法：init method（xml中bean标签有init-method属性，可以指定方法）
  - BeanPostProcessor.after



### （6）例子

#### 1）自定义BeanFactoryPostProcessor

**1、实现BeanFactoryPostProcessor接口**

```java
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;

public class MyBeanFactoryPostProcessor implements BeanFactoryPostProcessor {
    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
        BeanDefinition a = beanFactory.getBeanDefinition("a");

        //这里可以随意设置“a”的懒加载、依赖对象。。。等等

        System.out.println("设置bean a 的DeanDefinition");
    }
}
```

**2、配置resources/tx.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
    <bean id="a" class="com.example.springResource.Service.TestService" >
        <property name="name" value="tom" />
    </bean>
    <bean class="com.example.springResource.MyBeanFactoryPostProcessor"></bean>
</beans>
```

**3、测试**

```java
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class TestMain {

    public static void main(String[] args) {
        ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("tx.xml");
        context.getBean("a");
    }

}
```

**测试结果，控制台输出：**

```
设置bean a 的DeanDefinition
```

#### 2）使用FactoryBean

**1、实现FactoryBean接口**

```java
import com.example.springResource.Service.TestService;
import org.springframework.beans.factory.FactoryBean;

public class TestFactoryBean implements FactoryBean<TestService> {
    @Override
    public TestService getObject() throws Exception {
        return new TestService();
    }

    @Override
    public Class<?> getObjectType() {
        return TestService.class;
    }
}
```

**2、配置resources/tx.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">
    <bean id="TestFactoryBean" class="com.example.springResource.TestFactoryBean" ></bean>
</beans>
```

**3、test**

```java
public class TestMain {

    public static void main(String[] args) {
       ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("tx.xml");
        TestService testService = (TestService) context.getBean("TestFactoryBean");
        System.out.println(testService);

    }

}
```

**4、输出结果：**

```
TestService(name=null, age=null)
```

# 二、debug spring启动流程

入口：

```java
public static void main(String[] args) {
    ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext("tx.xml");
}
```

ClassPathXmlApplicationContext构造方法：

```java
public ClassPathXmlApplicationContext(
    String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
    throws BeansException {
	// 调用父类构造方法，进行相关对象创建等操作
    super(parent);
    //设置xml路径
    setConfigLocations(configLocations);
    if (refresh) {
        //核心流程
        refresh();
    }
}
```

refresh():

```java
@Override
public void refresh() throws BeansException, IllegalStateException {
    synchronized (this.startupShutdownMonitor) {
        // Prepare this context for refreshing.
        /**
         *  做容器刷新前的准备工作
         *  1、设置容器启动时间
         *  2、设置活跃装填
         *  3、设置关闭为false
         *  4、获取Environment对象，并加载到当前系统的属性值到Environment对象中
         *  5、准备监听器和事件集合对象，默认为空的集合
         */
        prepareRefresh();

        // Tell the subclass to refresh the internal bean factory.
        // 创建容器：DefaultListableBeanFactory
        // 并加载配置文件,封装成BeanDefinition，放入BeanFactory
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

        // Prepare the bean factory for use in this context.
        // 初始化BeanFactory，设置一些属性
        prepareBeanFactory(beanFactory);

        try {
            // Allows post-processing of the bean factory in context subclasses.
            // 空方法，用于扩展
            postProcessBeanFactory(beanFactory);

            // Invoke factory processors registered as beans in the context.
            // 执行BeanFactoryPostProcessor
            invokeBeanFactoryPostProcessors(beanFactory);

            // Register bean processors that intercept bean creation.
            // 把BeanPostProcessors设置到BeanFactory中
            registerBeanPostProcessors(beanFactory);

            // Initialize message source for this context.
            // 国际化操作
            initMessageSource();

            // Initialize event multicaster for this context.
            // 初始化广播器
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
            // 空方法
            onRefresh();

            // Check for listener beans and register them.
            // 注册监听器
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
            // 实例化；1、设置类型转换的操作；2、设置占位符；3、设置织入；4、设置冰冻配置；5、实例化所有非懒加载的单例
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
            finishRefresh();
        }

        catch (BeansException ex) {
            if (logger.isWarnEnabled()) {
                logger.warn("Exception encountered during context initialization - " +
                            "cancelling refresh attempt: " + ex);
            }

            // Destroy already created singletons to avoid dangling resources.
            destroyBeans();

            // Reset 'active' flag.
            cancelRefresh(ex);

            // Propagate exception to caller.
            throw ex;
        }

        finally {
            // Reset common introspection caches in Spring's core, since we
            // might not ever need metadata for singleton beans anymore...
            resetCommonCaches();
        }
    }
}
```



循环依赖处理：只能处理set造成的，不能处理构造函数造成的





单独spring项目，只有一个容器，如果是springmvc的就会有父子容器，当再容器中查找bean的时候，首先会在当前容器中查找，找不到再在父容器中查找

AbstractBeanFactory.doGetBean()方法中有

```java
// 获取父类容器
BeanFactory parentBeanFactory = getParentBeanFactory();
```





DefaultListableBeanFactory类图：spring类图如此复杂设计是为了扩展

<img src="img\DefaultListableBeanFactory.png" />

HierarchicalBeanFactory：层级

ListableBeanFactory：可以遍历bean

ConfigurableBeanFactory：有许多配置项可配置





spring容器启动的时候会加锁，保证“refresh"和”destory“是完整不被打断的

Ant表达式

springmvc中 StandardServletEnvironment继承StandardEnvironment

AbstractEnvironment、StandardEnvironment对propertySources的值设置，处理精妙

处理spirng-${abc${abc}}.xml的时候用递归；和解析${jdcb....}是一样的



lookup-method标签 	allowBeanDefinitionOverriding

replaced-method标签	allowCircularReferences



从xml中加载bean信息到BeanFactory的时候，使用了适配器模式XmlBeanDefinitionReader(beanFactory)



idea debug的时候会调用tostring()方法



# 问题：

1、bean生命周期？

2、BeanFactory和FactoryBean的区别？

> 都是用来创建对象的
>
> 当使用BeanFactory的时候必须遵循完整的创建过程，这个过程是由spring来管理控制的
>
> 而使用FactoryBean的时候只需要调用getObject就可以返回具体的对象，整个对象的创建过程是由用户来控制的

3、spring的容器为什么要使用三级缓存？


