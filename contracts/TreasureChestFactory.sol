pragma solidity ^0.4.23;

import {IFactory} from "./IFactory.sol";
import {TreasureChestInstance} from "./TreasureChestInstance.sol";

contract TreasureChestFactory is IFactory{
    address curve;
    uint256[2] publicKey;
    string name;
    uint256 difficulty;
    uint256 counter = 0;

    constructor(address _curve, uint256[2] _publicKey, string _name, uint256 _difficulty) {
        curve = _curve;
        publicKey = _publicKey;
        name = _name;
        difficulty = _difficulty;
    }

    function deploy() public returns(address) {
        counter = counter + 1;
        bytes32 messageHash = keccak256(abi.encodePacked(name, counter));
        return address(new TreasureChestInstance(curve, messageHash, publicKey));
    }

    function factoryName() public returns(string) {
        return name;
    }
    function factoryAmount() public returns(uint) {
        return difficulty;
    }
}
