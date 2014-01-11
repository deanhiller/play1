#!/bin/bash

export TIME=`date +%s`

echo BUILDING app with timestamp=$TIME

cd framework

ant package

rc=$?
if [[ $rc != 0 ]] ; then
    echo "build failure. exiting"
    exit $rc
fi

echo SENDING zip file to production

cd dist
export zipfile=`ls play-master*`

thefullname=$(basename "$zipfile")
dirname="${thefullname%.*}"

scp $zipfile root@myextremestore.com:/root

echo DONE SENDING, now deploying

#This one allows us not to have to escape but then we can't go backwards I think and not escape when we need to

#ssh root@myextremestore.com <<\EOF
ssh root@myextremestore.com <<EOF
    mv /root/$zipfile /opt/production/astaging/play-master.zip
    cd /opt/production/astaging
    unzip play-master.zip
    mv /opt/production/astaging/$dirname /opt/play-master$TIME
    mv /opt/production/astaging/play-master.zip /opt/production/bak/play-master$TIME.zip
EOF


echo NOW stopping old server and starting new server
#NOW, we need to make the switch....stopping the application and switching the link and starting the application
ssh root@myextremestore.com <<EOF
    cd /opt/production
    ./store/conf/stopproduction.sh
    mv store/logs/store.log store/logs/store.log.bak
    rm /opt/play1.3.x
    ln -s /opt/play-master$TIME /opt/play1.3.x
    chmod 755 ./store/conf/startproduction.sh
    chmod 755 ./store/conf/stopproduction.sh
    ./store/conf/startproduction.sh
EOF


#clush -g datanodes <<\EOF
#export READ=$(grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eth0 |awk -F= '{print $2}')
#echo "listen_address: $READ" >> /opt/cassandraB/conf/cassandra.yaml
#EOF


