#!/bin/bash

#docker run -d --privileged --net=host -p 80:80 -p 8080:8080 -p 443:443 -v /data1/sinaimgx/:/data1/sinaimgx/ cloudmario/sinaimgx /bin/sh -c 'cd /data1/sinaimgx/ && ./service.sh docker_start'
docker run -d --privileged --net=host -p 80:80 -p 8080:8080 -p 443:443 -e TZ='Asia/Shanghai' -v /data1/sinaimgx/:/data1/sinaimgx/ cloudmario/sinaimgx /bin/bash -c 'cd /data1/sinaimgx/ && ./service.sh docker_start'
