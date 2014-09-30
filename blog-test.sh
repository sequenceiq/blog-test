#!/bin/bash
cat <<EOF

============================
blog generation started ...
be pateinet it takes about 20 sec
red warnings are ok
if finished browser will open:

  http://192.168.59.103:${BLOG_PORT}
============================

EOF

: ${BLOG_PORT:=8080}
export BLOG_PORT

# stop previous blog contaier
docker rm -f  blog-test &> /dev/null

docker build -t blog-test-image . \
 && docker run -d --name blog-test -p ${BLOG_PORT}:8080 blog-test-image \
 && open http://192.168.59.103:${BLOG_PORT}

cat <<EOF

========================================================
to clean up the container, and the image:

  docker rm -f blog-test && docker rmi blog-test-image
========================================================
