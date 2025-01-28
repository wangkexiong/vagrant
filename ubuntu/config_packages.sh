#!/bin/sh

for each in `ls -1 /vagrant/script/package/*.sh 2>/dev/null`; do
  chmod +x "$each"
  dos2unix "$each"
  $each
done