const Curve = artifacts.require("Curve.sol");
const CurveFactory = artifacts.require("GenericCurveFactory.sol");
const util = require("util");
const testdata = require('./data/secp2561k_data.json');
const BN = require("bn.js");
const ethUtil = require("ethereumjs-util");
const assert = require("assert");
const t = require('truffle-test-utils')
t.init();
// const expectThrow = require("../helpers/expectThrow");


contract('Curve', async (accounts) => {
    return;
    var curve;
    var curveFactory;
    const operator = accounts[0]
    beforeEach(async () => {
        curveFactory = await CurveFactory.new({from:operator})
    })

    async function createSECP256K1() {
        const fieldSize = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F", 16);
        const groupOrder = new BN("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", 16);
        const cofactor = new BN(1);
        const Gx = new BN("79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798", 16);
        const Gy = new BN("483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8", 16);
        const lowSmax = new BN("7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0", 16);
        const A = new BN(0);
        const B = new BN(7);

        const secp256k1 = await curveFactory.createCurve([fieldSize], [groupOrder], [lowSmax], [cofactor], [Gx, Gy], [A], [B], {from: operator});
        const newCurve = secp256k1.logs[0].args.newCurve;
        return Curve.at(newCurve);
    }

    async function createPrime256v1() {
        const fieldSize = new BN("FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF", 16);
        const groupOrder = new BN("FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551", 16);
        const cofactor = new BN(1);
        const Gx = new BN("6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296", 16);
        const Gy = new BN("4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5", 16);
        const lowSmax = new BN("7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0", 16);
        const A = new BN("FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC", 16);
        const B = new BN("5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B", 16);

        const secp256k1 = await curveFactory.createCurve([fieldSize], [groupOrder], [lowSmax], [cofactor], [Gx, Gy], [A], [B], {from: operator});
        const newCurve = secp256k1.logs[0].args.newCurve;
        return Curve.at(newCurve);
    }

    it('check SECP256K1', async () => {
        // createCurve(uint256 fieldSize, uint256 groupOrder, uint256 lowSmax, uint256 cofactor, uint256[2] generator)
        curve = await createSECP256K1();
    })
    it('should detect that the given points are on the curve', async () => {
        secp256k1 = await createSECP256K1();
        try {
            for (const point of testdata.randomPoints) {
                const result = await secp256k1.onCurve(point);
                assert(result);
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should detect that the given points are not on the curve', async () => {
        secp256k1 = await createSECP256K1();
        var ok = false
        for (const point of testdata.randomPoints) {
            try {
                const result = await secp256k1.onCurve([point[0], point[0]]);
                assert(!result);
                }
            catch (e) {
                console.log(e);
                throw e
            }
        }
    });

    it('should detect that the given points are valid public keys', async () =>  {
        secp256k1 = await createSECP256K1();
        try {
            for (const point of testdata.randomPoints) {
                const result = await secp256k1.isPubKey(point);
                assert(result);
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should detect that the given points are not valid public keys', async () =>  {
        secp256k1 = await createSECP256K1();
        var ok = false
        for (const point of testdata.randomPoints) {
            try {
                const result = await secp256k1.isPubKey([point[0], point[0]]);
                assert(!result);
            }
            catch (e) {
                console.log(e);
                throw e
            }
        }
    });

    it('should detect that the given signatures are valid', async () =>  {
        // return
        const message = testdata.message;
        secp256k1 = await createSECP256K1();
        try {
            for (const idx in testdata.keypairs) {
                const keypair = testdata.keypairs[idx];
                const signature = testdata.signatures[idx];
                const result = await secp256k1.validateSignature(message, signature, keypair.pub);
                assert(result);
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should detect that the public key does not correspond to the given signature', async () => {
        // return
        const message = testdata.message;
        secp256k1 = await createSECP256K1();
        try {
            for (const idx in testdata.keypairs) {
                const keypair = testdata.keypairs[idx];
                const signature = testdata.signatures[17 - idx];
                const result = await secp256k1.validateSignature(message, signature, keypair.pub);
                assert(!result);
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should detect that the given signatures and pubkeys are wrong for the given message', async () =>  {
        // return
        const message = "0x1234123412341234123412341234123412341234123412341234123412341234";
        secp256k1 = await createSECP256K1();
        try {
            for (const idx in testdata.keypairs) {
                const keypair = testdata.keypairs[idx];
                const signature = testdata.signatures[idx];
                const result = await secp256k1.validateSignature(message, signature, keypair.pub);
                assert(!result);
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should compress a set of points successfully', async () =>  {
        secp256k1 = await createSECP256K1();
        try {
            for (const keypair of testdata.keypairs) {
                const result = await secp256k1.compress(keypair.pub);
                const x = new BN(keypair.pub[0].substring(2), 16);
                const yBit = (new BN(keypair.pub[1].substring(2), 16)).mod(new BN(2));
                assert(yBit.eq(new BN(result[0].toString(10))));
                assert(x.eq(new BN(result[1].toString(10))));
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });

    it('should decompress a set of points successfully', async () =>  {
        secp256k1 = await createSECP256K1();
        try {
            for (const keypair of testdata.keypairs) {
                const x = new BN(keypair.pub[0].substring(2), 16);
                const y = new BN(keypair.pub[1].substring(2), 16);
                const yBit = y.mod(new BN(2));
                const result = await secp256k1.decompress([yBit], [x]);
                assert(x.eq(new BN(result[0].toString(10))));
                assert(y.eq(new BN(result[1].toString(10))));
            }
        } catch(e) {
            console.log(e);
            throw e;
        }
    });
})
