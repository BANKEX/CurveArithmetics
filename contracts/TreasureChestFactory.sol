pragma solidity ^0.4.23;

import {IFactory} from "./IFactory.sol";
import {TreasureChestInstance} from "./TreasureChestInstance.sol";

contract TreasureChestFactory is IFactory{
    address public curve;
    uint256[2] public publicKey;
    string public name;
    uint256 public difficulty;
    uint256 counter = 0;

    event Deployed(address indexed _newInstance, bytes32 indexed _hash);

    constructor(address _curve, uint256[2] _publicKey, string _name, uint256 _difficulty) {
        curve = _curve;
        publicKey = _publicKey;
        name = _name;
        difficulty = _difficulty;
    }

    function deploy() public returns (address) {
        counter = counter + 1;
        bytes32 messageHash = keccak256(abi.encodePacked(name, counter));
        TreasureChestInstance newOne = new TreasureChestInstance(curve, messageHash, publicKey);
        emit Deployed(address(newOne), messageHash);
        return address(newOne);
    }

    function factoryName() public view returns (string) {
        return name;
    }

    function factoryAmount() public view returns (uint) {
        return difficulty;
    }
}
