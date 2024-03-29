#!/bin/bash
set -x

docker exec cli peer chaincode install -n simpleasset -v 1.0 -p github.com/simpleasset/1.0

docker exec cli peer chaincode instantiate -n simpleasset -v 1.0 -c '{"Args":["a","100"]}' -C mychannel -P 'AND ("Org1MSP.member")'
sleep 3

docker exec cli peer chaincode invoke -n simpleasset -C mychannel -c '{"Args":["set","b","200"]}'
sleep 3
# 4. 쿼리 
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["get","a"]}'
docker exec cli peer chaincode query -n simpleasset -C mychannel -c '{"Args":["get","b"]}'
