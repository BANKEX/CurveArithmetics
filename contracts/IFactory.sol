pragma solidity ^0.4.23;

contract IFactory {
  function deploy() public returns(address);
  function factoryName() public returns(string);
  function factoryAmount() public returns(uint);
}
