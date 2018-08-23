pragma solidity ^0.4.23;

import {GenericCurveFactory} from "./CurveFactory.sol";
import {CurveInterface} from "./Curve.sol";
import {IInstance} from "./IInstance.sol";

contract TreasureChestInstance is IInstance
{  
    address public curve;
    uint256[2] public publicKey;
    bytes32 public messageHash;
    bool public isOpen;

    constructor(address _curve, bytes32 _messageHash, uint[2] _publicKey) public {
        curve = _curve;
        publicKey = _publicKey;
        messageHash = _messageHash;
    }

    function findTreasure(uint256[2] sig) public returns (bool) {
        CurveInterface c = CurveInterface(curve);
        if (!c.validateSignature(messageHash, sig, publicKey)) {
            return false;
        }

        isOpen = true;
        return true;
    }

    function status() public view returns (bool) {
        return isOpen;
    }

}