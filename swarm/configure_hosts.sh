#!/bin/sh

# With DUMPED IPs in preaction script, make /etc/hosts
WORKING_DIR=/vagrant/exchange/hosts

INTER_CONNECT=$WORKING_DIR/interconnecting
HOST_FILES=`find $WORKING_DIR -type f`

if [ ! -f $INTER_CONNECT ]; then
  cat $HOST_FILES | sort | uniq -u > $INTER_CONNECT
fi

DNS_HOST=$WORKING_DIR/hosts
rm -rf $DNS_HOST

for f in $HOST_FILES
do
  HOST_IP=`cat $f $INTER_CONNECT | sort | uniq -d`
  echo "$HOST_IP `basename $f`" >> $DNS_HOST
  echo "$HOST_IP" > $f
done

COMMENT_HOST_HEADER="# BEGIN cluster hosts"
COMMENT_HOST_FOOTER="# END cluster hosts"

sed -i "/^$COMMENT_HOST_HEADER$/,/^$COMMENT_HOST_FOOTER$/d" /etc/hosts
echo "$COMMENT_HOST_HEADER" >> /etc/hosts
cat $DNS_HOST >> /etc/hosts
echo "$COMMENT_HOST_FOOTER" >> /etc/hosts

for f in $HOST_FILES
do
  REMOTE=`basename $f`
  DELETE_CMD="sed -i '/^$COMMENT_HOST_HEADER$/,/^$COMMENT_HOST_FOOTER$/d' /etc/hosts"

  (echo "$COMMENT_HOST_HEADER"; cat $DNS_HOST; echo "$COMMENT_HOST_FOOTER") | ssh -o "StrictHostKeyChecking no" $REMOTE "$DELETE_CMD && tee -a /etc/hosts > /dev/null"
done

rm -rf $WORKING_DIR
