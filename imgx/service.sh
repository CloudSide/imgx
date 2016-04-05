#!/bin/bash

if [ "$(stat -c '%U' cache)" != "sinaimgx" ]; then
	chown sinaimgx -R /data/imgx/cache
fi


mkdir -p logs
#alidns="223.5.5.5 223.6.6.6 "
alidns=""
echo resolver $alidns $(awk 'BEGIN{ORS=" "} /nameserver/{print $2}' /etc/resolv.conf | sed "s/ $/;/g") > conf/resolvers.conf
#mkdir -p process
#touch logs/error.log
#mkdir -p cache

ngx_bin="/usr/local/openresty/nginx/sbin/nginx"
ngx_conf="conf/nginx.conf"

start() {
	$ngx_bin -p "$(pwd)" -c $ngx_conf
}

stop() {
	$ngx_bin -p "$(pwd)" -c $ngx_conf -s stop
}

reopen() {
	$ngx_bin -p "$(pwd)" -c $ngx_conf -s reopen
}

reload() {
	$ngx_bin -p "$(pwd)" -c $ngx_conf -s reload
}

restart() {
	stop
	start
}

docker_start() {
	stop
	start
	while [ 1 ]
	do
		sleep 4h
		rm -f logs/access.log.1 logs/error.log.1
		mv logs/access.log logs/access.log.1
		mv logs/error.log logs/error.log.1
		reopen
		#kill -USR1 $(cat logs/nginx.pid)
	done
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	reload)
		reload
		;;
	reopen)
		reopen
		;;
	restart)
		restart
		;;
	docker_start)
		docker_start
		;;
	*)
	echo $"Usage: $0 {start|stop|restart|reload|reopen|docker_start}"
esac
