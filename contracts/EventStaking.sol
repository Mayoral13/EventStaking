pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract EventStaking is ERC20,Ownable{
    constructor()
    ERC20("EVENTSTK","ESTK"){

    }
    
    
}