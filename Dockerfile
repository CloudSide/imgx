FROM cloudmario/imgx-base
MAINTAINER Cloud Mario <smcz@qq.com>

ADD ./imgx /data/imgx

# magick_type
RUN cd /data/imgx/c/magicktype && \
  gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC && \
  mv libmagicktype.so /usr/local/lib/ && \
  ldconfig /usr/local/lib && \
  cd /usr/local/src

ENV TZ "Asia/Shanghai"
ENV IMGX_VERSION 0.9.0

# Users
groupadd imgx
useradd -g imgx imgx
chown imgx -R /data/imgx/cache
