const Curve = artifacts.require("Curve.sol");
const CurveFactory = artifacts.require("GenericCurveFactory.sol");
const util = require("util");
const testdata = require('./data/secp2561k_data.json');
const BN = require("bn.js");
const ethUtil = require("ethereumjs-util");
const assert = require("assert");
const t = require('truffle-test-utils');
const async = require("async");
t.init();
var ZERO = new BN(0);
var secp256k1;
var curveFactory;
var operator;
const EC = require("elliptic").ec;
const ec = new EC('secp256k1');

// const SECP256K1P = new BigNumber("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F");
// const SECP256K1N = new BigNumber("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141");

async function createSECP256K1() {
    const fieldSize = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F", 16);
    const groupOrder = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16);
    const cofactor = new BN(1);
    const Gx = new BN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", 16);
    const Gy = new BN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", 16);
    const lowSmax = new BN("7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0", 16);
    const A = new BN(0);
    const B = new BN(7);
    const gasEstimate = await curveFactory.createCurve.estimateGas([fieldSize], [groupOrder], [lowSmax], [cofactor], [Gx, Gy], [A], [B], {from: operator});
    const secp256k1 = await curveFactory.createCurve([fieldSize], [groupOrder], [lowSmax], [cofactor], [Gx, Gy], [A], [B], {from: operator});
    const newCurve = secp256k1.logs[0].args.newCurve;
    const curve = Curve.at(newCurve);
    const pp = await curve.pp();
    assert(pp.toString(10) === fieldSize.toString(10));
    return curve
} 

contract('Crypto', function (accounts) {
    return
    operator = accounts[0];

    describe('Secp256k1Arith', function () {
        before(async () => {
            const bytecodeSize = (CurveFactory.bytecode.length -2)/2
            curveFactory = await CurveFactory.new({from:operator})
            secp256k1 = await createSECP256K1();
        });

        describe('#add()', function () {

            it('should add a set of points successfully', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._add(randPoint, testdata.randomPoints[idx - 1]);
                    result = await secp256k1.toAffine(result);
                    // const P = ec.curve.jpoint(randPoint[0], randPoint[1], randPoint[2]);
                    // const Q = ec.curve.jpoint(testdata.randomPoints[idx - 1][0], testdata.randomPoints[idx - 1][1], testdata.randomPoints[idx - 1][2]);
                    // const sum = P.add(Q);
                    // const pp = await secp256k1.pp();
                    // const modulus = new BN(pp.toString(10));
                    // const intermediate = addJacobian(randPoint, testdata.randomPoints[idx - 1], modulus);
                    const expected = testdata.sums[idx - 1];
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should successfully add points with the point at identity.', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    const result = await secp256k1._add(randPoint, [ZERO, ZERO, ZERO]);
                    const expected = randPoint;
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                    assert(result[2].eq(expected[2]));
                }
            });

            it('should successfully add the point at infinity with a point.', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    const result = await secp256k1._add([ZERO, ZERO, ZERO], randPoint);
                    const expected = randPoint;
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                    assert(result[2].eq(expected[2]));
                }
            });

            it('should verify that addition is commutative for a set of points', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._add(randPoint, testdata.randomPoints[idx - 1]);
                    result = await secp256k1.toAffine(result);
                    let result2 = await secp256k1._add(testdata.randomPoints[idx - 1], randPoint);
                    result2 = await secp256k1.toAffine(result2);
                    assert(result[0].eq(result2[0]));
                    assert(result[1].eq(result2[1]));
                }
            });

        });

        describe('#addMixed()', function () {

            it('should add a set of points successfully', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    const P2 = testdata.randomPoints[idx - 1];
                    let result = await secp256k1._addMixed(randPoint, [P2[0], P2[1]]);
                    result = await secp256k1.toAffine(result);
                    const expected = testdata.sums[idx - 1];
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should successfully add points with the point at identity.', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    const result = await secp256k1._addMixed(randPoint, [ZERO, ZERO]);
                    const expected = randPoint;
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should successfully add the point at infinity with a point.', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    const P2 = testdata.randomPoints[idx];
                    const result = await secp256k1._addMixed([ZERO, ZERO, ZERO], [P2[0], P2[1]]);
                    const expected = randPoint;
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should verify that addition is commutative for a set of points', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    let P2 = testdata.randomPoints[idx - 1];
                    let result = await secp256k1._addMixed(randPoint, [P2[0], P2[1]]);
                    result = await secp256k1.toAffine(result);
                    P2 = testdata.randomPoints[idx];
                    let result2 = await secp256k1._addMixed(testdata.randomPoints[idx - 1], [P2[0], P2[1]]);
                    result2 = await secp256k1.toAffine(result2);
                    assert(result[0].eq(result2[0]));
                    assert(result[1].eq(result2[1]));
                }
            });

        });

        describe('#double()', function () {

            it('should double a set of points successfully', async () => {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._double(randPoint);
                    result = await secp256k1.toAffine(result);
                    const expected = testdata.doubles[idx];
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should verify that doubling is the same as addition with itself for a set of points', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._double(randPoint);
                    result = await secp256k1.toAffine(result);
                    let result2 = await secp256k1._add(randPoint, randPoint);
                    result2 = await secp256k1.toAffine(result2);
                    assert(result[0].eq(result2[0]));
                    assert(result[1].eq(result2[1]));
                }
            });

            it('should verify that doubling the point at infinity yields the point at infinity', async () =>  {
                const result = await secp256k1._double([ZERO, ZERO, ZERO]);
                assert(isPaI(result));
            });

        });

        describe('#mul()', function () {

            it('should multiply a set of points with random integers successfully', async () => {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const scalar = testdata.randomInts[idx];
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._mul(scalar, randPoint);
                    result = await secp256k1.toAffine(result);
                    const expected = testdata.products[idx];
                    assert(result[0].eq(expected[0]));
                    assert(result[1].eq(expected[1]));
                }
            });

            it('should verify that multiplying by 2 is the same as addition with itself', async () =>  {
                for (let idx = 0; idx < testdata.randomPoints.length; idx++) {
                    if (idx === 0) {
                        continue;
                    }
                    const scalar = new BN(2);
                    const randPoint = testdata.randomPoints[idx];
                    let result = await secp256k1._mul([scalar], randPoint);
                    result = await secp256k1.toAffine(result);
                    let result2 = await secp256k1._add(randPoint, randPoint);
                    result2 = await secp256k1.toAffine(result2);
                    assert(result[0].eq(result2[0]));
                    assert(result[1].eq(result2[1]));
                }
            });

            it('should verify that multiplying a point with 0 yields the point at infinity', async () =>  {
                var P = testdata.randomPoints[0];
                const result = await secp256k1._mul(0, P);
                assert(isPaI(result));
            });

        });

    });

});

function isPaI(point) {
    return point[0].toNumber() === 0 && point[1].toNumber() === 0 && point[2].toNumber() === 0;
}

function addJacobian(point1, point2, modulus) {
    const red = BN.red(modulus);
    const P = point1
    .map(el => {
        return new BN(el.substr(2), 16)
    })
    .map(el => {return el.toRed(red)})
    const Q = point2
    .map(el => {
        return new BN(el.substr(2), 16)
    })
    .map(el => {return el.toRed(red)})
    const zs = [0,0,0,0];
    zs[0] = P[2].redMul(P[2])
    zs[1] = P[2].redMul(zs[0])
    zs[2] = Q[2].redMul(Q[2])
    zs[3] = Q[2].redMul(zs[2])
    const us = [0,0,0,0];
    us[0] = P[0].redMul(zs[2])
    us[1] = P[1].redMul(zs[3])
    us[2] = Q[0].redMul(zs[0])
    us[3] = Q[1].redMul(zs[1])
    if (us[0].cmp(us[2]) === 0) {
        if (us[1].cmp(us[3]) !== 0)
            return;
        else {
            return;
        }
    }
    const H = us[2].redSub(us[0])
    const R = us[3].redSub(us[1])
    let TWO = new BN(2)
    TWO = TWO.toRed(red);
    const X3 = R.redMul(R).redSub( H.redMul(H).redMul(H)).redSub( TWO.redMul(us[0]).redMul(H).redMul(H) )
    const Y3 = R.redMul( us[0].redMul(H).redMul(H).redSub(X3) ).redSub( (us[1].redMul(H).redMul(H).redMul(H)) )
    const Z3 = H.redMul(P[2]).redMul(Q[2])
    const RES = [X3, Y3, Z3];
    return RES.map(el => {return el.fromRed()})
}