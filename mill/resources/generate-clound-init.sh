#!/bin/bash

mkdir generated
efsDomain=$1
millConfigPath=$2
millVersion=$3

for i in audit-worker bit-worker; do  
python3 generate-cloud-init.py -t cloud-init.txt.template -n $i -o generated/$i-cloud-init.txt -e efs.domain.com -p resources/common.properties -s $millConfigPath -r $aw -v 5.1.0-SNAPSHOT
