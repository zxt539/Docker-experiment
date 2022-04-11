FROM ubuntu
RUN sed -i "s/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade
RUN apt-get install sudo
RUN sudo apt-get update
RUN sudo apt install nginx --fix-missing -y
# update index.nginx-debian.html
RUN sudo apt install curl --fix-missing -y
RUN echo 'Student_id: 18374008' > /var/www/html/index.nginx-debian.html
CMD service nginx start && bash