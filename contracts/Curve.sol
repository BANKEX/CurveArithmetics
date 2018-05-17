pragma solidity ^0.4.23;

import {ECCMath} from "./ECCMath.sol";

interface CurveInterface {
    function getOrder() external view returns(uint order);
    function validateSignature(bytes32 message, uint[2] rs, uint[2] Q) external view returns (bool);
}

/**
 * @title Particular curve implementation
 *
 * Based on reworked ECCMath from Andreas Olofsson using modern precompiles
 * and his _add, _double and _add implementations. Added "toAffine" public method for convenience.
 *
 * Performs curve arithmetics and verifies signatures.
 *
 * @author Alexander Vlasov (alex.m.vlasov@gmail.com).
 */

contract Curve {

    // Field size
    uint public pp;

    // Base point (generator) G
    uint public Gx;
    uint public Gy;

    // Order of G
    uint public nn;

    // Curve parameters
    uint public aa;
    uint public bb;

    // Cofactor
    uint public hh;

    // Maximum value of s
    uint public lowSmax;

    uint[3] public pointOfInfinity = [0, 1, 0];

    constructor (uint256 fieldSize, uint256 groupOrder, uint256 lowS, uint256 cofactor, uint256[2] generator, uint256 a, uint256 b) public {
        pp = fieldSize;
        nn = groupOrder;
        lowSmax = lowS;
        hh = cofactor;
        Gx = generator[0];
        Gy = generator[1];
        aa = a;
        bb = b;
        uint det = mulmod(a,a,fieldSize); //a^2
        det = mulmod(det,a,fieldSize); //a^3
        det = mulmod(4,det,fieldSize); //4*a^3
        uint det2 = mulmod(b,b,fieldSize); //b^2
        det2 = mulmod(27,det2,fieldSize); //27*b^2
        require(addmod(det, det2, fieldSize) != 0); // 4*a^3 + 27*b^2 != 0
        if (lowSmax == 0) {
            lowSmax = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        }
    }

    function getPointOfInfinity() public view returns (uint[3] Q) {
        return pointOfInfinity;
    }

    function getOrder() public view returns(uint order) {
        return nn;
    }

    // Point addition, P + Q
    // inData: Px, Py, Pz, Qx, Qy, Qz
    // outData: Rx, Ry, Rz
    function _add(uint[3] P, uint[3] Q) 
    public 
    view 
    returns (uint[3] R) {
        if(P[2] == 0)
            return Q;
        if(Q[2] == 0)
            return P;
        uint p = pp;
        uint[4] memory zs; // Pz^2, Pz^3, Qz^2, Qz^3
        zs[0] = mulmod(P[2], P[2], p);
        zs[1] = mulmod(P[2], zs[0], p);
        zs[2] = mulmod(Q[2], Q[2], p);
        zs[3] = mulmod(Q[2], zs[2], p);
        uint[4] memory us;
        us[0] = mulmod(P[0], zs[2], p);
        us[1] = mulmod(P[1], zs[3], p);
        us[2] = mulmod(Q[0], zs[0], p);
        us[3] = mulmod(Q[1], zs[1], p);
        // Pu, Ps, Qu, Qs
        if (us[0] == us[2]) {
            if (us[1] != us[3])
                return pointOfInfinity;
            else {
                return _double(P);
            }
        }
        uint h = addmod(us[2], p - us[0], p);
        uint r = addmod(us[3], p - us[1], p);
        uint h2 = mulmod(h, h, p);
        uint h3 = mulmod(h2, h, p);
        uint Rx = addmod(mulmod(r, r, p), p - h3, p);
        uint uh2 = mulmod(us[0], h2, p);
        Rx = addmod(Rx, p - mulmod(2, uh2, p), p);
        R[0] = Rx;
        R[1] = mulmod(r, addmod(uh2, p - Rx, p), p);
        R[1] = addmod(R[1], p - mulmod(us[1], h3, p), p);
        R[2] = mulmod(h, mulmod(P[2], Q[2], p), p);
        return R;
    }


    // Point addition, P + Q. P Jacobian, Q affine.
    // inData: Px, Py, Pz, Qx, Qy
    // outData: Rx, Ry, Rz
    function _addMixed(uint[3] P, uint[2] Q) public view returns (uint[3] R) {
        if(P[2] == 0)
            return [Q[0], Q[1], 1];
        if(Q[1] == 0)
            return P;
        uint p = pp;
        uint[2] memory zs; // Pz^2, Pz^3, Qz^2, Qz^3
        zs[0] = mulmod(P[2], P[2], p);
        zs[1] = mulmod(P[2], zs[0], p);
        uint[4] memory us = [
            P[0],
            P[1],
            mulmod(Q[0], zs[0], p),
            mulmod(Q[1], zs[1], p)
        ]; // Pu, Ps, Qu, Qs
        if (us[0] == us[2]) {
            if (us[1] != us[3]) {
                return pointOfInfinity;
            }
            else {
                return _double(P);
            }
        }
        uint h = addmod(us[2], p - us[0], p);
        uint r = addmod(us[3], p - us[1], p);
        uint h2 = mulmod(h, h, p);
        uint h3 = mulmod(h2, h, p);
        uint Rx = addmod(mulmod(r, r, p), p - h3, p);
        Rx = addmod(Rx, p - mulmod(2, mulmod(us[0], h2, p), p), p);
        R[0] = Rx;
        R[1] = mulmod(r, addmod(mulmod(us[0], h2, p), p - Rx, p), p);
        R[1] = addmod(R[1], p - mulmod(us[1], h3, p), p);
        R[2] = mulmod(h, P[2], p);
        return R;
    }

    // Point doubling, 2*P
    // Params: Px, Py, Pz
    // Not concerned about the 1 extra mulmod.
    function _double(uint[3] P) public view returns (uint[3] Q) {
        uint p = pp;
        uint a = aa;
        if (P[2] == 0)
            return pointOfInfinity;
        uint Px = P[0];
        uint Py = P[1];
        uint Py2 = mulmod(Py, Py, p);
        uint s = mulmod(4, mulmod(Px, Py2, p), p);
        uint m = mulmod(3, mulmod(Px, Px, p), p);
        if (a != 0) {
            uint z2 = mulmod(P[2], P[2], p);
            m = addmod(m, mulmod(mulmod(z2, z2, p), a, p), p);
        }
        uint Qx = addmod(mulmod(m, m, p), p - addmod(s, s, p), p);
        Q[0] = Qx;
        Q[1] = addmod(mulmod(m, addmod(s, p - Qx, p), p), p - mulmod(8, mulmod(Py2, Py2, p), p), p);
        Q[2] = mulmod(2, mulmod(Py, P[2], p), p);
        return Q;
    }

    // Multiplication dP. P affine, wNAF: w=5
    // Params: d, Px, Py
    // Output: Jacobian Q
    function _mul(uint d, uint[2] P) public view returns (uint[3] Q) {
        uint p = pp;
        if (d == 0) {
            return pointOfInfinity;
        }
        uint dwPtr; // points to array of NAF coefficients.
        uint i;

        // wNAF
        assembly
        {
            let dm := 0
            dwPtr := mload(0x40)
            mstore(0x40, add(dwPtr, 512)) // Should lower this.
        loop:
            jumpi(loop_end, iszero(d))
            jumpi(even, iszero(and(d, 1)))
            dm := mod(d, 32)
            mstore8(add(dwPtr, i), dm) // Don't store as signed - convert when reading.
            d := add(sub(d, dm), mul(gt(dm, 16), 32))
        even:
            d := div(d, 2)
            i := add(i, 1)
            jump(loop)
        loop_end:
        }

        // Pre calculation
        uint[3][8] memory PREC; // P, 3P, 5P, 7P, 9P, 11P, 13P, 15P
        PREC[0] = [P[0], P[1], 1];
        uint[3] memory X = _double(PREC[0]);
        PREC[1] = _addMixed(X, P);
        PREC[2] = _add(X, PREC[1]);
        PREC[3] = _add(X, PREC[2]);
        PREC[4] = _add(X, PREC[3]);
        PREC[5] = _add(X, PREC[4]);
        PREC[6] = _add(X, PREC[5]);
        PREC[7] = _add(X, PREC[6]);

        // Mult loop
        while(i > 0) {
            uint dj;
            uint pIdx;
            i--;
            assembly {
                dj := byte(0, mload(add(dwPtr, i)))
            }
            Q = _double(Q);
            if (dj > 16) {
                pIdx = (31 - dj) / 2; // These are the "negative ones", so invert y.
                Q = _add(Q, [PREC[pIdx][0], p - PREC[pIdx][1], PREC[pIdx][2] ]);
            }
            else if (dj > 0) {
                pIdx = (dj - 1) / 2;
                Q = _add(Q, [PREC[pIdx][0], PREC[pIdx][1], PREC[pIdx][2] ]);
            }
            if (Q[0] == pointOfInfinity[0] && Q[1] == pointOfInfinity[1] && Q[2] == pointOfInfinity[2]) {
                return Q;
            }
        }
        return Q;
    }

    function onCurve(uint[2] P) public view returns (bool) {
        uint p = pp;
        uint a = aa;
        uint b = bb;
        if (0 == P[0] || P[0] == p || 0 == P[1] || P[1] == p)
            return false;
        uint LHS = mulmod(P[1], P[1], p); // y^2
        uint RHS = mulmod(mulmod(P[0], P[0], p), P[0], p); // x^3
        if (a != 0) {
            RHS = addmod(RHS, mulmod(P[0], a, p), p); // x^3 + a*x
        }
        if (b != 0) {
            RHS = addmod(RHS, b, p); // x^3 + a*x + b
        }
        return LHS == RHS;
    }

    /// @dev See Curve.isPubKey
    function isPubKey(uint[2] P) public view returns (bool isPK) {
        isPK = onCurve(P);
        return isPK;
    }

    /// @dev See Curve.validateSignature
    function validateSignature(bytes32 message, uint[2] rs, uint[2] Q) public view returns (bool) {
        uint n = nn;
        uint p = pp;
        if(rs[0] == 0 || rs[0] >= n || rs[1] == 0 || rs[1] > lowSmax)
            return false;
        if (!isPubKey(Q))
            return false;

        uint sInv = ECCMath.invmod(rs[1], n);
        uint[3] memory u1G = _mul(mulmod(uint(message), sInv, n), [Gx, Gy]);
        uint[3] memory u2Q = _mul(mulmod(rs[0], sInv, n), Q);
        uint[3] memory P = _add(u1G, u2Q);

        if (P[2] == 0)
            return false;

        uint Px = ECCMath.invmod(P[2], p); // need Px/Pz^2
        Px = mulmod(P[0], mulmod(Px, Px, p), p);
        return Px % n == rs[0];
    }

    function computePublicKey(uint priv) public view returns(uint[2] Q) {
        uint[2] memory generator = [Gx, Gy];
        uint[3] memory P = _mul(priv, generator);
        return toAffine(P);
    }

    // @dev Only used on the local node
    function createSignature(bytes32 message, uint k, uint priv) public view returns (uint r, uint s) {
        uint p = pp;
        uint n = nn;
        uint[2] memory generator = [Gx, Gy];
        uint[3] memory P = _mul(k, generator);
        ECCMath.toZ1(P, p);
        r = P[0];
        s = mulmod(priv, r, n);
        s = addmod(uint(message), s, n);
        uint k_1 = ECCMath.invmod(k, n); 
        s = mulmod(k_1, s, n);
        return (r, s);
    }

    /// @dev See Curve.compress
    function compress(uint[2] P) public pure returns (uint8 yBit, uint x) {
        x = P[0];
        yBit = P[1] & 1 == 1 ? 1 : 0;
        return (yBit, x);
    }

    /// @dev See Curve.decompress
    function decompress(uint8 yBit, uint x) public view returns (uint[2] P) {
        uint p = pp;
        uint a = aa;
        uint b = bb;
        uint y2 = mulmod(x, mulmod(x, x, p), p);
        if (a != 0) {
            y2 = addmod(y2, mulmod(x, a, p), p);
        }
        if (b != 0) {
            y2 = addmod(y2, b, p);
        }
        uint y_ = 0;
        if (p % 4 == 3) {
            y_ = ECCMath.expmod(y2, (p + 1) / 4, p);
        } else {
            return;
            //TODO general algo or other fact methods here
            // revert();
        }
        uint cmp = yBit ^ y_ & 1;
        P[0] = x;
        P[1] = (cmp == 0) ? y_ : p - y_;
        return P;
    }

    function toAffine(uint[3] P) public view returns (uint[2] Q) {
        uint p = pp;
        ECCMath.toZ1(P, p);
        Q[0] = P[0];
        Q[1] = P[1];
        return Q;
    }
}