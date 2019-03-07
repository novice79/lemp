#!/bin/bash
log () {
    printf "[%(%Y-%m-%d %T)T] %s\n" -1 "$*"
}

cd /workspace/nodejs && npm i 
# sed -i "s@/socket.io@/nodejs/socket.io@" /workspace/nodejs/public/js/index.js
pkg . -t node10-linux -o ../app
cd /workspace/letsencrypt && composer install

rm -- "$0"