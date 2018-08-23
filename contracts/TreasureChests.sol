pragma solidity ^0.4.23;

import {GenericCurveFactory} from "./CurveFactory.sol";
import {CurveInterface} from "./Curve.sol";

contract TreasureChests
{  
    struct Vault
    {
        address curve;
        uint[2] publicKey;
        address thePirate;
        string yohoho;
        bool isOpen;
    }

    Vault[] public treasures;

    constructor(address[] _curves, uint[] _publicKeys) public {
        require(_curves.length * 2 == _publicKeys.length);
        uint256[2] memory pubkey = [uint256(0), uint256(0)];
        for (uint256 i = 0; i < _curves.length; i++) {
            pubkey[0] = _publicKeys[2*i];
            pubkey[1] = _publicKeys[2*i+1];
            Vault memory newVault = Vault({
                curve: _curves[i],
                publicKey: pubkey,
                thePirate: address(0),
                isOpen: false,
                yohoho: ""
            });
            treasures.push(newVault);
        }
    }

    function findTreasure(uint256 i, string message, uint256[2] sig) public returns (bool) {
        Vault storage vault = treasures[i];
        require(vault.curve != address(0));
        CurveInterface curve = CurveInterface(vault.curve);
        bytes32 messageHash = keccak256(abi.encodePacked(message));
        if (!curve.validateSignature(messageHash, sig, vault.publicKey)) {
            return false;
        }

        if (vault.thePirate == address(0)) {
            vault.thePirate = msg.sender;
            vault.isOpen = true;
            vault.yohoho = message;
        }

        return true;
    }
}