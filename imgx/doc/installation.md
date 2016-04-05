SinaImgx部署文档：
-----

### 下载、安装openresty：

```sh
cd /user/local/src
wget "http://openresty.org/download/ngx_openresty-1.7.4.1.tar.gz"
tar zxvf ngx_openresty-1.7.4.1.tar.gz
cd ngx_openresty-1.7.4.1
yum install readline-devel pcre-devel openssl-devel gcc libdrizzle-devel postgresql-devel
./configure --with-luajit --with-http_drizzle_module --with-http_postgres_module --with-http_iconv_module
make -j2
make install
```

### 安装ImageMagic：

```sh
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm (卸载：rpm -e remi-release)
yum remove ImageMagick*
yum install ImageMagick-last* --enablerepo=remi
```

### 安装memcached:

```sh
yum install memcache*
#修改最大连接数和最大内存
/etc/init.d/memcached start
```

### 创建lua脚本：

```sh
mkdir /data1
cd /
chmod -R data1
cd data1
svn co "https://svn1.intra.sina.com.cn/scs/sinaimgx/"
cd sinaimgx
./service.sh start
```

### MagickType
```sh
gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC
```
