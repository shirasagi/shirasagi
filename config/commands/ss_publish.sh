#!/bin/sh
#
# ss_publish.sh
#
# Description:
#   第二引数(PAR_PATH)のフォルダ、ファイルを転送するスクリプト
#   第一引数(PAR_CMD)が page ならば scp を使用する
#   第一引数が site, folder ならば rsync を使用する
#
# Usage:
#   ss_publish.sh site /var/www/shirasagi/public/sites/w/w/w/_
#   ss_publish.sh page /var/www/shirasagi/public/sites/w/w/w/_/docs/page1.html
#
##############################################################################

PATH=$PATH:/usr/bin:/bin
PAR_CMD=${1:-"site"}
PAR_PATH=${2:-""}
PAR_PATH=`echo \$PAR_PATH | tr "A-Z" "a-z"`
cat << EOS
PAR_CMD=$PAR_CMD
PAR_PATH=$PAR_PATH

#!/bin/sh

## Env.
# Shirasagi
SS_DIR="/var/www/shirasagi"
# Rsync Remote
REMOTE_USR="root"
REMOTE_SVR="0.0.0.0"
# Rsync/scp option
SCP_OPT=""
RSYNC_OPT="-az --delete"

## Param check
if [ \$# -ne 2 ]; then
  echo "Usage: ss_publish.sh [site|folder|page] [dir|file]" 1>&2
  exit 1
fi

PAR_CMD=\${1:-"site"}
PAR_PATH=\${2:-""}
PAR_PATH=\`echo \$PAR_PATH | tr "A-Z" "a-z"\`
if [ \$PAR_CMD != "site" -a \$PAR_CMD != "folder" -a \$PAR_CMD != "page" ]; then
  echo "Param1 Error! [site|folder|page]" 1>&2
  exit 1
fi

## Make from path
if [[ \$PAR_PATH =~ ^\$SS_DIR ]]; then
  SYNC_PATH=\$PAR_PATH
else
  SYNC_PATH=\$SS_DIR/\$PAR_PATH
fi

## Check from path
if [ \$PAR_CMD == "page" ]; then
  if [ ! -f \$SYNC_PATH ]; then
    echo "file not exist! ["\$SYNC_PATH"]" 1>&2
    exit 1
  fi
else
  SYNC_PATH=\`echo \${SYNC_PATH%/}\`
  if [ ! -d \$SYNC_PATH ]; then
    echo "directory not exist! ["\$SYNC_PATH"]" 1>&2
    exit 1
  fi
fi

## Sync to Remote
if [ \$PAR_CMD == "page" ]; then
  scp \$SCP_OPT \$SYNC_PATH \$REMOTE_USR@\$REMOTE_SVR:\$SYNC_PATH
else
  rsync \$RSYNC_OPT \$SYNC_PATH/ \$REMOTE_USR@\$REMOTE_SVR:\$SYNC_PATH
fi

exit 0
EOS

exit 0
