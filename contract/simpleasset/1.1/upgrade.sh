#!/bin/bash
# 1줄은 bash 셸로 할거다 라는 약속 ? 명령 ? 같은거임
set -x  # 옵션 

# v1.1 install
docker exec cli peer chaincode install -n simpleasset -v 1.1.2 -p github.com/simpleasset/1.1
# v1.1 upgrade
docker exec cli peer chaincode upgrade -n simpleasset -v 1.1.2 -C mychannel -c '{"Args":[]}' -P 'AND ("Org1MSP.member")'
sleep 3

# v1.1 invoke
docker exec cli peer chaincode invoke -n simpleasset -C mychannel -c '{"Args":["set","Alice","10000"]}'
docker exec cli peer chaincode invoke -n simpleasset -C mychannel -c '{"Args":["set","Bob","20000"]}'
sleep 3
docker exec cli peer chaincode invoke -n simpleasset -C mychannel -c '{"Args":["transfer","Alice","Bob","5000"]}'
sleep 3

# v1.1 query
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["get","Alice"]}'
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["get","Bob"]}'
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["history","Bob"]}'

# v1.1 del
docker exec cli peer chaincode invoke -n simpleasset -C mychannel -c '{"Args":["del","Bob"]}'
sleep 3
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["get","Bob"]}'
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["history","Bob"]}'

