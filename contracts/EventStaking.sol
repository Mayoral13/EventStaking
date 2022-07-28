pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract EventStaking is ERC20,Ownable{
    using SafeMath for uint;
    constructor()
    ERC20("EVENTSTK","ESTK"){

    }
    struct Event{
        string title;
        address host;
        uint fee;
        uint size;
        uint time;
        bool started;
    }
    uint private rate = 40000000000000;
    uint private eventId = 1;
    uint private ListFee = 0.01 ether;
    uint[]AttendableEvents;
    mapping(address => bool)EventHost;
    mapping(address => uint)Bought;
    mapping(address => uint[])Eventcount;
    mapping(address => uint)Sold;
    mapping(uint => Event)events;
    mapping(uint => address)Host;
    mapping(uint => uint)Eventsize;
    event rateSet(address indexed _from,uint _value);
    event ownerChange(address indexed _from,address indexed _to);
    event tokensBought(address indexed _from,uint _value);
    event tokensSold(address indexed _from,uint _value);
    event withdraw(address indexed _from,address indexed _to,uint _value);

     modifier OnlyOwner(){
        require(msg.sender == owner,"Unauthorized Access");
        _;
    }
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
      Host[eventId] = msg.sender;
      AttendableEvents.push(eventId);
      eventId++;
      return true;
    }
    function AttendEvent(uint id)external returns(bool success){
        require(Eventsize[id] <= events[id].size,"Capacity reached");
        require(balanceOf(msg.sender) >= events[id].fee,"Insufficient Token Balance");
        require(events[id].started == true,"Event has already started");
        _mint(Host[eventId],events[id].fee);
        _burn(msg.sender,events[id].fee);
        Eventsize[id]++;
        return true;
    }
    function StartEvent(uint id)external returns(bool success){
        require(msg.sender == Host[id],"You are not the event host");
        require(block.timestamp > events[id].time,"Wait till time is reached");
        require(events[id].started == false,"Event has already started");
        events[id].started = true;
        EventChecker(id);
        return true;
    }

    function EventChecker(uint id)internal returns(bool success){
     if(events[id].started == true){
        AttendableEvents.pop();
     }
     return true;
    }
    function SearchEvent(uint id)public view returns(string memory _title,address _host,uint _fee,uint _size,uint _time,bool _started){
     require(id != 0,"No such event exists");
     require(events[id].time != 0 ,"No such event exists");
     _title = events[id].title; 
     _host = events[id].host;
     _fee = events[id].fee;
     _size = events[id].size;
     _time = events[id].time;
     _started = events[id].started;
    } 

    function ShowAllEvents()public view returns(uint[]memory){
        return AttendableEvents;
    }
    
    function ShowEventsByUser(address _user)public view returns(uint[]memory){
        require(EventHost[_user] == true ,"User must host an event first");
        return Eventcount[_user];
    }

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
     function WithdrawETH(address payable _to,uint amount)external OnlyOwner payable returns(bool success){
        require(address(this).balance >= amount,"Insufficient Balance");
        _to.transfer(amount);
        emit withdraw(msg.sender,_to,amount);
        return true;
    }
     function BalanceVendor()public view returns(uint){
        return address(this).balance;
    }
     function Balance()public view returns(uint){
        return balanceOf(msg.sender);
    }

    
    
}