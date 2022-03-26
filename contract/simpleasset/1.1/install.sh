#!/bin/bash
# 1줄은 bash 셸로 할거다 라는 약속 ? 명령 ? 같은거임
set -x  # 옵션 

if [ $# -ne 4 ]; then
    echo "not correct param"
    echo "ex) ./install.sh simpleasset 1.0 instantiate mychannel"
    exit 1
fi


###### 환경변수 들#########
ccname=$1
version=$2  # 버전
instruction=$3   # upgrade 인지 instruction 인지
chname=$4   # 채널 이름


# v1.1 설치
docker exec cli peer chaincode install -n $ccname -v $version -p github.com/$ccname/1.1


# v1.1 배포/업그레이드
docker exec cli peer chaincode $instruction -n $ccname -v $version -c '{"Args":["a","0"]}' -C $chname -P 'OR ("Org1MSP.member","Org2MSP.member","Org3MSP.member")'
sleep 3

# v1.1 invoke
docker exec cli peer chaincode invoke -n $ccname -C $chname -c '{"Args":["set","Alice","10000"]}'
docker exec cli peer chaincode invoke -n $ccname -C $chname -c '{"Args":["set","Bob","20000"]}'
sleep 3
docker exec cli peer chaincode invoke -n $ccname -C $chname -c '{"Args":["transfer","Alice","Bob","5000"]}'
sleep 3

# v1.1 query
docker exec cli peer chaincode query -n $ccname -C $chname -c '{"Args":["get","Alice"]}'
docker exec cli peer chaincode query -n $ccname -C $chname -c '{"Args":["get","Bob"]}'
docker exec cli peer chaincode query -n $ccname -C $chname -c '{"Args":["history","Bob"]}'

# v1.1 del
docker exec cli peer chaincode invoke -n $ccname -C $chname -c '{"Args":["del","Bob"]}'
sleep 3
docker exec cli peer chaincode query -n $ccname -C $chname -c '{"Args":["get","Bob"]}'
docker exec cli peer chaincode query -n $ccname -C $chname -c '{"Args":["history","Bob"]}'

