爬虫能做什么？

- 采集网络数据
- 自动化测试
- 做一些萝莉手动的操作（帮人投票、12306抢票、微信聊天助手-itchat）-有操作浏览器的库去操作浏览器帮我们访问网站
- 灰产（薅羊毛、发动网络攻击、做水军）

# 一、安装和配置virtualenvwrapper和virtualenv

当不同项目用到的python版本、依赖包版本不一致时，可以用虚拟环境隔开。

1、windows下安装

```sql
pip install virtualenvwrapper-win
pip install virtualenv
#新建虚拟环境(建立后会在第一行显示创建的位置，且会默认进入该虚拟环境)
mkvirtualenv -p C:\Python39\python.exe spider
#退出虚拟环境
deactivate
#列出所有虚拟环境
workon
#进入虚拟环境
workon spider
#进入虚拟环境后查看使用的python版本
python
#删除虚拟环境，只要进入Envs目录删除对于的目录即可
```

配置虚拟环境到pycharm:setting->project Interpreter->add，添加已存在的evn

修改虚拟环境保存的位置：添加环境变量WORKON_HOME



2、linux下安装

3、mac下安装

# 二、robots协议

网站的数据并非都可以爬取的，可以爬取的数据都写在网站更目录下的

User-agent：表示爬虫名称

robots.txt文件中，该文件中的Allow表示可以爬取的url

disallow表示不能爬取的路径

