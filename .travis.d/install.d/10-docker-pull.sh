#!/bin/bash
if [ -n "$DOCKER_USERNAME"]; then
  echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
fi
docker info
docker pull mongo:4.2
docker run --name mongo -d -p 27017:27017 mongo:4.2
docker pull osixia/openldap
docker pull shirasagi/mail
docker run --name test_mail -d -p 10143:143 -p 10587:587 shirasagi/mail
docker ps -a
