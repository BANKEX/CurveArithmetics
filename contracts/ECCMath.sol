pragma solidity ^0.4.23;

/**
 * @title ECCMath
 *
 * Functions for working with integers, curve-points, etc.
 *
 * @author Andreas Olofsson (androlo1980@gmail.com). Reworked by Alexander Vlasov (alex.m.vlasov@gmail.com)
 */
library ECCMath {

    /// @dev Modular inverse of a (mod p) using euclid.
    /// 'a' and 'p' must be co-prime.
    /// @param a The number.
    /// @param p The mmodulus.
    /// @return x such that ax = 1 (mod p)
    function invmod(uint a, uint p) internal pure returns (uint) {
        if (a == 0 || a == p || p == 0)
            return 0;
        if (a > p)
            a = a % p;
        int t1;
        int t2 = 1;
        uint r1 = p;
        uint r2 = a;
        uint q;
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(q) * t2, r2, r1 - q * r2);
        }
        if (t1 < 0)
            return (p - uint(-t1));
        return uint(t1);
    }

    /// @dev Modular exponentiation, b^e % m
    /// Uses precompile for computation
    /// @param b The base.
    /// @param e The exponent.
    /// @param m The modulus.
    /// @return x such that x = b**e (mod m)
    function expmod(uint256 b, uint256 e, uint256 m) internal view returns (uint256) {
        uint256[6] memory input;
        uint256[1] memory output;
        input[0] = 0x20;  // length_of_BASE
        input[1] = 0x20;  // length_of_EXPONENT
        input[2] = 0x20;  // length_of_MODULUS
        input[3] = b;
        input[4] = e;
        input[5] = m;
        assembly {
            if iszero(staticcall(not(0), 5, input, 0xc0, output, 0x20)) {
                revert(0, 0)
            }
        }
        return output[0];
    }

    /// @dev Converts a point (Px, Py, Pz) expressed in Jacobian coordinates to (Px', Py', 1).
    /// Mutates P.
    /// @param P The point.
    /// @param zInv The modular inverse of 'Pz'.
    /// @param z2Inv The square of zInv
    /// @param prime The prime modulus.
    /// @return (Px', Py', 1)
    function toZ1(uint[3] memory P, uint zInv, uint z2Inv, uint prime) internal pure {
        P[0] = mulmod(P[0], z2Inv, prime);
        P[1] = mulmod(P[1], mulmod(zInv, z2Inv, prime), prime);
        P[2] = 1;
    }

    /// @dev See _toZ1(uint[3], uint, uint).
    /// Warning: Computes a modular inverse.
    /// @param PJ The point.
    /// @param prime The prime modulus.
    /// @return (Px', Py', 1)
    function toZ1(uint[3] PJ, uint prime) internal pure {
        uint zInv = invmod(PJ[2], prime);
        uint zInv2 = mulmod(zInv, zInv, prime);
        PJ[0] = mulmod(PJ[0], zInv2, prime);
        PJ[1] = mulmod(PJ[1], mulmod(zInv, zInv2, prime), prime);
        PJ[2] = 1;
    }

}