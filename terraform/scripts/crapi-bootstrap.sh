#! /bin/bash

cd /home/ubuntu

sudo apt-get update -y

sudo apt-get install \
  awscli \
  ca-certificates \
  curl \
  gnupg \
  lsb-release -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update -y

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

sudo mkdir /opt/crapi
cd /opt/crapi

if [ "${git_branch}" = "main" ]; then
  DOCKER_VERSION="production"
else
  DOCKER_VERSION="development"
fi

aws s3 cp s3://noname-workshop-share/${git_branch}/crapi-docker-compose.yml ./docker-compose.yml
sudo VERSION=$DOCKER_VERSION docker compose -f /opt/crapi/docker-compose.yml --compatibility up -d
