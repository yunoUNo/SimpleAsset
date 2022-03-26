#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=/home/bstudent/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}   # 나중에 configtxgen 파일이 이 파일 경로 읽어와야 함.

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

# 3. 채널 트랜잭션을 생성
configtxgen -profile TwoOrgChannel1 -outputCreateChannelTx ./config/channel1.tx -channelID channel1
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi
configtxgen -profile TwoOrgChannel2 -outputCreateChannelTx ./config/channel2.tx -channelID channel2

# 4-1 CHannel1 Join
configtxgen -profile TwoOrgChannel1 -outputAnchorPeersUpdate ./config/Org1MSPanchors.tx -channelID channel1 -asOrg Org1MSP

if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org1MSP..."
  exit 1
fi
configtxgen -profile TwoOrgChannel1 -outputAnchorPeersUpdate ./config/Org3MSPanchors.tx -channelID channel1 -asOrg Org3MSP

# 4-2 Channel2 Join
configtxgen -profile TwoOrgChannel2 -outputAnchorPeersUpdate ./config/Ch2Org2MSPanchors.tx -channelID channel2 -asOrg Org2MSP
configtxgen -profile TwoOrgChannel2 -outputAnchorPeersUpdate ./config/Ch2Org3MSPanchors.tx -channelID channel2 -asOrg Org3MSP