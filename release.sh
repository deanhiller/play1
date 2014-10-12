#!/bin/bash

HOST=$1

set -x

export TIME=`date +%s`

echo ZIPPING app with timestamp=$TIME

cd ..
rm play.zip
zip -r play.zip play1 -x "*.git*"

echo SENDING zip file to production
scp play.zip root@$HOST:/root/play.zip
echo DONE SENDING, now deploying

#This one allows us not to have to escape but then we can't go backwards I think and not escape when we need to
#ssh root@$HOST <<\EOF

ssh root@$HOST <<EOF
    mv /root/play.zip /opt/production/astaging/play.zip
    cd /opt/production/astaging
    unzip play.zip
    mv /opt/production/astaging/play1 /opt/production/play$TIME
    mv /opt/production/astaging/play.zip /opt/production/bak/play$TIME.zip
EOF


echo NOW stopping old server and starting new server
#NOW, we need to make the switch....stopping the application and switching the link and starting the application
ssh root@$HOST <<EOF
    cd /opt/production
    ./theapp/conf/stopproduction.sh
    rm /opt/production/play
    ln -s play$TIME play 
    ./theapp/conf/startproduction.sh
EOF
