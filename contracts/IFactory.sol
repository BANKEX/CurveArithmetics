pragma solidity ^0.4.23;

contract IFactory {
    function deploy() public returns(address);
    function factoryName() public view returns(string);
    function factoryAmount() public view returns(uint);
}
