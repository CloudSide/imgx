FROM cloudmario/imgx-base:v1.0.0
MAINTAINER Cloud Mario <smcz@qq.com>

COPY ./imgx /imgx

RUN mkdir -p /imgx/cache

# magick_type
RUN cd /imgx/c/magicktype && \
  gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC && \
  mv libmagicktype.so /usr/local/lib/ && \
  ldconfig /usr/local/lib && \
  cd /usr/local/src

# download fonts files
RUN cd /imgx/src/lib/data && \
  rm -rf fonts* && \
  wget -O fonts.zip "http://cdn.sinacloud.net/hehe/imgx/fonts.zip" && \
  unzip fonts.zip && \
  rm -rf fonts.zip

ENV TZ "Asia/Shanghai"
ENV IMGX_VERSION 0.9.0

# Users
RUN groupadd imgx
RUN useradd -g imgx imgx
RUN chown imgx -R /imgx/cache

EXPOSE 80

RUN chmod +x /imgx/boot

WORKDIR /imgx

CMD ["./boot"]
