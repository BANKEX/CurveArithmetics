pragma solidity ^0.4.23;

import {GenericCurveFactory} from "./CurveFactory.sol";
import {CurveInterface} from "./Curve.sol";
import {IInstance} from "./IInstance.sol";

contract TreasureChestInstance is IInstance
{  
    address curve;
    uint256[2] publicKey;
    bytes32 messageHash;
    bool isOpen;

    constructor(address _curve, bytes32 _messageHash, uint[2] _publicKey) public
    {
        curve = _curve;
        publicKey = _publicKey;
        messageHash = _messageHash;
    }

    function findTreasure(uint256[2] sig) public returns (bool success)
    {
        CurveInterface c = CurveInterface(curve);
        bool isValid = c.validateSignature(messageHash, sig, publicKey);
        if (!isValid) {
            return false;
        }
        isOpen = true;
        return true;
    }

    function status() public returns(bool) {
        return isOpen;
    }

}