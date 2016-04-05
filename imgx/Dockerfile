#停止所有container:
#docker stop $(docker ps -a -q)
#----------------------------------
#删除所有container
#docker rm $(docker ps -a -q)
#----------------------------------
#要删除全部image的话
#docker rmi $(docker images -q)
#----------------------------------
#删除images，通过image的id来指定删除谁
#docker rmi <image id>
#----------------------------------
#想要删除untagged images，也就是那些id为<None>的image的话可以用
#docker rmi $(docker images | grep "^<none>" | awk "{print $3}")
#----------------------------------
#提交镜像
#docker commit -m "add libluafs" -a "cloudmario" 712591c554f4 cloudmario/sinaimgx
#----------------------------------
#启动服务
#docker run --name=sinaimgx -d --privileged --net=host -p 80:80 -p 8080:8080 -p 443:443 -e TZ='Asia/Shanghai' -v /data1/sinaimgx/:/data1/sinaimgx/ cloudmario/sinaimgx /bin/bash -c 'cd /data1/sinaimgx/ && ./service.sh docker_start'
#docker run --name=dipscribe -d --privileged --net=host -v /data1/:/data1/ -e TZ='Asia/Shanghai' --env LOCAL_ADDR=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | cut -f2 -d ":"` cloudmario/dipscribe /bin/bash -c 'cd /data1/sinaimgx/ && sh tools/dip_config.sh && sh tools/dip_docker_start.sh'
#----------------------------------
#配置服务
#docker run -i -t --privileged --net=host -p 80:80 -p 8080:8080 -p 443:443 -v /data1/sinaimgx/:/data1/sinaimgx/ cloudmario/sinaimgx /bin/bash
#docker run -it --privileged --net=host -v /data1/:/data1/ --env LOCAL_ADDR=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | cut -f2 -d ":"` cloudmario/dipscribe /bin/bash
#
#初始化安装
yum -y update
yum clean all
yum -y install epel-release.noarch
rpm -Uvh "http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
yum -y install readline-devel pcre-devel openssl-devel gcc postgresql-devel vim wget tar zip unzip make ctags pkgconfig gtk2-devel cmake lua lua-devel jasper* fftw* giflib* texlive-dvipng.noarch
#rpm -Uvh "http://dl.fedoraproject.org/pub/epel/6/x86_64/libdrizzle-0.8-6.el6.x86_64.rpm"
#rpm -Uvh "http://dl.fedoraproject.org/pub/epel/6/x86_64/libdrizzle-devel-0.8-6.el6.x86_64.rpm"
rpm -Uvh "http://mirrors.karan.org/epel7/Packages/libdrizzle/20131231005344/0.8-6.el6.x86_64/libdrizzle-0.8-6.el7.x86_64.rpm"
rpm -Uvh "http://mirrors.karan.org/epel7/Packages/libdrizzle/20131231005344/0.8-6.el6.x86_64/libdrizzle-devel-0.8-6.el7.x86_64.rpm"
yum -y group install "Development Tools"
#安装ImageMagick
yum -y remove ImageMagick*
yum clean all
yum -y install ImageMagick-last* --enablerepo=remi
#
#yum -y remove ImageMagick-last*
#cd /usr/local/src
#wget "http://www.imagemagick.org/download/ImageMagick.tar.gz"
#tar zxvf ImageMagick.tar.gz
#cd ImageMagick-6.9.0-0
#./configure --with-jp2=yes --enable-hdri=yes --with-autotrace=yes
#make
#make install
#ldconfig /usr/local/lib
#
#安装openresty
cd /usr/local/src
wget "http://openresty.org/download/ngx_openresty-1.7.7.2.tar.gz"
tar zxvf ngx_openresty-1.7.7.2.tar.gz
cd ngx_openresty-1.7.7.2
./configure --with-luajit --with-http_drizzle_module --with-http_postgres_module --with-http_iconv_module
make -j2
make install
#安装luarocks
cd /usr/local/src
wget "http://luarocks.org/releases/luarocks-2.2.0.tar.gz"
tar zxvf luarocks-2.2.0.tar.gz
cd luarocks-2.2.0
./configure --prefix=/usr/local/openresty/luajit \
	--with-lua=/usr/local/openresty/luajit/ \
	--lua-suffix=jit-2.1.0-alpha \
	--with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make build
make install
#安装opencv
cd /usr/local/src
#wget -O opencv-master.zip "https://github.com/Itseez/opencv/archive/master.zip"
wget -O opencv-3.0.0-beta.zip "https://github.com/Itseez/opencv/archive/3.0.0-beta.zip"
#unzip opencv-master.zip
unzip opencv-3.0.0-beta.zip
#cd opencv-master
cd opencv-3.0.0-beta
mkdir release
cd release
cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local ..
make -j2
make install
echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf
echo "export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" >> /etc/bashrc
source /etc/bashrc
ldconfig /usr/local/lib
#安装libluafs
cd /data1/sinaimgx/c/libluafs
#wget "http://sdk.sinacloud.net/lua/libluafs.zip"
#unzip libluafs.zip
#cd libluafs
make
mv libluafs.so /usr/local/openresty/lualib/
cd /usr/local/src
#编译magick_type
cd /data1/sinaimgx/c/magicktype
gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC
mv libmagicktype.so /usr/local/lib/
ldconfig /usr/local/lib
cd /usr/local/src
#设置时区
echo "export TZ='Asia/Shanghai'" >> /etc/bashrc && source /etc/bashrc
echo "export TZ='Asia/Shanghai'" >> /etc/profile && source /etc/profile
#创建用户
groupadd sinaimgx
useradd -g sinaimgx sinaimgx
#给cache目录设置权限
chown sinaimgx -R /data1/sinaimgx/cache

#
# accesskey,sip,sport,an,domain,cip,time,hitinfo,createtime,timezone,httpmethod,request_uri,httptype,httpcode,bytes_down,refer,cookie,useragent,server_port,requestid,bucket_name
# ^_accesskey=([^=]*)&_ip=([^=]*)&_port=([^=]*)&_an=([^=]*)&_data=([^\s]*) ([^\s]*) ([^\s]*) ([^\s]*) \[([^\s]*) ([^\s]*)\] "([^\s]*) ([^\s]*) ([^\s]*)" ([^\s]*) ([^\s]*) ([^\s]*) [^\s]* (".*") (".*") ([^\s]*) ([^\s]*) ([^\s]*)$
#
