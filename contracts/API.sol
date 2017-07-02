// 打车合约API定义说明 
// Version 0.3.9

//-------------------------------------------//


/*变量的定义*/
//uint int 均为32位整型
//address 是地址类型，在智能合约中可以唯一的确定某一个账户，即可作为账户的名字或者标识

mapping (address => uint) passengerToOrder;   //每个乘客对应到某个订单
mapping (address => uint) driverToOrder;      //每个司机对应到某个订单
uint counterOrderIndex;                       //下一个空的订单序号
//订单需要的信息
struct Order
{
    uint id;                //订单编号
    address passenger;      //乘客地址
    address driver;         //司机地址
    //经纬度格式：小数点后保留四位然后乘10000转化为整形，经纬度之差最大是3.2700度，约为300km之差，小数点后四位表示的实际精度为10米
    int s_x;                //起点经度 
    int s_y;                //起点纬度
    int d_x;                //终点经度
    int d_y;                //终点纬度
    string sName;           //起点地名
    string dName;           //终点地名
    int distance;           //起终点直线距离
    int preFee;             //预付款额
    int actFee;             //实际款额
    uint startTime;         //UNIX标准时间，单位为 秒
    uint endTime;           //UNIX标准时间，单位为 秒
    int state;              //订单状态 1待分配 2已被抢 3订单完成 4订单终止 其他状态为非法
    string passInfo;        //乘客个人信息，utf8
    string drivInfo;        //司机个人信息，utf8
}
mapping (uint => Order) orders;

mapping (address => uint) driverIndexs; //给每个司机分配一个内部的序号，从1开始，0号表示非法
uint counterDriverIndex;                //下一个空的司机序号（当前司机数量+1）

//司机的有关信息
struct Driver
{
    int cor_x;                            //经度
    int cor_y;                            //纬度
    bool state;                           //true 表示接单中 false 表示休息中
    address name;                         //司机地址
    string info;                          //司机信息
    uint counterOrder;                    //司机当前可接订单数
    uint[8] orderPool;                    //司机可接订单池
    int last_x;                           //上一次经度
    int last_y;                           //上一次纬度
}
mapping (uint => Driver) drivers;        //使用序号去寻找司机的信息

//轮循查询状态
//挂起 订单分配中 待付款 行程中 => 0 1 2 3
mapping (address => uint) passengerStates;    //乘客状态
//挂起 已接单 行程中 => 0 1 2
mapping (address => uint) driverStates;        //司机状态

mapping (address => address) driverLinks;
mapping (address => address) passengerLinks;

//乘客附近的司机，最大数量为5
mapping (address => uint[5]) passengerNearDrivers;

//司机评价
mapping (address => Judgement) driverJudgements;


//里程单价
int unitPrice = 1;

//违约金
int penaltyPrice = 5;



//四个私有函数，调用者请无视
/*
function Taxing() 

function sqrt(int x) private returns (int)

function calculateDistance(int x0, int x1, int y0, int y1) private returns(int)

function driverSelction(int x, int y, uint orderIndex) private returns(bool)

function calculatePreFee(int s_x, int s_y, int d_x, int d_y) private returns(int)
*/

// 描述：乘客提交订单函数
// 参数：起点经度 起点纬度 终点经度 终点纬度 当前时间(Linux标准时单位秒) 乘客个人信息 起点地名 终点地名
// 返回值：返回新建的订单编号
// 备注：起终点的地名是新增的，用于展示在订单信息中，减少了反地理编码的开销
function passengerSubmitOrder(int s_x, int s_y, int d_x, int d_y, uint time, string passInfo, string sName, string dName) returns(uint)

// 描述：司机抢单函数
// 参数：要抢的订单编号
// 返回值：true 抢单成功
function driverCompetOrder(uint orderIndex) returns(bool)

// 描述：乘客预付款
// 参数：无
// 返回值：true 预付款成功
function passengerPrepayFee() returns(bool)

// 描述：司机接到乘客函数
// 参数：接到乘客的实际地点经纬度
// 返回值：true 成功
// 备注：该参数消除了由于订单起点和实际起点不同导致的计费偏差
function driverPickUpPassenger(int x, int y) returns(bool)

// 描述：司机计算实际费用，该函数要在行程开始之后轮循调用
// 参数：当前的经纬度
// 返回值：当前的费用
function driverCalculateActFee(int cur_x, int cur_y) returns(int)

// 描述：司机完成订单，表明行程结束
// 参数：结束时间
// 返回值：true 终止成功
function driverFinishOrder(uint time) returns(bool)

// 描述：获得司机状态
// 参数：无
// 返回值：状态值
function getDriverState() returns(uint)

// 描述：获得乘客状态
// 参数：无
// 返回值：状态值
function getPassengerState() returns(uint)

// 描述：获得司机注册状态
// 参数：无
// 返回值：true 已经注册
function getDriverRegiterState() returns(bool)

// 描述：新司机注册
// 参数：司机信息
// 返回值：司机内部编号
function newDriverRegister(string info0, string info1, string info2) returns(uint)

// 描述：司机更新当前位置
// 参数：当前经纬度 接单状态（true 接单）
// 返回值：true 更新成功
function driverUpdatePos(int x, int y, bool state) returns(bool)

// 描述：查看订单池
// 参数：无
// 返回值：返回8个订单池内的订单编号，若编号为0或者非0但订单状态不是1(待分配)，则为无效订单
function getDriverOrderPool() returns(uint[8])

// 描述：获得订单ID
// 参数：0 表示司机 1 表示乘客
// 返回值：该司机/乘客当前对应的正在进行中的订单编号
function getOrderID(bool isPassenger) returns(uint)

// 描述：下面一组函数用于查询订单的具体信息
// 参数：订单编号
// 返回值：订单各个信息（参看上面订单结构的定义）
// 备注：某些高频属性采用单独的函数返回
function getOrderInfoStatic(uint orderIndex) returns(uint id, address passenger, int s_x, int s_y, int d_x, int d_y, int distance, int preFee, uint startTime) 
function getOrderInfoDynamic(uint orderIndex) returns(address driver, int actFee, uint endTime, int state, string drivInfo)
function getOrderState(uint orderIndex) returns(int) 
function getOrderPreFee(uint orderIndex) returns(int) 
function getOrderActFee(uint orderIndex) returns(int) 
function getOrderPassInfo(uint orderIndex) returns(string)
function getOrderPlaceName(uint orderIndex) returns(string sName, string dName)
function getOrderStateAndDriverPos(uint orderIndex) returns(int state, int x, int y) //仅供乘客使用
function getOrderDrivInfo(uint orderIndex) returns(string drivInfo0, string drivInfo1, string drivInfo2)
function getOrderPassInfo(uint orderIndex) returns(string)
function getOrderDisAndActFee(uint orderIndex) returns(int distance, int actFee)

// 描述：获得附近的司机
// 参数：当前经纬度，范围
// 返回值：返回最多5个司机的司机编号
function getNearDrivers(int x, int y, int threshold) returns(uint[5])

// 描述：查询司机的信息
// 参数：司机编号
// 返回值：该司机当前经纬度，司机的名字（地址），司机的信息
function getDriverInfo(bool isPassenger) returns(int x, int y, address name, string info0, string info1, string info2)

// 描述：更新司机信息
// 参数：新的信息
// 返回值：true 更新成功
function driverChangeInfo(string newInfo0, string newInfo1, string newInfo2) returns(bool)

// 描述：乘客取消函数
// 参数：乘客预付款后如果超过三分钟，设置参数为true，使得乘客付出违约金
// 返回值：成功
function passengerCancelOrder(bool isPenalty) returns(bool) 

// 描述：司机取消函数
// 参数：无
// 返回值：成功
function driverCancelOrder() returns(bool) 

// 描述：乘客评价司机函数
// 参数：分数(小数点后三位 乘 1000) 评论
// 返回值：成功
function passengerJudge(int score, string comment) returns(bool)

// 描述：获得评价
// 参数：乘客调用请设置为true 司机调用设置为false
// 返回值：平均分和总评价数
function getJudge(bool isPassenger) returns(int avgScore, int total)

// 描述：给调用者充钱
// 参数：无
// 返回值：成功
function recharge() returns(bool)

// 描述：获得调用者的账户余额
// 参数：无
// 返回值：账户余额
function getAccountBalance() returns(int)








