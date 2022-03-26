#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=/home/bstudent/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}   # 나중에 configtxgen 파일이 이 파일 경로 읽어와야 함.
CHANNEL_NAME=mychannel

if [ ! -d config ]; then
  mkdir config
fi

#!!!! 이거 날릴때는 조심해야한다. 백업 무적권하구.
rm -fr config/*
rm -fr crypto-config/*

# 1. generate crypto material
cryptogen generate --config=./crypto-config.yaml   # utility는 cryptogen 옵션은 generate 가 사용됐다.
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# 2. 제네시스 블락 만드는거 옵션확인 configtxgen --help
configtxgen -profile ThreeOrgOrdererGenesis -outputBlock ./config/genesis.block   # configtx 에서 만든 프로필네임 사용! 
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# 3. 채널 트랜잭션을 만들어주라
configtxgen -profile ThreeOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME   # channelID이름으로 configtx에서 만든 프로필네임 사용해 채널 생성.
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# 4. generate anchor peer transaction
configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP   #앵커피어는 org네이션마다 하나씩.
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org1MSP..."
  exit 1
fi

# 4-1. generate anchor peer transaction
configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP   #앵커피어는 org네이션마다 하나씩.
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org2MSP..."
  exit 1
fi

# 4-2. generate anchor peer transaction
configtxgen -profile ThreeOrgChannel -outputAnchorPeersUpdate ./config/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP   #앵커피어는 org네이션마다 하나씩.
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org3MSP..."
  exit 1
fi