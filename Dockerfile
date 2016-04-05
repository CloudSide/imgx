FROM centos:7
MAINTAINER Cloud Mario <smcz@qq.com>

# Base
RUN yum -y update
RUN yum clean all
RUN yum -y install epel-release.noarch
RUN rpm -Uvh "http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
RUN yum -y install readline-devel pcre-devel openssl-devel gcc wget tar zip unzip make ctags pkgconfig gtk2-devel cmake lua lua-devel jasper* fftw* giflib* texlive-dvipng.noarch
RUN yum -y group install "Development Tools"

# ImageMagick
RUN yum -y remove ImageMagick*
RUN yum clean all
RUN yum -y install ImageMagick-last* --enablerepo=remi

# openresty
RUN cd /usr/local/src && \
  wget "https://openresty.org/download/openresty-1.9.7.4.tar.gz" && \
  tar zxvf openresty-1.9.7.4.tar.gz && \
  cd openresty-1.9.7.4 && \
  ./configure --with-luajit --with-http_iconv_module && \
  make -j2 && \
  make install && \
  cd /usr/local/src && \
  rm -rf openresty-1.9.7.4*

# luarocks
RUN cd /usr/local/src && \
  wget "http://luarocks.org/releases/luarocks-2.3.0.tar.gz" && \
  tar zxvf luarocks-2.3.0.tar.gz && \
  cd luarocks-2.3.0 && \
  ./configure --prefix=/usr/local/openresty/luajit \
  --with-lua=/usr/local/openresty/luajit/ \
  --lua-suffix=jit-2.1.0-beta1 \
  --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 && \
  make build && \
  make install && \
  cd /usr/local/src && \
  rm -rf luarocks-2.3.0*

# opencv
RUN cd /usr/local/src && \
  wget -O opencv-3.1.0.zip "https://github.com/Itseez/opencv/archive/3.1.0.zip" && \
  unzip opencv-3.1.0.zip && \
  cd opencv-3.1.0 && \
  mkdir release && \
  cd release && \
  cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
  make -j2 && \
  make install && \
  echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf && \
  echo "export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" >> /etc/bashrc && \
  source /etc/bashrc && \
  ldconfig /usr/local/lib && \
  cd /usr/local/src && \
  rm -rf opencv-3.1.0*

# libluafs
RUN cd /usr/local/src && \
  wget -O libluafs-master.zip "https://github.com/CloudSide/libluafs/archive/master.zip" && \
  unzip libluafs-master.zip && \
  cd libluafs-master && \
  make && \
  mv libluafs.so /usr/local/openresty/lualib/ && \
  cd /usr/local/src && \
  rm -rf libluafs-master*


# magick_type
# cd /data1/sinaimgx/c/magicktype
# gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC
# mv libmagicktype.so /usr/local/lib/
# ldconfig /usr/local/lib
# cd /usr/local/src
