FROM daocloud.io/cloudmario/imgx-base
MAINTAINER Cloud Mario <smcz@qq.com>

ADD ./imgx /imgx

RUN mkdir -p /imgx/cache

# magick_type
RUN cd /imgx/c/magicktype && \
  gcc -shared magicktype.c -o libmagicktype.so `freetype-config --cflags --libs` -fPIC && \
  mv libmagicktype.so /usr/local/lib/ && \
  ldconfig /usr/local/lib && \
  cd /usr/local/src

ENV TZ "Asia/Shanghai"
ENV IMGX_VERSION 0.9.0

# Users
RUN groupadd imgx
RUN useradd -g imgx imgx
RUN chown imgx -R /imgx/cache

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /imgx/logs/access.log \
  && ln -sf /dev/stderr /imgx/logs/error.log

EXPOSE 80

RUN chmod +x /imgx/boot

CMD ["/imgx/boot"]
