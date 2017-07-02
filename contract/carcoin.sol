pragma solidity ^0.4.6;

contract CarCoin 
{
    mapping (address => int) balances;
    address owner;
    address taxi;
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

    function tsTotalNumOfRecord(uint idx) returns(uint)
    {
    	return counter;
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
            taxi = addr;
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
        b = taxi;
        c = owner;
    }

    function verify1() returns(address)
    {
    	return msg.sender;
    }

    function prepay(address client, int preFee) returns(bool success) 
    {   
        if (msg.sender != taxi)
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
        if (msg.sender != taxi)
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
        if (msg.sender != taxi)
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
        // if (balances[owner] < amount)
        // {
        //     return false;
        // }
        balances[addr] += amount;
        balances[owner] -= amount;
        Transfer(this, addr, amount, "recharge");
        return true;
    }
}