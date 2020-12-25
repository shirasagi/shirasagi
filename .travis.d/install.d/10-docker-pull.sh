#!/bin/bash
#
# 2020/11/02 に docker pull に制限が設けられるようになり、TravisCI で次のエラーが発生するようになった。
# "You have reached your pull rate limit."
#
# これを回避するためにログインしてから pull する。
#
# see:
# - https://docs.docker.com/docker-hub/download-rate-limit/
# - https://blog.travis-ci.com/docker-rate-limits
#
echo "DOCKER_USERNAME=$DOCKER_USERNAME"
if [ -n "$DOCKER_USERNAME"]; then
  docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"
fi
docker info
docker pull mongo:4.2
docker run --name mongo -d -p 27017:27017 mongo:4.2
docker pull osixia/openldap
docker pull shirasagi/mail
docker run --name test_mail -d -p 10143:143 -p 10587:587 shirasagi/mail
docker ps -a
