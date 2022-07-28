pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract EventStaking is ERC20,Ownable{
    using SafeMath for uint;
    constructor()
    ERC20("EVENTSTK","ESTK"){

    }
    //STRUCT FOR THE EVENT MAKING
    struct Event{
        string title;
        address host;
        uint fee;
        uint size;
        uint time;
        address[]guests;
        bool started;
    }
    //UINT TO SET RATE FOR BUYING AND SELLING TOKENS
    uint private rate = 1;
    //UINT TO KEEP COUNT OF EVENT ID
    uint private eventId = 1;
    //UINT TO KKEP TRACK OF FEE TO BE PAID
    uint private ListFee = 0.01 ether;
    //ARRAY OF UINT TO KEEP TRACK OF EVENTS
    uint[]AttendableEvents;
   
    //MAPPING TO KEEP TRACK OF EVENTS HELD BY USERS
    mapping(uint => Event)events;
    //MAPPING TO KEEP TRACK OF EVENT SIZE
    mapping(uint => uint)Eventsize;
    //MAPPING TO KEEP TRACK OF WHETHER ADDRESS IS EVENT HOST
    mapping(address => bool)EventHost;
    //MAPPING TO KEEP TRACK OF THE ID OF THE EVENTS HOSTED BY USERS
    mapping(address => uint[])Eventcount;
    //MAPPING TO KKEP TRACK OF WHETHER HOST OF EVENT HAS STARTED EVENT 
    mapping(uint => mapping(address => bool))Started;
    //MAPPING TO KEEP TRACK OF WHETHER USER HAS CHECKED INTO AN EVENT
    mapping(uint => mapping(address => bool))Attended;

    /****************EVENTS*******************/
    event tokensBought(address indexed _from,uint _value);
    event tokensSold(address indexed _from,uint _value);
    event withdraw(address indexed _from,address indexed _to,uint _value);
    event createEvent(address indexed _by,uint _time);
    event attendEvent(address indexed _by,uint _time);
    event startEvent(address indexed _by,uint _time);

     modifier OnlyOwner(){
        require(msg.sender == owner,"Unauthorized Access");
        _;
    }
    //FUNCTION FOR CREATING EVENTS FEE OF 0.01ETH MUST BE PAID
    function CreateEvent(string memory _title,uint _fee,uint _size,uint _time)external payable returns(bool success){
      require(msg.value == ListFee,"Send the required amount");
      require(_size != 0,"You need people for an event bruh!");
      require(_time.add(block.timestamp) > block.timestamp,"Set a time greater than current time");
      events[eventId].host = msg.sender;
      events[eventId].title = _title;
      events[eventId].fee = _fee;
      events[eventId].size = _size;
      events[eventId].time = _time.add(block.timestamp);
      Eventcount[msg.sender].push(eventId);
      EventHost[msg.sender] = true;
      AttendableEvents.push(eventId);
      eventId++;
      emit createEvent(msg.sender,block.timestamp);
      return true;
    }
    //FUNCTION TO ATTEND EVENT ID OF THE EVENT MUST BE PUT
    function AttendEvent(uint id)external returns(bool success){
        require(Eventsize[id] != events[id].size,"Capacity Reached");
        require(Attended[id][msg.sender] == false,"You have checked in");
        require(balanceOf(msg.sender) >= events[id].fee,"Insufficient Token Balance");
        require(events[id].started == true,"Event has not started");
        _mint(events[id].host,events[id].fee);
        _burn(msg.sender,events[id].fee);
        events[id].guests.push(msg.sender);
        Attended[id][msg.sender] = true;
        Eventsize[id]++;
        emit attendEvent(msg.sender,block.timestamp);
        return true;
    }
    //FUNCTION TO START EVENT ONLY EVENT HOST CAN CALL IT
    function StartEvent(uint id)external returns(bool success){
        require(msg.sender == events[id].host,"You are not the event host");
        require(block.timestamp > events[id].time,"Wait till time is reached");
        require( Started[id][events[id].host] == false,"You have already started the event");
        events[id].started = true;
        Started[id][events[id].host] = true;
        emit startEvent(msg.sender,block.timestamp);
        return true;
    }
    //FUNCTION TO SEARCH AN EVENT AND ALL IT DETAILS
    function SearchEvent(uint id)public view returns(string memory _title,address _host,uint _fee,uint _size,uint _time,bool _started,address[]memory _guests){
     require(id != 0,"No such event exists");
     require(events[id].time != 0 ,"No such event exists");
     _title = events[id].title; 
     _host = events[id].host;
     _fee = events[id].fee;
     _size = events[id].size;
     _time = events[id].time;
     _started = events[id].started;
     _guests = events[id].guests;
    } 
     
     //FUNCTION TO SHOW ALL EVENTS
    function ShowAllEvents()public view returns(uint[]memory){
        return AttendableEvents;
    }
    
    //FUNCTION TO SHOW EVENTS ID HOSTED BY USERS
    function ShowEventsByUser(address _user)public view returns(uint[]memory){
        require(EventHost[_user] == true ,"User must host an event first");
        return Eventcount[_user];
    }
    
    //FUNCTION TO BUY TOKENS YOU NEED TOKENS TO ATTEND EVENTS
    function BuyTokens()external payable returns(bool success){
        require(rate != 0,"Rate has not been set");
        require(msg.value != 0,"You cannot send nothing");
        uint bought = msg.value.div(rate);
        uint fee = (bought.mul(10)).div(100);
        uint recieve = bought.sub(fee);
        bought = msg.value.div(rate);
        _mint(msg.sender,recieve);
        _mint(address(this),fee);
        emit tokensBought(msg.sender,bought);
        return true;
    }
    //FUNCTION TO SELL TOKENS
     function SellTokens(uint amount)external returns(bool success){
        uint sold = amount.mul(rate);
        uint fee = (amount.mul(10)).div(100);
        uint recieve = sold.sub(fee);
        uint UserBalance = balanceOf(msg.sender);
        require(amount != 0,"You cannot sell nothing");
        require(UserBalance >= amount,"Insufficient Amount Of Tokens");
        require(rate != 0,"Rate has not been set");
        require(BalanceVendor() >= sold,"Insufficient Cash");
        _burn(msg.sender,amount);
        _mint(address(this),fee);
        payable(msg.sender).transfer(recieve);
        emit tokensSold(msg.sender,amount);
        return true;
    }
    //FUNCTION TO WITHDRAW ETH ONLY OWNER CAN USE
     function WithdrawETH(address payable _to,uint amount)external OnlyOwner payable returns(bool success){
        require(address(this).balance >= amount,"Insufficient Balance");
        _to.transfer(amount);
        emit withdraw(msg.sender,_to,amount);
        return true;
    }
    //FUNCTION TO RETURN ETH BALANCE OF ADDRESS
     function BalanceVendor()public view returns(uint){
        return address(this).balance;
    }
    //FUNCTION TO RETURN TOKEN BALANCE OF USER
     function TokenBalance()public view returns(uint){
        return balanceOf(msg.sender);
    }

    
    
}