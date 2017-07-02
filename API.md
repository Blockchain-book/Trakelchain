# 接口说明
## 区块链接口
调用invoke接口调用智能合约函数，然后调用getTransactionReceipt获取返回值。  
JSON-RPC调用方法说明：

### 调用合约
|方法|参数|返回值|
|---|----|-----|
|contract_invokeContract|`{from: <string> 合约调用者地址。to: <string> 合约地址。payload:<string> 方法名和方法参数经过编码后的input字节码。signature: <string> 交易签名timestamp: <number> 交易时间戳(单位ns)。}`|transactionHash:<string>  交易的哈希值,32字节的十六进制字符串|

**说明**：to合约地址需要在部署完合约以后，调用tx_getTransactionReceipt方法来获取。

Example：  
**Request**   
`curl -X POST --data '{"jsonrpc":"2.0","method":" contract_invokeContract ","params": [{
  "from": "0xb60e8dd61c5d32be8058bb8eb970870f07233155",
"to":"0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331",    
   "payload":    
"0xcdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001",
"timestamp": 1477459062327000000,
" signature ": "your signature"
   }],"id":71}'`

**Result**  
`{
"id":71,
"jsonrpc": "2.0",
"result": "0xe670ec64341771606e55d6b4ca35a1a6b75ee3d5145a99d05921026d1527331"
}`


### 获取函数调用返回值
|方法|参数|返回值|
|---|----|-----|
|tx_getTransactionReceipt|transactionHash: <string> 交易hash。|<receipt>{postState: <string> 交易状态。contractAddress:<string> 合约地址。ret: <string>执行的结果。}


Example：  
**Request**  
`curl -X POST --data '{"jsonrpc": "2.0", "method": "tx_getTransactionReceipt", "params":  ["0xb60e8dd61c5d32be8058bb8eb970870f07233155"], "id": 71}'`

**Result**  
`{"id":71,"jsonrpc": "2.0","result": {" postState ": ‘1’" contractAddress ": ‘0xe04d296d2460cfb8472af2c5fd05b5a214109c25688d3704aed5484f’" ret ": “0x606060405260e060020a60003504633ad14af381146030578063569c5f6d146056578063d09de08a14606d575b6002565b346002576000805460043563ffffffff8216016024350163ffffffff199091161790555b005b3460025760005463ffffffff166060908152602090f35b3460025760546000805463ffffffff19811663ffffffff90911660010117905556”}}`

      
## 智能合约接口
请参见API.sol  
合约地址：0x80c3fbdee14edd3cc1c3f8941f4d486d0b3552c5   
**注意**：部分函数只有合约部署者才能调用，部署者信息：  
地址：0x2cd84f9e3c182c5c543571ea00611c41009c7024  
私钥：0x437cace9ccb62f0e3e5bd71d2793aa8ac4a0e9d42262028e4a4dc7797d060dff
