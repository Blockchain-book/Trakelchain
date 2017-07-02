#  趣快出行
此项目为趣快出行区块链后台，用户下载、部署后可试用趣快出行后台。
    
##  1. 系统要求
1. 目前仅支持Linux
2. Go语言环境
  
##  2. 安装区块链后台
1. 执行以下命令下载trakelchain：  
`git clone https://github.com/trakel-project/trakelchain.git`

2. 执行以下命令运行四个节点的Trakelchain：  
`./start.sh`

3. 如果想手动起四个节点并监控状态，打开四个终端窗口，分别运行：  
```
./trakelchain -o 1 -l 8001 -t 8081 //run this on first node
./trakelchain -o 2 -l 8002 -t 8082 //run this on second node
./trakelchain -o 3 -l 8003 -t 8083 //run this on third node
./trakelchain -o 4 -l 8004 -t 8084 //run this on fourth node
```
    
## 3. 部署合约（可选）
我们提供的区块链后台中已部署趣快出行的智能合约，用户可以直接使用。如果想体验在区块链平台上部署智能合约，请执行以下步骤：

## 4. 使用


## 接口说明
请见API.md


