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

: ${DIRTY:=false}
: ${BLOG_PORT:=8080}
export BLOG_PORT

if [[ $1 =~ -d ]]; then
  echo '[WARNING] you are testing uncommited changes !'
else
  echo [INFO] stashing away uncommited changes and untracked files
  git stash save -u "before blog generation"
fi

# stop previous blog contaier
docker rm -f  blog-test &> /dev/null

docker build -t blog-test-image . \
 && docker run -d --name blog-test -p ${BLOG_PORT}:8080 blog-test-image \
 && open http://192.168.59.103:${BLOG_PORT}

if [[ $1 =~ -d ]]; then
  echo '[WARNING] Please remember to commit you changes'
else
  echo [INFO] Move uncommited changes and untracked files back to WORKDIR
  git stash pop
fi

cat <<EOF

========================================================
to clean up the container, and the image:

  docker rm -f blog-test && docker rmi blog-test-image
========================================================
