#!/bin/sh
# chkconfig: - 85 35
# description: Unicorn

# rvm wrapper 2.1.2 start unicorn => /usr/local/rvm/bin/start_unicorn
export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

APPS=()
APPS=("${APPS[@]}" "/var/www/shirasagi")

for APP in ${APPS[@]}; do
  NAME="Unicorn"
  ENV="production"
  PID="${APP}/tmp/pids/unicorn.pid"
  CONF="${APP}/config/unicorn.rb"
  
  start()
  {
    if [ -e $PID ]; then
      echo "$NAME already started"
      exit 1
    fi
    echo "start $NAME"
    cd $APP
    /usr/local/rvm/bin/start_unicorn -c ${CONF} -E ${ENV} -D
  }
  
  stop()
  {
    if [ ! -e $PID ]; then
      echo "$NAME not started"
      exit 1
    fi
    echo "stop $NAME"
    kill -QUIT `cat ${PID}`
  }
  
  force_stop()
  {
    if [ ! -e $PID ]; then
      echo "$NAME not started"
      exit 1
    fi
    echo "stop $NAME"
    kill -INT `cat ${PID}`
  }
  
  reload()
  {
    if [ ! -e $PID ]; then
      echo "$NAME not started"
      start
      exit 0
    fi
    echo "reload $NAME"
    kill -HUP `cat ${PID}`
  }
  
  restart()
  {
    stop
    sleep 3
    start
  }
  
  case "$1" in
    start)
      start
      ;;
    stop)
      stop
      ;;
    force-stop)
      force_stop
      ;;
    reload)
      reload
      ;;
    restart)
      restart
      ;;
    *)
      echo "Syntax Error: release [start|stop|force-stop|reload|restart]"
      ;;
  esac
done
