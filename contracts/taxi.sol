// Version 0.5


pragma solidity ^0.4.6;


contract CarCoin 
{
    mapping (address => int) balances;
    address owner;
    address taxing;
    bool flag;
    uint counter;

	struct record 
	{
		address from;
		address to;
		int value;
		string comment;
	}    
    mapping (uint => record) records;

    function CarCoin() 
    {
        owner = msg.sender;
        balances[owner] = 1000000000;
        flag = true;
        counter = 1;
    }

    function tsRecords(uint idx) returns(address from, address to, int val, string comm)
    {
    	from = records[idx].from;
    	to = records[idx].to;
    	val = records[idx].value;
    	comm = records[idx].comment;
    }

    function Transfer(address from, address to, int value, string comment) private
    {
    	records[counter].from = from;
    	records[counter].to = to;
    	records[counter].value = value;
    	records[counter].comment = comment;
    	counter++;
    }



    function exeOnce(address addr)
    {
        if (flag)
        {
            taxing = addr;
        }
        //flag = false; 测试时注释
    }

    function getBalance(address addr) returns(int) 
    {
        return balances[addr];
    }
    
    function getOwner() returns(address) 
    {
        return owner;
    }

    function verify() returns(address a, address b, address c)
    {
        a = msg.sender;
        b = taxing;
        c = owner;
    }

    function verify1() returns(address)
    {
    	return msg.sender;
    }

    function prepay(address client, int preFee) returns(bool success) 
    {   
        if (msg.sender != taxing)
        {
            return false;
        }

        balances[client] -= preFee;
        balances[owner] += preFee;
        Transfer(client, this, preFee, "prepay");
        return true;
    }
    
    function confirm(address client, address driver, int preFee, int finalFee)  returns(bool success) 
    {   
        if (msg.sender != taxing)
        {
            return false;
        }

        int remain = preFee - finalFee;
        balances[owner] -= preFee;
        balances[client] += remain;
        balances[driver] += finalFee;
        Transfer(this, client, remain, "remain fee");
        Transfer(this, driver, finalFee, "final fee");
        return true;
    }

    function penalty(address from, address to, int amount) returns(bool)
    {
        if (msg.sender != taxing)
        {
            return false;
        }

        balances[from] -= amount;
        balances[to] += amount;
    }


    function recharge(address addr, int amount) returns(bool)
    {
        if (msg.sender != owner)
        {
            return false;
        }
        if (balances[owner] < amount)
        {
            return false;
        }
        balances[addr] += amount;
        balances[owner] -= amount;
        return true;
    }
}





//只允许乘客修改，但允许任何人查询
contract Passenger
{
	struct data
	{
		address name;
		string info0;
		string info1;
		string info2;
	}
	mapping (address => data) passengers;

	function modifyInfo(string info0, string info1, string info2) returns(bool)
	{
		passengers[msg.sender].name = msg.sender;
		passengers[msg.sender].info0 = info0;
		passengers[msg.sender].info1 = info1;
		passengers[msg.sender].info2 = info2;
	}


	function getInfo() returns(string info0, string info1, string info2)
	{
		info0 = passengers[msg.sender].info0;
		info1 = passengers[msg.sender].info1;
		info2 = passengers[msg.sender].info2;
	}

	function getInfoWithAddress(address owner) returns(string info0, string info1, string info2)
	{
		info0 = passengers[owner].info0;
		info1 = passengers[owner].info1;
		info2 = passengers[owner].info2;
	}
	
}



contract Taxing 
{

	CarCoin carcoin = CarCoin(0x07cdd926d33553fa9c2c6d9ba7742cb2ba3f3101);
	Passenger pass = Passenger(0x4f403ceb3b4dd924405518d953d4e974b88e35bd);

	mapping (address => uint) passengerToOrder;	//每个乘客对应到某个订单
	mapping (address => uint) driverToOrder;	//每个司机对应到某个订单
	uint counterOrderIndex;						//下一个空的订单序号
	//订单需要的信息
	struct Order
	{
		uint id;				//订单编号
		address passenger;		//乘客地址
		address driver;			//司机地址
		int s_x;				//起点经度
		int s_y;				//起点纬度
		int d_x;				//终点经度
		int d_y;				//终点纬度
		string sName;			//起点地名
		string dName;			//终点地名
		int distance;			//起终点直线距离
		int preFee;				//预付款额
		int actFee;				//实际款额
		int actFeeTime;
		uint startTime; 		//UNIX标准时间
		uint pickTime;
		uint endTime;			//UNIX标准时间
		int state;				//订单状态 1待分配 2已被抢 3订单完成 4订单终止
		string passInfo;		//乘客个人信息，utf8
        string drivInfo0;		//司机个人信息，utf8
        string drivInfo1;
        string drivInfo2;
	}
	mapping (uint => Order) orders;

	mapping (address => uint) driverIndexs; //给每个司机分配一个内部的序号
	uint counterDriverIndex;				//下一个空的司机序号（当前司机数量+1）
	struct Driver
	{
		int cor_x;							//经度
		int cor_y;							//纬度
		bool state;							//true 表示接单中 false 表示休息中
		address name;						//司机地址
        string info0;
        string info1;
        string info2;
		uint counterOrder;					//司机当前可接订单数
		uint[8] orderPool; 					//司机可接订单池
		int last_x;							//上一次经度
		int last_y;							//上一次纬度
	}
	mapping (uint => Driver) drivers;		//使用序号去寻找司机的信息


	mapping (address => uint) passengerStates;	//乘客状态 0 1 2 3 4
	mapping (address => uint) driverStates;		//司机状态 0 1 2 3


	mapping (address => uint[5]) passengerNearDrivers;

	struct Judgement
	{
		int total;									//总评价数
		int avgScore;								//平均分
		mapping (int => int) score;					//单次分数
		mapping (int => string) comment;			//单次评价
	}

	//mapping (address => Judgement) passengerJudgements;
	mapping (address => Judgement) driverJudgements;

	struct passengerPosition
	{
		int x;
		int y;
	}
	mapping (address => passengerPosition) passPos;

	
	//里程单价 0.01币：0.1米 => 1km = 100块
	int unitPrice = 1;
	int unitPriceTime = 1;

	int penaltyPrice = 500;


	function Taxing() 
	{
		counterDriverIndex = 1;
		counterOrderIndex = 1;
	}

	function sqrt(int x) private returns (int)
	{		
		if(x < 0)
			x = - x;
		int z = (x + 1) / 2;
	    int y = x;
	    while (z < y) 
	    {
	        y = z;
	        z = (x / z + z) / 2;
	    }
	    return y;
	}


	//不会因为乘方而溢出，若距离超过了最大的表示范围，则返回值是-1
	// function calculateDistance(int x0, int x1, int y0, int y1) private returns(int)
	// {
	//     int tempX = x0 - x1;
	//     int tempY = y0 - y1;
	//     int maxDiff = 32700;
	//     int mult = 1;

	//     while(tempX > maxDiff || tempX < -maxDiff || tempY > maxDiff || tempY < - maxDiff)
	//     {
	//         x1 = (x0 + x1) / 2;
	//         y1 = (y0 + y1) / 2;
	//         mult *= 2;
	//         tempX = x0 - x1;
	//         tempY = y0 - y1;
	//         if (mult <= 0)
	//         {
	//             return -1;
	//         }
	//     }

	//     return mult * sqrt(tempX*tempX + tempY*tempY);
	// }

	function calculateDistance(int x0, int x1, int y0, int y1) private returns(int)
	{
		int tempX = x0 - x1;
		int tempY = y0 - y1;
	    return sqrt(tempX*tempX + tempY*tempY);
	}

	function driverSelction(int x, int y, uint orderIndex) private returns(bool)
	{
		uint i;
		uint j;
		int threshold = 500000; 	//阀值，当距离小于该值之后则派单，数值可调整
		int temp;
		uint maxOrder = 8;			//司机可抢的最大订单数量
		bool flag = false;
		for (i=1; i<counterDriverIndex; ++i)
		{
			if (drivers[i].state && driverStates[drivers[i].name] == 0) //
			{
				temp = calculateDistance(x, drivers[i].cor_x, y, drivers[i].cor_y);
				if (temp < threshold)
				{
					//找到订单池中的空位
					for(j=0; j<maxOrder; ++j)
					{
						if(orders[drivers[i].orderPool[j]].state != 1)
						{
							flag = true;
							drivers[i].orderPool[j] = orderIndex;
							break;
						}
					}
				}
			}
		}
		return flag;
	}

	function calculatePreFee(int s_x, int s_y, int d_x, int d_y) private returns(int)
	{
		int tempX = s_x - d_x;
		int tempY = s_y - d_y;
		if (tempX < 0)
		{
			tempX = -tempX;
		}
		if (tempY < 0)
		{
			tempY = -tempY;
		}
		return ((tempX + tempY) * unitPrice) / 2 * 3 / 100;
		//return unitPrice * calculateDistance(s_x, d_x, s_y, d_y);
	}

	function passengerSubmitOrder(int s_x, int s_y, int d_x, int d_y, uint time, string passInfo, string sName, string dName) returns(uint)
	{
		if(carcoin.getBalance(msg.sender) < 0) //乘客账户余额必须是正数
		{
			return 0;
		}
		if(passengerStates[msg.sender] != 0) //乘客必须处于挂起状态才能抢单
		{
			return 0;
		}
		if (counterDriverIndex <= 1) //没有司机
		{
			return 0;
		}

		//创建新的订单
		passengerToOrder[msg.sender] = counterOrderIndex;
		orders[counterOrderIndex].id = counterOrderIndex;
		orders[counterOrderIndex].passenger = msg.sender;
		orders[counterOrderIndex].driver = 0x0;
		orders[counterOrderIndex].s_x = s_x;
		orders[counterOrderIndex].s_y = s_y;
		orders[counterOrderIndex].d_x = d_x;
		orders[counterOrderIndex].d_y = d_y;
		orders[counterOrderIndex].distance = 0;//calculateDistance(s_x, d_x, s_y, d_y);
		orders[counterOrderIndex].preFee = penaltyPrice + calculatePreFee(s_x, s_y, d_x, d_y);
		orders[counterOrderIndex].actFee = 0;
		orders[counterOrderIndex].actFeeTime = 0;
		orders[counterOrderIndex].startTime = time;
		orders[counterOrderIndex].state = 1;
		orders[counterOrderIndex].passInfo = passInfo;
		orders[counterOrderIndex].sName = sName;
		orders[counterOrderIndex].dName = dName;
		counterOrderIndex++;
		passengerStates[msg.sender] = 1; //乘客订单分配中

		if(!driverSelction(s_x, s_y, counterOrderIndex-1))
		{
			orders[counterOrderIndex-1].state = 4;
			passengerStates[msg.sender] = 0;
			return 0;
		}
		
		return counterOrderIndex-1;
	}


	function driverCompetOrder(uint orderIndex) returns(bool)
	{	
		if(driverIndexs[msg.sender] == 0) //司机没有注册
		{
			return false;
		}
		if(driverStates[msg.sender] != 0) //司机不在挂起状态
		{
			return false;
		}
		if(orders[orderIndex].state != 1) //抢单失败
		{
			return false;
		}
		orders[orderIndex].state = 2;
		orders[orderIndex].driver = msg.sender;
		//orders[orderIndex].drivInfo = drivers[driverIndexs[msg.sender]].info;
        orders[orderIndex].drivInfo0 = drivers[driverIndexs[msg.sender]].info0;
        orders[orderIndex].drivInfo1 = drivers[driverIndexs[msg.sender]].info1;
        orders[orderIndex].drivInfo2 = drivers[driverIndexs[msg.sender]].info2;

		//passengerLinks[orders[orderIndex].passenger] = msg.sender;
		//driverLinks[msg.sender] = orders[orderIndex].passenger;
		
		passengerStates[orders[orderIndex].passenger] = 2;		//乘客待付款
		driverStates[msg.sender] = 1;							//司机已接单
		driverToOrder[msg.sender] = orderIndex;

		//初始化司机上一次位置
		drivers[driverIndexs[msg.sender]].last_x = orders[orderIndex].s_x; 
		drivers[driverIndexs[msg.sender]].last_y = orders[orderIndex].s_y;
		return true;
	}	

	function passengerPrepayFee() returns(bool)
	{
		uint orderIndex = passengerToOrder[msg.sender];
		address driver = orders[orderIndex].driver;

		//乘客不是待付款 或者订单不是已被抢
		if (passengerStates[msg.sender] != 2 || orders[orderIndex].state != 2)
		{
			return false;
		}

		//付款过程，确定款项已经进入合约账户
		if (carcoin.prepay(msg.sender, orders[orderIndex].preFee))
		{
			passengerStates[msg.sender] = 3;
			driverStates[driver] = 2;
			return true;
		}
		//下面是支付失败的逻辑，或者是乘客取消订单的逻辑，目前没有处理，待加入，例如订单状态的改变等
		else
		{
			//....
			orders[orderIndex].state = 4;
			passengerStates[msg.sender] = 0;
			driverStates[driver] = 0;
			return false;
		}
	}

	function driverPickUpPassenger(int x, int y, uint time) returns(bool)
	{
		uint orderIndex = driverToOrder[msg.sender];
		address passenger = orders[orderIndex].passenger;

		if (driverStates[msg.sender] != 2 || passengerStates[passenger] != 3 || orders[orderIndex].state != 2)
		{
			return false;
		}

		int passX = passPos[passenger].x;
		int passY = passPos[passenger].y;
		int threshold = 2000;
		
		if (calculateDistance(x, passX, y, passY) > threshold)
		{
			return false;
		}

		drivers[driverIndexs[msg.sender]].last_x = x;
		drivers[driverIndexs[msg.sender]].last_y = y;
		orders[orderIndex].pickTime = time;

		passengerStates[passenger] = 4;
		driverStates[msg.sender] = 3;
		return true;
	}

	function driverCalculateActFee(int cur_x, int cur_y) returns(int)
	{
		uint orderIndex = driverToOrder[msg.sender];
		uint driverindex = driverIndexs[msg.sender];
		int distance;
		address passenger = orders[orderIndex].passenger;

		if (driverStates[msg.sender] != 3 || passengerStates[passenger] != 4 || orders[orderIndex].state != 2)
		{
			return 0;
		}
		
		distance = calculateDistance(cur_x, drivers[driverindex].last_x, cur_y, drivers[driverindex].last_y);
		orders[orderIndex].distance += distance;
		orders[orderIndex].actFee +=  distance * unitPrice / 100;
        drivers[driverindex].cor_x = cur_x;
        drivers[driverindex].cor_y = cur_y;
		drivers[driverindex].last_x = cur_x;
		drivers[driverindex].last_y = cur_y;
		return orders[orderIndex].actFee;
	}

	function driverFinishOrder(uint time) returns(bool)
	{
		uint orderIndex = driverToOrder[msg.sender];
		address passenger = orders[orderIndex].passenger;
		//司机不是行程中，订单不是已被抢
		if (driverStates[msg.sender] != 3 || passengerStates[passenger] != 4 || orders[orderIndex].state != 2)
		{
			return false;
		}
		orders[orderIndex].actFeeTime = (int)(time - orders[orderIndex].pickTime) * unitPriceTime;
		int preFee = orders[orderIndex].preFee;
		int finalFee = orders[orderIndex].actFee + orders[orderIndex].actFeeTime;
		if (finalFee > preFee)
		{
			finalFee = preFee;
			orders[orderIndex].actFee = finalFee - orders[orderIndex].actFeeTime;
		}

		//支付
		if (carcoin.confirm(passenger, msg.sender, preFee, finalFee))
		{
			orders[orderIndex].state = 3;
			orders[orderIndex].endTime = time;
			passengerStates[passenger] = 0;
			driverStates[msg.sender] = 0;
			return true;
		}
		//同上，若支付失败要怎么办
		else
		{
			//....
			passengerStates[passenger] = 0;
			driverStates[msg.sender] = 0;
			orders[orderIndex].state = 4;
			return false;
		}
	}


	function getDriverState() returns(uint)
	{
		return driverStates[msg.sender];
	}

	function getPassengerState() returns(uint)
	{
		return passengerStates[msg.sender];
	}


	function getDriverRegiterState() returns(bool)
	{
		if (driverIndexs[msg.sender] > 0)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	function newDriverRegister(string info0, string info1, string info2) returns(uint)
	{
		if (driverIndexs[msg.sender] > 0)//已经注册
		{
			return driverIndexs[msg.sender];
		}
		driverIndexs[msg.sender] = counterDriverIndex;
		drivers[counterDriverIndex].state = false;
		drivers[counterDriverIndex].name = msg.sender;
		drivers[counterDriverIndex].cor_x = 0x7FFFFFFF;
		drivers[counterDriverIndex].cor_y = 0x7FFFFFFF;
		drivers[counterDriverIndex].info0 = info0;
        drivers[counterDriverIndex].info1 = info1;
        drivers[counterDriverIndex].info2 = info2;
		drivers[counterDriverIndex].counterOrder = 0;
		driverStates[msg.sender] = 0;
		counterDriverIndex++;
		return counterDriverIndex - 1;
	}


	function driverUpdatePos(int x, int y, bool state) returns(bool)
	{
		uint tempIndex = driverIndexs[msg.sender];
		if (tempIndex == 0)
		{
			return false;
		}
		else
		{
			drivers[tempIndex].cor_x = x;
			drivers[tempIndex].cor_y = y;
			drivers[tempIndex].state = state;
			return true;
		}
	}


	function getDriverOrderPool() returns(uint[8])
	{
		uint driverIndex = driverIndexs[msg.sender];
		uint i;
		for (i=0; i<8; ++i)
		{
			uint orderIndex = drivers[driverIndex].orderPool[i];
			if (orderIndex != 0 && orders[orderIndex].state != 1)
			{
				drivers[driverIndex].orderPool[i] = 0;
			}
		}
		return drivers[driverIndex].orderPool;
	}



	function getOrderID(bool isPassenger) returns(uint)
	{
		uint orderIndex;
		if(isPassenger)
		{
			orderIndex = passengerToOrder[msg.sender];
		}
		else
		{
			orderIndex = driverToOrder[msg.sender];
		}
		return orderIndex;
	}


	function getOrderInfo0(uint orderIndex) returns(uint id, address passenger, int s_x, int s_y, int d_x, int d_y, int distance, int preFee, uint startTime, string passInfo) 
	{
		id = orders[orderIndex].id;
		passenger = orders[orderIndex].passenger;
		s_x = orders[orderIndex].s_x;
		s_y = orders[orderIndex].s_y;
		d_x = orders[orderIndex].d_x;
		d_y = orders[orderIndex].d_y;
		distance = orders[orderIndex].distance;
		preFee = orders[orderIndex].preFee;
		startTime = orders[orderIndex].startTime;
		passInfo = orders[orderIndex].passInfo;
	}

	function getOrderInfo1(uint orderIndex) returns(address driver, int actFee, int actFeeTime, uint pickTime, uint endTime, int state)
	{
		driver = orders[orderIndex].driver;
		actFee = orders[orderIndex].actFee;
		actFeeTime = orders[orderIndex].actFeeTime;
		pickTime = orders[orderIndex].pickTime;
		endTime = orders[orderIndex].endTime;
		state = orders[orderIndex].state;
	}

	//乘客调用
	//等待司机接客界面轮循调用
    function getOrderStateAndDriverPos(uint orderIndex) returns(int state, int x, int y)  
    {
        uint driverIndex;
        address driver = orders[passengerToOrder[msg.sender]].driver;
        driverIndex = driverIndexs[driver];
        state = orders[orderIndex].state;
        x = drivers[driverIndex].cor_x;
        y = drivers[driverIndex].cor_y;
    }

    function getPassStateAndDriPos() returns(uint state, int x, int y)
    {
    	uint driverIndex;
        address driver = orders[passengerToOrder[msg.sender]].driver;
        driverIndex = driverIndexs[driver];
        state = passengerStates[msg.sender];
        x = drivers[driverIndex].cor_x;
        y = drivers[driverIndex].cor_y;
    }

	function getOrderState(uint orderIndex) returns(int) 
	{
		return orders[orderIndex].state;
	}

	function getOrderPreFee(uint orderIndex) returns(int) 
	{
		return orders[orderIndex].preFee;
	}

	function getOrderActFee(uint orderIndex) returns(int) 
	{
		return orders[orderIndex].actFee;
	}

	function getOrderDisAndActFee(uint orderIndex) returns(int distance, int actFeeD, int actFeeT, uint duration)
	{
		distance = orders[orderIndex].distance;
		actFeeD = orders[orderIndex].actFee;
		actFeeT = orders[orderIndex].actFeeTime;
		duration = orders[orderIndex].endTime - orders[orderIndex].startTime;
	}

	function getOrderPassInfo(uint orderIndex) returns(string)
	{
		return orders[orderIndex].passInfo;
	}

    function getOrderDrivInfo(uint orderIndex) returns(string drivInfo0, string drivInfo1, string drivInfo2)
    {
        drivInfo0 = orders[orderIndex].drivInfo0;
        drivInfo1 = orders[orderIndex].drivInfo1;
        drivInfo2 = orders[orderIndex].drivInfo2;
    }

	function getOrderFeeStimeAndPlaceName(uint orderIndex) returns(int fee, uint time, string sName, string dName)
	{
		fee = orders[orderIndex].preFee;
		time = orders[orderIndex].startTime;
		sName = orders[orderIndex].sName;
		dName = orders[orderIndex].dName;
	}

	function getOrderPlaceName(uint orderIndex) returns(string sName, string dName)
	{
		sName = orders[orderIndex].sName;
		dName = orders[orderIndex].dName;
	}


	function getNearDrivers(int x, int y, int threshold) returns(uint[5])
	{
		uint maxNear = 5;
		uint i;
		uint j = 0;
		for (i=0; i<5; ++i)
		{
			passengerNearDrivers[msg.sender][i] = 0;
		}
		for (i=1; i<counterDriverIndex; ++i)
		{
			if (drivers[i].state && driverStates[drivers[i].name] == 0)
			{
				if (calculateDistance(x, drivers[i].cor_x, y, drivers[i].cor_y) < threshold)
				{
					passengerNearDrivers[msg.sender][j++] = i;
				}
			}
			else
			{
				continue;
			}
			if(j >= maxNear)
			{
				break;
			}
		}
		return passengerNearDrivers[msg.sender];
	}

	function getDriverInfo(bool isPassenger) returns(int x, int y, address name, string info0, string info1, string info2)
	{
		uint driverIndex;
		address driver;
		if (isPassenger)
		{

			driver = orders[passengerToOrder[msg.sender]].driver;
		}
		else 
		{
			driver = msg.sender;
		}
		driverIndex = driverIndexs[driver];

		x = drivers[driverIndex].cor_x;
		y = drivers[driverIndex].cor_y;
		name = drivers[driverIndex].name;
		info0 = drivers[driverIndex].info0;
        info1 = drivers[driverIndex].info1;
        info2 = drivers[driverIndex].info2;
	}

    // function getDriverPos() returns(int x, int y)  //乘客调用
    // {
    //     uint driverIndex;
    //     address driver;

    //     driver = orders[passengerToOrder[msg.sender]].driver;
    //     driverIndex = driverIndexs[driver];

    //     x = drivers[driverIndex].cor_x;
    //     y = drivers[driverIndex].cor_y;
    // }

	function driverChangeInfo(string newInfo0, string newInfo1, string newInfo2) returns(bool)
	{
		if (driverIndexs[msg.sender] == 0)
		{
			return false;
		}
		drivers[driverIndexs[msg.sender]].info0 = newInfo0;
        drivers[driverIndexs[msg.sender]].info1 = newInfo1;
        drivers[driverIndexs[msg.sender]].info2 = newInfo2;
		return true;
	}


	function passengerCancelOrder(bool isPenalty) returns(bool) 
	{
		uint orderIndex = passengerToOrder[msg.sender];
		address driver = orders[orderIndex].driver;

		//乘客在司机接单前取消订单，没有任何惩罚
		if (passengerStates[msg.sender] == 1 && orders[orderIndex].state == 1)
		{
			passengerStates[msg.sender] = 0;
			orders[orderIndex].state = 4;
			return true;
		}

		//乘客在司机接单后、自己预付款前取消订单，没有惩罚
		if (passengerStates[msg.sender] == 2 && driverStates[driver] == 1 && orders[orderIndex].state == 2)
		{
			passengerStates[msg.sender] = 0;
			driverStates[driver] = 0;
			orders[orderIndex].state = 4;
			return true;
		}

		//乘客在预付款后、等待司机接客时取消订单
		if (passengerStates[msg.sender] == 3 && driverStates[driver] == 2 && orders[orderIndex].state == 2)
		{
			//退还预付款
			if (!carcoin.confirm(msg.sender, driver, orders[orderIndex].preFee, 0))
			{
				return false;
			}
			//违约金
			if (isPenalty)
			{
				carcoin.penalty(msg.sender, driver, penaltyPrice);
			}
			passengerStates[msg.sender] = 0;
			driverStates[driver] = 0;
			orders[orderIndex].state = 4;
			return true;
		}

		return false;
	}

	function driverCancelOrder() returns(bool) 
	{
		uint orderIndex = driverToOrder[msg.sender];
		address passenger = orders[orderIndex].passenger;

		if (driverStates[msg.sender] == 1 && passengerStates[passenger] == 2 && orders[orderIndex].state == 2)
		{
			passengerStates[passenger] = 0;
			driverStates[msg.sender] = 0;
			orders[orderIndex].state = 4;
			return true;
		}

		if (driverStates[msg.sender] == 2 && passengerStates[passenger] == 3 && orders[orderIndex].state == 2)
		{
			//退还预付款
			if (!carcoin.confirm(passenger, msg.sender, orders[orderIndex].preFee, 0))
			{
				return false;
			}
			carcoin.penalty(msg.sender, passenger, penaltyPrice);
			passengerStates[passenger] = 0;
			driverStates[msg.sender] = 0;
			orders[orderIndex].state = 4;
			return true;
		}

		return false;
	}


	function passengerJudge(int score, string comment) returns(bool)
	{
		uint orderIndex = passengerToOrder[msg.sender];
		address driver = orders[orderIndex].driver;
		int total = driverJudgements[driver].total;
		
		if (orderIndex == 0)
		{
			return false;
		}

		passengerToOrder[msg.sender] = 0;
		if (score > 5000)
			score = 5000;
		if (score < 0)
			score = 0;
		driverJudgements[driver].avgScore = (driverJudgements[driver].avgScore * total + score) / (total + 1);
		driverJudgements[driver].total += 1;
		total++;
		driverJudgements[driver].score[total] = score;
		driverJudgements[driver].comment[total] = comment;
		return true;
	}

	function getJudge(bool isPassenger) returns(int avgScore, int total)
	{
		address driver;
		if (isPassenger)
		{
			uint orderIndex = passengerToOrder[msg.sender];
			driver = orders[orderIndex].driver;
		}
		else 
		{
			driver = msg.sender;
		}
		avgScore = driverJudgements[driver].avgScore;
		total = driverJudgements[driver].total;
	}



	function getAccountBalance() returns(int)
	{
		return carcoin.getBalance(msg.sender);
	}

	function verify() returns(address)
	{
		return carcoin.verify1();
	}


	function updatePassengerPos(int x, int y) 
	{
		passPos[msg.sender].x = x;
		passPos[msg.sender].y = y;
	}


	function tsTotalNumOfOrder() returns(uint)
	{
		return counterOrderIndex - 1;
	}

	function tsTotalNumOfDriver() returns(uint)
	{
		return counterDriverIndex - 1;
	}

	function tsDriverInfoIdx(uint driverIndex) returns(int x, int y, address name, string info0, string info1, string info2)
	{
		x = drivers[driverIndex].cor_x;
		y = drivers[driverIndex].cor_y;
		name = drivers[driverIndex].name;
		info0 = drivers[driverIndex].info0;
        info1 = drivers[driverIndex].info1;
        info2 = drivers[driverIndex].info2;
	}

	function tsDriverInfoAddr(address addr) returns(int x, int y, address name, string info0, string info1, string info2)
	{
		uint driverIndex;
		address driver = addr;

		driverIndex = driverIndexs[driver];
		x = drivers[driverIndex].cor_x;
		y = drivers[driverIndex].cor_y;
		name = drivers[driverIndex].name;
		info0 = drivers[driverIndex].info0;
        info1 = drivers[driverIndex].info1;
        info2 = drivers[driverIndex].info2;
	}
}










