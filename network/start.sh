#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

# key 값 자동으로 가져오기
export CA1_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org1.example.com/ca && ls *_sk)
export CA2_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org2.example.com/ca && ls *_sk)
export CA3_PRIVATE_KEY=$(cd crypto-config/peerOrganizations/org3.example.com/ca && ls *_sk)

function checkPrereqs(){
    if [ ! -d "crypto-config" ]; then
        echo "crypto-config dir missig"
        exit 1
    fi

    if [ ! -d "config" ]; then
        echo "config dir missing"
        exit 1
    fi
}

checkPrereqs

docker-compose -f docker-compose.yml down

docker-compose -f docker-compose.yml up -d orderer.example.com ca.org1.example.com ca.org2.example.com ca.org3.example.com peer0.org1.example.com peer0.org2.example.com peer0.org3.example.com cli 
docker ps -a

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec cli peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.example.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block
sleep 3
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block
sleep 3
docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer0.org3.example.com peer channel join -b /etc/hyperledger/configtx/mychannel.block

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel update -f /etc/hyperledger/configtx/Org1MSPanchors.tx -c mychannel -o orderer.example.com:7050
sleep 3 
docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel update -f /etc/hyperledger/configtx/Org2MSPanchors.tx -c mychannel -o orderer.example.com:7050
sleep 3 
docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer0.org3.example.com peer channel update -f /etc/hyperledger/configtx/Org3MSPanchors.tx -c mychannel -o orderer.example.com:7050
sleep 3 