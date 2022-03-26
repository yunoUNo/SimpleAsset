// 패키지 정의
package main

// 1. 외부모듈 포함
import (
	"fmt"
	"encoding/json"		// JSON 구조 사용
	"strconv"			// 문자열과 기본형 사이 변환
	"time"    			// 시간
	"bytes"   			// 문자 버퍼 사용
	
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/protos/peer"
)

// 2. 체인코드 클래스-구조체정의 SimpleAsset
type SimpleAsset struct {

}

type Asset struct{
	Key string `json:"key"`
	Value string `json:"Value"`
}

// 3. Init 함수
func (t *SimpleAsset) Init(stub shim.ChaincodeStubInterface) peer.Response{
	args := stub.GetStringArgs()

	if len(args) != 2 {
		return shim.Error("Incorrect argumets. Explect a key and value")
	}
	err := stub.PutState(args[0], []byte(args[1]))
	if err != nil {
		return shim.Error(fmt.Sprintf("Failed to create asset: %s", args[0]))
		// return shim.Error("Failed to create asset: "+args[0])
	}

	return shim.Success([]byte("init success"))
}
// 4. Invoke 함수
func (t *SimpleAsset) Invoke(stub shim.ChaincodeStubInterface) peer.Response{
	fn, args := stub.GetFunctionAndParameters()
	/*
	if fn == "set" {
		return t.Set(stub, args)
	} else if fn == "get" {
		return t.Get(stub, args)
	} else if fn =="del"{
		return t.Del(stub, args)
	} else if fn =="transfer"{
		return t.Transfer(stub, args)
	} else if fn == "history"{
		return t.History(stub, args)
	}
*/
	switch fn{
	case "set":
		return t.Set(stub, args)
	case "get":
		return t.Get(stub, args)
	case "del":
		return t.Del(stub, args)
	case "transfer":
		return t.Transfer(stub, args)
	case "history":
		return t.History(stub, args)
	}
	
	return shim.Error("Not supported function name"+ fn )
}

// 5. set 함수
func (t *SimpleAsset) Set(stub shim.ChaincodeStubInterface, args []string) peer.Response{
	
	if len(args) != 2 {
		return shim.Error("Incorrect arguments. Expecting a key and value")
	}

	// set에서 Asset 생성
	asset := Asset{Key: args[0], Value: args[1]}

	assetAsBytes, err := json.Marshal(asset)
	if err != nil{
		shim.Error("asset set fail!!: " +args[0])
	}

	// world state 생성/수정
	err = stub.PutState(args[0], assetAsBytes)
	if err != nil {
		return shim.Error("Failed to set asset: " + args[0])
	}

	return shim.Success(assetAsBytes)
}

// 6. get 함수  (바뀌는거 없음)
func (t *SimpleAsset) Get(stub shim.ChaincodeStubInterface, args []string) peer.Response{

	if len(args) != 1 {
		return shim.Error("Incorrect arguments. Expecting a key")
	}

	value, err := stub.GetState(args[0])   // 받는형식 자체가 Json
	if err != nil {
		shim.Error("Filed to get asset: " + args[0] + " with error: " + err.Error())
	}
	if value == nil {
		shim.Error("Asset not found: " + args[0])
	}

	return shim.Success([]byte(value))
}

// 6.1 del 함수
func (t *SimpleAsset) Del(stub shim.ChaincodeStubInterface, args []string) peer.Response{
	///데이터 찾는부분 get 과 동일
	if len(args) != 1 {
		return shim.Error("Incorrect arguments. Expecting a key")
	}

	value, err := stub.GetState(args[0])   
	if err != nil {
		shim.Error("Filed to get asset: " + args[0] + " with error: " + err.Error())
	}
	if value == nil {
		shim.Error("Asset not found: " + args[0])
	}
	////////////////////////////////////////////////////////
	// 삭제 부분
	err = stub.DelState(args[0])   // 삭제 보증 -> order -> validate 순서로 블록이 생성된다.
	////////////////////////////////////////////////////////
	return shim.Success([]byte(args[0]))
}

// 6.2 Transfer
func (t *SimpleAsset) Transfer(stub shim.ChaincodeStubInterface, args []string) peer.Response{
	// 1. 전달 인자 확인
	if len(args) != 3{    //from_key, to_key, amount
		return shim.Error("Transfer argument Error!!!")
	}
	// 2. 보내는이, 받는이 GestState 후 unmarshal
	from_asset, err := stub.GetState(args[0])
	if err != nil{
		return shim.Error("Asset not found: "+args[0])
	}
	if from_asset ==nil{
		return shim.Error("Failed to get asset: "+args[1]+ " with errer: "+ err.Error())
	}
	to_asset, err := stub.GetState(args[1])
	if err != nil{
		return shim.Error("Asset not found: "+args[0])
	}
	if to_asset == nil{
		return shim.Error("Asset not found: "+ args[1])
	}

	from := Asset{}
	to := Asset{}
	json.Unmarshal(from_asset, &from)
	json.Unmarshal(to_asset, &to)
	// 3. 잔액변환 및 검증, 전송
	from_amount, _ := strconv.Atoi(from.Value)
	to_amount, _ := strconv.Atoi(to.Value)
	amount, _ := strconv.Atoi(args[2])
	//검증
	if (from_amount - amount) < 0{
		shim.Error("Not enough asset value: "+ args[0])
	}
	// 결과를 다시 구조체에 string 형식으로 할당
	from.Value = strconv.Itoa(from_amount-amount)
	to.Value = strconv.Itoa(to_amount + amount)

	// 4. marshal
	from_asset, _ = json.Marshal(from)
	to_asset, _ = json.Marshal(to)
	// 5. PusState
	stub.PutState(args[0], from_asset)
	stub.PutState(args[1], to_asset)

	return shim.Success([]byte("transfer done!!"))
}	

// History 출력 
func (t *SimpleAsset) History(stub shim.ChaincodeStubInterface, args []string) peer.Response{
	if len(args) <1 {
		return shim.Error("History arguments Error!!!")
	}

	key := args[0]
	
	fmt.Println("getHistoryForKey: "+key) // 로그 남기기

	resultsIterator, err := stub.GetHistoryForKey(key)
	if err != nil{
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext(){
		response, err := resultsIterator.Next()
		if err != nil{
			return shim.Error(err.Error())
		}

		if bArrayMemberAlreadyWritten== true{
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"TxId\":")
		buffer.WriteString("\"")
		buffer.WriteString(response.TxId)
		buffer.WriteString("\"")
		buffer.WriteString(", \"Value\":")

		if response.IsDelete{
			buffer.WriteString("null")
		}else{
			buffer.WriteString(string(response.Value))
		}

		buffer.WriteString(", \"Timestamp\":")
		buffer.WriteString("\"")
		buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
		buffer.WriteString("\"")

		buffer.WriteString(", \"IsDelete\":")
		buffer.WriteString("\"")
		buffer.WriteString(strconv.FormatBool(response.IsDelete))
		buffer.WriteString("\"")

		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- history end...: %s",buffer.String())

	return shim.Success(buffer.Bytes())
}

// 7. main 함수
func main() {
	if err := shim.Start(new(SimpleAsset)); err != nil {
		fmt.Printf("Error starting SimpleAsset chaincode : %s", err)
	}
}