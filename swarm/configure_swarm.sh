#!/bin/sh

LEAD=
TOKEN_MANAGER=
TOKEN_WORKER=

# If not properly configured no_proxy, swarm cluster may failed to be initialized.
# Temporarily remove docker proxy related configuration and restore back after cluster is ready.
DISABLE_DOCKER_PROXY_CMD="if [ -f /etc/sysconfig/docker ]; then mv /etc/sysconfig/docker /tmp/docker_vagrant_proxy && systemctl restart docker; fi"
RESTORE_DOCKER_PROXY_CMD="if [ -f /tmp/docker_vagrant_proxy ]; then mv /tmp/docker_vagrant_proxy /etc/sysconfig/docker && systemctl restart docker; fi"

for SSH_HOST in $1; do
  SSH_IP=`grep "$SSH_HOST$" /etc/hosts | tail -1 | awk '{print $1}'`

  if [ "x$LEAD" = "x" ]; then
    LEAD=$SSH_IP
    if ssh -o "StrictHostKeyChecking no" $LEAD docker node ls 2>/dev/null; then
      echo "Already in docker swarm cluster..."
      exit 0
    fi

    SWARM_INIT_CMD="$DISABLE_DOCKER_PROXY_CMD && docker swarm init --advertise-addr $SSH_IP"
    ssh -o "StrictHostKeyChecking no" $LEAD $SWARM_INIT_CMD

    TOKEN_MANAGER=`ssh -o "StrictHostKeyChecking no" $LEAD docker swarm join-token -q manager`
    TOKEN_WORKER=`ssh  -o "StrictHostKeyChecking no" $LEAD docker swarm join-token -q worker`
  else
    SWARM_MANAGER_JOIN_CMD="docker swarm join --advertise-addr $SSH_IP --listen-addr $SSH_IP:2377 --token $TOKEN_MANAGER $LEAD:2377"
    SWARM_MANAGER_JOIN_CMD="$DISABLE_DOCKER_PROXY_CMD && $SWARM_MANAGER_JOIN_CMD"
    ssh -o "StrictHostKeyChecking no" $SSH_IP "$SWARM_MANAGER_JOIN_CMD && $RESTORE_DOCKER_PROXY_CMD"
  fi
done

for SSH_HOST in $2; do
  SSH_IP=`grep "$SSH_HOST$" /etc/hosts | tail -1 | awk '{print $1}'`

  SWARM_WORKER_JOIN_CMD="docker swarm join --advertise-addr $SSH_IP --listen-addr $SSH_IP:2377 --token $TOKEN_WORKER $LEAD:2377"
  ssh -o "StrictHostKeyChecking no" $SSH_IP $SWARM_WORKER_JOIN_CMD
done

ssh -o "StrictHostKeyChecking no" $LEAD "$RESTORE_DOCKER_PROXY_CMD"
