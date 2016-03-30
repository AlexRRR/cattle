#!/bin/sh
set -e
umask 077

IMAGE=$1
if [ "$IMAGE" = "" ]; then
    IMAGE=rancher/server
fi

mkdir -p /var/lib/rancher/etc/server
mkdir -p /var/lib/rancher/bin

echo Creating /var/lib/rancher/etc/server.conf
cat > /var/lib/rancher/etc/server.conf << EOF
export CATTLE_HA_CLUSTER_SIZE=${clusterSize}
export CATTLE_HA_HOST_REGISTRATION_URL=${hostRegistrationUrl}
export CATTLE_HA_CONTAINER_PREFIX=${containerPrefix}

export CATTLE_DB_CATTLE_MYSQL_HOST=${dbHost}
export CATTLE_DB_CATTLE_MYSQL_PORT=${dbPort}
export CATTLE_DB_CATTLE_MYSQL_NAME=${dbName}
export CATTLE_DB_CATTLE_USERNAME=${dbUser}
export CATTLE_DB_CATTLE_PASSWORD=${dbPass}

export CATTLE_HA_REDIS_PORT=${redisPort}
export CATTLE_HA_SWARM_PORT=${swarmPort}
export CATTLE_HA_HTTP_PORT=${httpPort}
export CATTLE_HA_HTTPS_PORT=${httpsPort}
export CATTLE_HA_ZK_CLIENT_PORT=${zookeeperClientPort}
export CATTLE_HA_ZK_QUORUM_PORT=${zookeeperQuorumPort}
export CATTLE_HA_ZK_LEADER_PORT=${zookeeperLeaderPort}
EOF

<#if cert?? >
echo Creating /var/lib/rancher/etc/server/cert.pem
cat > /var/lib/rancher/etc/server/cert.pem << EOF
${cert}
EOF
</#if>

<#if key?? >
echo Creating /var/lib/rancher/etc/server/key.pem
cat > /var/lib/rancher/etc/server/key.pem << EOF
${key}
EOF
</#if>

<#if certChain?? >
echo Creating /var/lib/rancher/etc/server/ca.pem
cat > /var/lib/rancher/etc/server/ca.pem << EOF
${certChain}
EOF
</#if>

<#if encryptionKey?? >
echo Creating /var/lib/rancher/etc/server/encryption.key
if [ -e /var/lib/rancher/etc/server/encryption.key ]; then
    mv /var/lib/rancher/etc/server/encryption.key /var/lib/rancher/etc/server/encryption.key.`date '+%s'`
fi
cat > /var/lib/rancher/etc/server/encryption.key << EOF
${encryptionKey}
EOF
</#if>


echo Creating /var/lib/rancher/bin/rancher-ha-start.sh
cat > /var/lib/rancher/bin/rancher-ha-start.sh << "EOF"
#!/bin/sh
set -e

IMAGE=$1
if [ "$IMAGE" = "" ]; then
    echo Usage: $0 DOCKER_IMAGE
    exit 1
fi

docker rm -fv rancher-ha >/dev/null 2>&1 || true
ID=`docker run --restart=always -d -v /var/run/docker.sock:/var/run/docker.sock --name rancher-ha --net host --privileged -v /var/lib/rancher/etc:/var/lib/rancher/etc $IMAGE ha`

echo Started container rancher-ha $ID
echo Run the below to see the logs
echo
echo docker logs -f rancher-ha
EOF

chmod +x /var/lib/rancher/bin/rancher-ha-start.sh

echo Running: /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
echo To re-run please execute: /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
exec /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
