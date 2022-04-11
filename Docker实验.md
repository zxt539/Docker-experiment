# 容器与Docker综合实验

> 姓名：周昕潼
>
> 学号：18374008
>
> 班级：192112

## 1. 数据持久化

> **数据持久化**。容器是 **“一次性的”** 和 **“脆弱的”**（请大家务必牢记容器这一特性），容器很容易因为各种原因被kill（如资源不足等等）。而容器产生的数据文件是和容器绑定在一起的，当容器被删除时，这些数据文件也会被删除，这是我们不想看到的。
>
> 比如，我们在机器上启动了一个mysql容器，在写入了一些重要数据后，因为某种原因该容器被意外删除了。此时即使重新启动一个mysql容器也找不会之前的数据了。**请结合实验文档中的内容和查阅相关资料，讨论应该通过何种方式启动容器来避免出现这一问题？你能得出几种方案？每种方案的优劣如何？并请分别使用这些方案模拟mysql容器 创建 - 写入数据 - 销毁 - 重新创建 - 重新读到之前写入的数据 的场景，以证明方案的有效性。**

### 方案1 ：Volume（挂载卷）

- Volumes 是Docker推荐的挂载方式，与把数据存储在容器的可写层相比，使用Volume可以避免增加容器的容量大小，还可以使存储的数据与容器的生命周期独立。本质就是建立容器内路径和本机路径的同步和映射。

#### 操作步骤

- 创建容器。`-v my_volume:/var`目的是创建名为my_volume的volume并且和容器内的`/var`路径挂载。可以通过`docker inspect my_volume`指令查看挂载卷信息

  ![image-20220410085730145](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410085730145.png)

- 启动容器，在`/var`路径写入数据，这里写入的是我的学号，完成后删除容器。

  ![image-20220410085842767](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410085842767.png)

- 打开新的终端，进入sudo模式，查看挂载卷本机路径下的数据，可以看到，即使容器被删除，挂载卷的数据仍然保留。

  ![image-20220410090117784](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410090117784.png)

- 新建容器，命名为`mysql_02`，并挂载`my_volume`数据卷到容器的`/var`路径，运行容器，可以看到之前写入的数据，说明成功保证了数据持久性。

  ![image-20220410090417541](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410090417541.png)



### 方案2 ：bind mount

- Bind mount本质也是挂载主机目录以实现数据持久化，但它和Volume不同的在于是用户自己指定目录，自行管理；而通过Volume创建的挂载卷会统一在`var/lib/docker/volumes/`目录下，由docker管理，且非root用户无法访问和更改该路径下的数据。

#### 操作步骤

- 创建容器，挂载容器中路径` /var/tmp`到本机路径`/tmp`，启动容器，在相应路径下写入数据写入数据，然后退出容器

  ![](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410095702716.png)

- 查看本机目录`/tmp`,可以看到之前在容器中写入的数据。删除容器，再次查看，本机路径下的数据不受影响

  ![image-20220410095908269](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410095908269.png)

- 创建新的容器，挂载本机目录`/tmp`,启动容器，在对应路径下可以看到之前写入的数据，说明达成了数据持久化。

  ![image-20220410100053401](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410100053401.png)



### 方案对比

- Volume方式和Bind Mounts方式我认为没有本质的区别，都是挂载容器目录到主机目录

- 区别：bind mount是挂载主机指定目录，而volume是挂载`/var/lib/docker/volumes/`下的存储卷

- 当要挂载volume时，我们通过`docker volume create my_volume`指令创建名为`my_volume`的volume，此时通过`--mount`和`-v`来挂载，命令写法是不同的(以nginx为例):

  ```
  // --mount
  docker run -d --name devtest --mount source=myvol2,target=/app nginx:latest
  
  // -v(--volume)
  docker run -d --name devtest -v myvol2:/app nginx:latest
  ```

- 当要挂载本机某个路径(bind mount)时，`--mount`和`-v`来挂载，命令写法也是不同的(以nginx为例):

  ```
  // --mount
  docker run -d -it --name devtest --mount type=bind,source="$(pwd)"/target,target=/app nginx:latest
  
  // -v
  docker run -d -it --name devtest -v "$(pwd)"/target:/app nginx:latest
  ```

  - 这种情况下，不仅命令写法不同，还有一个区别是：**如果用户指定的路径不存在，`-v`会默认创建路径，而`--mount`会报错**

- 一些具体区别：

|    对比项    |    bind mount    |          volume          |
| :----------: | :--------------: | :----------------------: |
|  source位置  |     用户指定     | /var/lib/docker/volumes/ |
|  Source种类  |    文件或目录    |        只能是目录        |
|   可移植性   | 一般（自行维护） |    强（由docker管理）    |
| 宿主直接访问 |    可直接访问    |     仅限root用户访问     |



## 2. 构建镜像

请从ubuntu镜像开始，构建一个新的包含Nginx服务的ubuntu镜像，并修改Nginx主页内容为你的学号，**请分别使用`docker commit` 和 `Dockerfile`两种方式完成，** 并将这个新构建的镜像推送到软院的image registry中。这个镜像推送的地址应该是 `harbor.scs.buaa.edu.cn/<你的学号>/ubuntu-nginx:${TAG}`，其中，使用`docker commit`构建的镜像的`TAG`为`dockercommit`；使用`Dockerfile`构建的镜像的`TAG`为 `dockerfile`。



#### 整体思路

- 云平台上Ubuntu换源失败，换成阿里云镜像源也无法执行很多安装指令，遂在本机进行试验。基于wsl2安装docker，然后在docker中拉取Ubuntu镜像，创建容器，安装Nginx，修改默认网页html文件内容，最后通过`docker commit`和`dockerfile`两种方法导出镜像。

#### 具体步骤

##### 1. 拉取Ubuntu镜像，启动容器。换源，这里采用清华镜像源。执行相关初始化命令。

![image-20220410222329741](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410222329741.png)

![image-20220410222412832](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410222412832.png)

##### 2. 安装sudo、nginx、curl

![image-20220410222542659](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410222542659.png)

![image-20220410222633026](C:\Users\Zhouxt\Desktop\2022Spring\大数据和云计算\云计算\image-20220410222633026.png)

##### 3. 编辑nginx默认主页文件的内容为学号，启动nginx，通过curl查看内容

![image-20220410222820772](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410222820772.png)

#### Docker commit

- 指令为`docker commit --change='CMD service nginx start ; sleep infinity' b8ff2ee0e2b1 ubuntu_image_by_dockercommit`，并验证结果

![image-20220411211310441](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220411211310441.png)

#### Dockerfile

- 将之前用到的指令编写成Dockerfile，需要注意的是最后要通过`CMD`语句启动nginx并sleep防止bash进程退出

```dockerfile
# Dockerfile
FROM ubuntu
RUN sed -i "s/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade
RUN apt-get install sudo
RUN sudo apt-get update
RUN sudo apt install nginx --fix-missing -y
RUN sudo apt install curl --fix-missing -y
RUN echo 'Student_id: 18374008' > /var/www/html/index.nginx-debian.html
CMD service nginx start ; sleep infinity
```

- 生成镜像，并用生成的镜像创建容器，验证效果，如图看到nginx主页显示Student_id: 18374008说明成功了！

![image-20220410223322016](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220410223322016.png)

#### Docker push

- 推送镜像到仓库，要先登录

![image-20220411211822918](C:\Users\Zhouxt\AppData\Roaming\Typora\typora-user-images\image-20220411211822918.png)






