#!/bin/bash

# PATCH: POD inter-connecting (Restart VM may loose below configuration!!!)
# https://github.com/ubuntu/microk8s/issues/72
/sbin/iptables -P FORWARD ACCEPT -w
