#!/bin/bash

: ${BLOG_PORT:=8080}
cat <<EOF
blog is beeing generated
a browser will automatically
open up after 30sec serving:

============================
 http://192.168.59.103:${BLOG_PORT}
============================

EOF

export BLOG_PORT
(sleep 30; open http://192.168.59.103:${BLOG_PORT}) &

docker build -t delme . && docker run -p ${BLOG_PORT}:8080 delme
