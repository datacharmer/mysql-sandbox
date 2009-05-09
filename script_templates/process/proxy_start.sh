#!_BINBASH_
__LICENSE__

PROXY_BIN=/usr/local/sbin/mysql-proxy
HOST='127.0.0.1'

$PROXY_BIN --proxy-backend-addresses=$HOST:_SERVERPORT_ "$@"


