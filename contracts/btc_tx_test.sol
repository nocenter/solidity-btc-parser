import 'dapple/test.sol';
import 'btc_tx.sol';

contract BasicParseTest is Test {
    function testGetBytesLittleEndian8() {
        bytes memory data = new bytes(1);
        data[0] = 0xfa;
        var val = BTC.getBytesLE(data, 0, 8);
        assertEq(val, 250);
    }
    function testGetBytesLittleEndian16() {
        bytes memory data = new bytes(2);
        data[0] = 0x02;
        data[1] = 0x01;
        var val = BTC.getBytesLE(data, 0, 16);
        assertEq(val, 258);
    }
    function testGetBytesLittleEndian32() {
        bytes memory data = new bytes(4);
        data[0] = 0x04;
        data[1] = 0x03;
        data[2] = 0x02;
        data[3] = 0x01;
        var val = BTC.getBytesLE(data, 0, 32);
        assertEq(val, 16909060);
    }
    function testGetBytesLittleEndian64() {
        bytes memory data = new bytes(8);
        data[0] = 0x08;
        data[1] = 0x07;
        data[2] = 0x06;
        data[3] = 0x05;
        data[4] = 0x04;
        data[5] = 0x03;
        data[6] = 0x02;
        data[7] = 0x01;
        var val = BTC.getBytesLE(data, 0, 64);
        assertEq(val, 72623859790382856);
    }
    function testParseVarInt8() {
        bytes memory data = new bytes(1);
        data[0] = 0x00;
        var (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 0);
        assertEq(pos, 1);

        data[0] = 0xfc;
        (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 252);
    }
    function testParseVarInt16() {
        bytes memory data = new bytes(3);
        data[0] = 0xfd;
        var (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 0);
        assertEq(pos, 3);

        data[1] = 0x01;
        data[2] = 0x02;
        (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 513);
    }
    function testParseVarInt32() {
        bytes memory data = new bytes(5);
        data[0] = 0xfe;
        var (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 0);
        assertEq(pos, 5);

        data[3] = 0x01;
        data[4] = 0x02;
        (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 33619968);
    }
    function testParseVarInt64() {
        bytes memory data = new bytes(9);
        data[0] = 0xff;
        var (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 0);
        assertEq(pos, 9);

        data[7] = 0x01;
        data[8] = 0x02;
        (val, pos) = BTC.parseVarInt(data, 0);
        assertEq(val, 144396663052566528);
    }
}

contract SolidityTest is Test {
    // check how solidity deals with partially decoded byte strings.
    // In Python, '\x' characters will be presented decoded if possible.
    function testSolidityBytesEquivalence() {
        // original hex: '01 5b 2b 99'
        bytes memory data = '\x01[+\x99';
        bytes memory raw_data = '\x01\x5b\x2b\x99';
        bytes memory array_data = new bytes(4);
        array_data[0] = 0x01;
        array_data[1] = 0x5b;
        array_data[2] = 0x2b;
        array_data[3] = 0x99;

        assertEq0(data, raw_data);
        assertEq0(data, array_data);
        assertEq0(raw_data, array_data);
    }
}

contract BTCTxTest is Test {
    function testGetFirstTwoOutputs() {
        // transaction data generated with ./generate_bitcoin_transaction.sh
        // txid: 015bb217e9b83dd5d9d1c26e856873ff10325fc77141a153cb1df2a43f3d1033
        // value: 12345678
        // value: 11223344
        // address: 1MaTeTiCCGFvgmZxK2R1pmD9LDWvkmU9BS
        // address: 16A81uRvSkHCn6Kpm7dLWM9Du9E9cwBPkM
        // script: OP_DUP OP_HASH160 e1b67c3a7f8977fac55a15dbdb19c7a175676d73 OP_EQUALVERIFY OP_CHECKSIG
        // script: OP_DUP OP_HASH160 38923a989763397163a08d5498d903a0b86b9ac9 OP_EQUALVERIFY OP_CHECKSIG
        bytes memory transaction = "\x01\x00\x00\x00\x01\xa5\x8c\xbb\xcb\xad\x45\x62\x5f\x5e\xd1\xf2\x04\x58\xf3\x93\xfe\x1d\x15\x07\xe2\x54\x26\x5f\x09\xd9\x74\x62\x32\xda\x48\x00\x24\x00\x00\x00\x00\x00\xff\xff\xff\xff\x02\x4e\x61\xbc\x00\x00\x00\x00\x00\x19\x76\xa9\x14\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73\x88\xac\x30\x41\xab\x00\x00\x00\x00\x00\x19\x76\xa9\x14\x38\x92\x3a\x98\x97\x63\x39\x71\x63\xa0\x8d\x54\x98\xd9\x03\xa0\xb8\x6b\x9a\xc9\x88\xac\x00\x00\x00\x00";

        var (ov1, oa1, ov2, oa2) = BTC.getFirstTwoOutputs(transaction);

        // expected output values in satoshis
        uint ev1 = 12345678;
        uint ev2 = 11223344;
        assertEq(uint(ov1), ev1);
        assertEq(uint(ov2), ev2);

        // expected addresses in binary
        bytes20 ea1 = "\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73";
        bytes20 ea2 = "\x38\x92\x3a\x98\x97\x63\x39\x71\x63\xa0\x8d\x54\x98\xd9\x03\xa0\xb8\x6b\x9a\xc9";
        assertEq20(oa1, ea1);
        assertEq20(oa2, ea2);
    }
    function testIdP2pkh() {
        bytes memory pk_script = "\x76\xa9\x14\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73\x88\xac";

        assertTrue(BTC.isP2PKH(pk_script, 0, 25));
        assertFalse(BTC.isP2PKH(pk_script, 0, 24));
        assertFalse(BTC.isP2PKH(pk_script, 0, 26));

        pk_script = "\x77\xa9\x14\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73\x88\xac";
        assertFalse(BTC.isP2PKH(pk_script, 0, 25));
    }
    function testFailIdShortP2pkh() {
        bytes memory pk_script = "\x76\xa9\x14";
        BTC.isP2PKH(pk_script, 0, 25);
    }
    function testParseP2pkhOutputScript() logs_gas() {
        bytes memory pk_script = "\x76\xa9\x14\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73\x88\xac";
        bytes20 rpkhash = bytes20("\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73");

        var pkhash = BTC.parseOutputScript(pk_script, 0, 25);

        assertEq20(pkhash, rpkhash);
    }
    // all p2sh example data from http://www.soroushjp.com/2014/12/20/bitcoin-multisig-the-hard-way-understanding-raw-multisignature-bitcoin-transactions
    function testIdP2sh() {
        bytes memory script = "\xa9\x14\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e\x87";

        assertTrue(BTC.isP2SH(script, 0, 23));
        assertFalse(BTC.isP2SH(script, 0, 22));
        assertFalse(BTC.isP2SH(script, 0, 24));

        script = "\xa9\x15\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e\x87";
        assertFalse(BTC.isP2SH(script, 0, 23));
    }
    function testFailIdShortP2sh() {
        bytes memory script = "\xa9\x14\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e";
        BTC.isP2SH(script, 0, 23);
    }
    function testParseP2shOutputScript() {
        bytes memory script = "\xa9\x14\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e\x87";
        bytes20 rscript_hash = bytes20("\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e");

        var script_hash = BTC.parseOutputScript(script, 0, 23);

        assertEq20(script_hash, rscript_hash);
    }
    function testCheckValueSentP2pkh() logs_gas() {
        // same transaction as in testGetFirstTwoOutputs
        bytes memory transaction = "\x01\x00\x00\x00\x01\xa5\x8c\xbb\xcb\xad\x45\x62\x5f\x5e\xd1\xf2\x04\x58\xf3\x93\xfe\x1d\x15\x07\xe2\x54\x26\x5f\x09\xd9\x74\x62\x32\xda\x48\x00\x24\x00\x00\x00\x00\x00\xff\xff\xff\xff\x02\x4e\x61\xbc\x00\x00\x00\x00\x00\x19\x76\xa9\x14\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73\x88\xac\x30\x41\xab\x00\x00\x00\x00\x00\x19\x76\xa9\x14\x38\x92\x3a\x98\x97\x63\x39\x71\x63\xa0\x8d\x54\x98\xd9\x03\xa0\xb8\x6b\x9a\xc9\x88\xac\x00\x00\x00\x00";

        bytes20 address1 = "\xe1\xb6\x7c\x3a\x7f\x89\x77\xfa\xc5\x5a\x15\xdb\xdb\x19\xc7\xa1\x75\x67\x6d\x73";
        bytes20 address2 = "\x38\x92\x3a\x98\x97\x63\x39\x71\x63\xa0\x8d\x54\x98\xd9\x03\xa0\xb8\x6b\x9a\xc9";

        assertTrue(BTC.checkValueSent(transaction, address1, 1000));
        assertTrue(BTC.checkValueSent(transaction, address2, 1000));
        assertTrue(BTC.checkValueSent(transaction, address1, 12345678));
        assertTrue(BTC.checkValueSent(transaction, address2, 11223344));
        assertFalse(BTC.checkValueSent(transaction, address1, 12345679));
        assertFalse(BTC.checkValueSent(transaction, address2, 11223345));
    }
    function testCheckValueSentMultiP2pkh() logs_gas {
        bytes memory transaction = "\x01\x00\x00\x00\x01\xa5\x8c\xbb\xcb\xad\x45\x62\x5f\x5e\xd1\xf2\x04\x58\xf3\x93\xfe\x1d\x15\x07\xe2\x54\x26\x5f\x09\xd9\x74\x62\x32\xda\x48\x00\x24\x00\x00\x00\x00\x00\xff\xff\xff\xff\x05\x4e\x61\xbc\x00\x00\x00\x00\x00\x19\x76\xa9\x14\xcb\xb3\x82\x98\x56\xd7\x7a\x8b\x65\xb1\xbd\x95\xdc\xd3\x25\x4d\x5e\xa2\xcc\x14\x88\xac\x30\x41\xab\x00\x00\x00\x00\x00\x19\x76\xa9\x14\x15\x88\xd7\x22\xa2\xa4\x52\xb5\xf4\x8b\x23\x54\x06\xdb\x35\x6a\x72\xd6\xf9\xf6\x88\xac\x55\xa0\xfc\x01\x00\x00\x00\x00\x19\x76\xa9\x14\xed\xd1\xd8\x73\xc4\x79\x67\x48\xb7\x3e\x19\xda\xa5\x7f\xca\x3b\xa4\x9d\xab\x62\x88\xac\x1c\x2b\xa6\x02\x00\x00\x00\x00\x19\x76\xa9\x14\x50\xf8\x7c\x16\x81\x08\x96\xe9\x9e\x2c\xeb\x18\x6e\xcc\x68\xd9\xc7\x5b\x7e\x6b\x88\xac\xe3\xb5\x4f\x03\x00\x00\x00\x00\x19\x76\xa9\x14\x7d\x23\x10\xb8\xc6\xcb\x53\x85\x71\xdb\xc5\x17\x0d\xcc\x58\x2c\x5f\x32\xa4\x4c\x88\xac\x00\x00\x00\x00";

        bytes20 address1 = "\xcb\xb3\x82\x98\x56\xd7\x7a\x8b\x65\xb1\xbd\x95\xdc\xd3\x25\x4d\x5e\xa2\xcc\x14";
        bytes20 address2 = "\x15\x88\xd7\x22\xa2\xa4\x52\xb5\xf4\x8b\x23\x54\x06\xdb\x35\x6a\x72\xd6\xf9\xf6";
        bytes20 address3 = "\xed\xd1\xd8\x73\xc4\x79\x67\x48\xb7\x3e\x19\xda\xa5\x7f\xca\x3b\xa4\x9d\xab\x62";
        bytes20 address4 = "\x50\xf8\x7c\x16\x81\x08\x96\xe9\x9e\x2c\xeb\x18\x6e\xcc\x68\xd9\xc7\x5b\x7e\x6b";
        bytes20 address5 = "\x7d\x23\x10\xb8\xc6\xcb\x53\x85\x71\xdb\xc5\x17\x0d\xcc\x58\x2c\x5f\x32\xa4\x4c";

        assertTrue(BTC.checkValueSent(transaction, address1, 1));
        assertTrue(BTC.checkValueSent(transaction, address2, 1));
        assertTrue(BTC.checkValueSent(transaction, address3, 1));
        assertTrue(BTC.checkValueSent(transaction, address4, 1));
        assertTrue(BTC.checkValueSent(transaction, address5, 1));

        assertTrue(BTC.checkValueSent(transaction, address4, 44444444));
        assertTrue(BTC.checkValueSent(transaction, address5, 55555555));

        assertFalse(BTC.checkValueSent(transaction, address4, 44444445));
        assertFalse(BTC.checkValueSent(transaction, address5, 55555556));
    }
    function testCheckValueSentP2sh() {
        bytes memory transaction = "\x01\x00\x00\x00\x01\xac\xc6\xfb\x9e\xc2\xc3\x88\x4d\x3a\x12\xa8\x9e\x70\x78\xc8\x38\x53\xd9\xb7\x91\x22\x81\xce\xfb\x14\xba\xc0\x0a\x27\x37\xd3\x3a\x00\x00\x00\x00\x8a\x47\x30\x44\x02\x20\x4e\x63\xd0\x34\xc6\x07\x4f\x17\xe9\xc5\xf8\x76\x6b\xc7\xb5\x46\x8a\x0d\xce\x5b\x69\x57\x8b\xd0\x85\x54\xe8\xf2\x14\x34\xc5\x8e\x02\x20\x76\x3c\x69\x66\xf4\x7c\x39\x06\x8c\x8d\xcd\x3f\x3d\xbd\x8e\x2a\x4e\xa1\x3a\xc9\xe9\xc8\x99\xca\x1f\xbc\x00\xe2\x55\x8c\xbb\x8b\x01\x41\x04\x31\x39\x3a\xf9\x98\x43\x75\x83\x09\x71\xab\x5d\x30\x94\xc6\xa7\xd0\x2d\xb3\x56\x8b\x2b\x06\x21\x2a\x70\x90\x09\x45\x49\x70\x1b\xbb\x9e\x84\xd9\x47\x74\x51\xac\xc4\x26\x38\x96\x36\x35\x89\x9c\xe9\x1b\xac\xb4\x51\xa1\xbb\x6d\xa7\x3d\xdf\xbc\xf5\x96\xbd\xdf\xff\xff\xff\xff\x01\x40\x00\x01\x00\x00\x00\x00\x00\x17\xa9\x14\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e\x87\x00\x00\x00\x00";

        bytes20 script_hash = "\x1a\x8b\x00\x26\x34\x31\x66\x62\x5c\x74\x75\xf0\x1e\x48\xb5\xed\xe8\xc0\x25\x2e";

        assertTrue(BTC.checkValueSent(transaction, script_hash, 1));
        assertTrue(BTC.checkValueSent(transaction, script_hash, 65600));
        assertFalse(BTC.checkValueSent(transaction, script_hash, 65601));
    }
}

// real data from https://blockchain.info/strange-transactions
// use curl https://blockchain.info/rawtx/TXHASH?format={hex|json} to get the data
contract StrangeTransactionTest is Test {
    function testA() {
        // P2SH, OP_RETURN, P2SH
        // hash: 19631dbcca350b703cc7276b13e2866e30df5fd90a05c8cbf5c16772add2ac10

        // outputs:
        // "addr":"3KW5pjgfDuVTftXsyLqbtxs7nAUd35Jqts",
        // "value":2730,
        // "script":"a914c360f1a8e6af948e8ae55a23293be19003f6329387"

        // (OP_RETURN)
        // "value":0,
        // "script":"6a146f6d6e69000000000000001f0000005d21dba000"

        // "addr":"3BbDtxBSjgfTRxaBUgR2JACWRukLKtZdiQ",
        // "value":9376312,
        // "script":"a9146c98c19a033bdbd421a9c7d24ad5e0e3a3318ec187"
        bytes memory transaction = "\x01\x00\x00\x00\x01\xfd\x4d\x49\x52\xd7\x42\x8c\x42\x13\x70\xcc\xef\xb2\x01\xb9\x15\x13\x3a\x5d\xec\x08\x28\xb0\x52\x9c\xf2\x16\x84\x54\x7e\x87\x84\x01\x00\x00\x00\x6f\x00\x47\x30\x44\x02\x20\x45\xa8\xb1\x6c\x43\x87\x4c\x82\xba\x84\x6b\x34\x9a\x82\xcb\x26\x35\x2d\x3b\x49\x02\x80\x5d\x27\xa3\x97\x08\x7b\xb1\x7b\x04\x47\x02\x20\x1a\xc9\xe1\x5a\xe9\x9a\x61\xd6\xdf\x97\xc7\x71\x96\x8e\xe8\xa5\xad\xc1\xe6\x80\x8b\x1c\x29\x6f\x3f\x97\x83\x6f\x72\x20\xe3\x19\x01\x25\x51\x21\x03\x0e\xc1\x11\xfb\x92\x35\x15\xba\x47\x47\xf3\xc7\x00\x5b\x43\x98\xe8\x1d\x81\x6a\x66\xba\x50\x30\x6a\xac\xac\x2f\x40\x5a\xc7\x26\x51\xae\xff\xff\xff\xff\x03\xaa\x0a\x00\x00\x00\x00\x00\x00\x17\xa9\x14\xc3\x60\xf1\xa8\xe6\xaf\x94\x8e\x8a\xe5\x5a\x23\x29\x3b\xe1\x90\x03\xf6\x32\x93\x87\x00\x00\x00\x00\x00\x00\x00\x00\x16\x6a\x14\x6f\x6d\x6e\x69\x00\x00\x00\x00\x00\x00\x00\x1f\x00\x00\x00\x5d\x21\xdb\xa0\x00\x38\x12\x8f\x00\x00\x00\x00\x00\x17\xa9\x14\x6c\x98\xc1\x9a\x03\x3b\xdb\xd4\x21\xa9\xc7\xd2\x4a\xd5\xe0\xe3\xa3\x31\x8e\xc1\x87\x00\x00\x00\x00";

        bytes20 address1 = "\xc3\x60\xf1\xa8\xe6\xaf\x94\x8e\x8a\xe5\x5a\x23\x29\x3b\xe1\x90\x03\xf6\x32\x93";
        bytes20 address2 = "\x6c\x98\xc1\x9a\x03\x3b\xdb\xd4\x21\xa9\xc7\xd2\x4a\xd5\xe0\xe3\xa3\x31\x8e\xc1";

        assertTrue(BTC.checkValueSent(transaction, address1, 2730));
        assertFalse(BTC.checkValueSent(transaction, address1, 2731));

        assertTrue(BTC.checkValueSent(transaction, address2, 9376312));
        assertFalse(BTC.checkValueSent(transaction, address2, 9376313));
    }
    function testB() {
        // OP_RETURN, P2SH, P2PKH, P2PKH
        // hash: be8c30b9e5dd56ed3b0eaf93365cdd84bc36e512d4aebdd25a38584d7f2fdfbc

        // "value":0,
        // "script":"6a104f4101000280d0acf30e80d0acf30e00"

        // "addr":"3JxhW1U3R8Ju4AzfLkfAKgBF9jdDYr7Lxf",
        // "value":600,
        // "script":"a914bd716a3a6c9b0c4fc11be9cd3581741d3b4f29b587"

        // "addr":"1KStr8jyMSJt4YBqzKPynJASZjaBwSUjkw",
        // "value":600,
        // "script":"76a914ca57f16593cf2423d1d17ed7481d25fdefbc290288ac"

        // "addr":"1KStr8jyMSJt4YBqzKPynJASZjaBwSUjkw",
        // "value":149400,
        // "script":"76a914ca57f16593cf2423d1d17ed7481d25fdefbc290288ac"

        bytes memory transaction = "\x01\x00\x00\x00\x02\x9f\xb7\x2a\xb2\x59\x84\x64\xda\x31\x2d\x34\x4c\xa9\x1f\xf2\xac\x91\xe7\xd2\x24\x18\x6d\x7a\x93\xd2\x80\x8d\xb7\x72\x84\x0d\xe6\x01\x00\x00\x00\x6b\x48\x30\x45\x02\x21\x00\x8e\x27\x82\x7e\xa5\xf7\xad\x7b\x38\xb2\xcc\x7e\x01\x6b\x5a\x11\x9a\xcb\xe1\x85\x1a\x65\x17\xa3\x53\x8f\x89\x14\x8e\xe9\x7c\x0c\x02\x20\x79\xde\x59\x8c\x49\x8f\x47\xb8\x72\x14\x3b\xd8\x30\xba\xe4\xb4\x83\xe8\x5a\xd2\xe1\x87\xac\x52\x86\x32\xbc\x50\xd8\x06\x57\x42\x01\x21\x03\xed\xc4\x05\xc1\x2e\xc2\x64\x3a\xe5\x8b\x42\x98\xa4\x82\xa7\x12\x78\x97\x9c\xba\xce\x49\x48\x75\x4e\xad\x40\x40\xf1\xde\xa8\x2a\xff\xff\xff\xff\x5d\x5a\xc4\x8f\x04\x42\x31\x7f\xbb\x4a\x31\xa5\x29\x17\x00\x76\x47\x36\xb2\xda\xb1\x5d\x43\xc0\xdb\xb7\x91\x21\xf9\xd2\xba\x2c\x00\x00\x00\x00\x6a\x47\x30\x44\x02\x20\x4a\x92\x75\x02\x75\x9e\x6b\xad\x02\xe7\xb4\xd7\x4a\xc5\x7c\x6d\x29\x65\xd9\xe2\x71\x91\x5f\x66\xec\x5f\x36\x5f\xb9\x22\xd9\x30\x02\x20\x53\xe9\xcd\xb6\x6b\x72\x7c\x58\xa8\x9a\x07\x99\xfd\x68\x0c\xee\x6f\x04\x53\x33\xe4\xb8\x16\xfc\xf4\x20\x43\x4f\xe8\x5c\xb7\xc0\x01\x21\x03\xed\xc4\x05\xc1\x2e\xc2\x64\x3a\xe5\x8b\x42\x98\xa4\x82\xa7\x12\x78\x97\x9c\xba\xce\x49\x48\x75\x4e\xad\x40\x40\xf1\xde\xa8\x2a\xff\xff\xff\xff\x04\x00\x00\x00\x00\x00\x00\x00\x00\x12\x6a\x10\x4f\x41\x01\x00\x02\x80\xd0\xac\xf3\x0e\x80\xd0\xac\xf3\x0e\x00\x58\x02\x00\x00\x00\x00\x00\x00\x17\xa9\x14\xbd\x71\x6a\x3a\x6c\x9b\x0c\x4f\xc1\x1b\xe9\xcd\x35\x81\x74\x1d\x3b\x4f\x29\xb5\x87\x58\x02\x00\x00\x00\x00\x00\x00\x19\x76\xa9\x14\xca\x57\xf1\x65\x93\xcf\x24\x23\xd1\xd1\x7e\xd7\x48\x1d\x25\xfd\xef\xbc\x29\x02\x88\xac\x98\x47\x02\x00\x00\x00\x00\x00\x19\x76\xa9\x14\xca\x57\xf1\x65\x93\xcf\x24\x23\xd1\xd1\x7e\xd7\x48\x1d\x25\xfd\xef\xbc\x29\x02\x88\xac\x00\x00\x00\x00";

        bytes20 address1 = "\xbd\x71\x6a\x3a\x6c\x9b\x0c\x4f\xc1\x1b\xe9\xcd\x35\x81\x74\x1d\x3b\x4f\x29\xb5";
        // edge case: repeated output addresses
        bytes20 address2 = "\xca\x57\xf1\x65\x93\xcf\x24\x23\xd1\xd1\x7e\xd7\x48\x1d\x25\xfd\xef\xbc\x29\x02";
        bytes20 address3 = "\xca\x57\xf1\x65\x93\xcf\x24\x23\xd1\xd1\x7e\xd7\x48\x1d\x25\xfd\xef\xbc\x29\x02";

        assertTrue(BTC.checkValueSent(transaction, address1, 600));
        assertTrue(BTC.checkValueSent(transaction, address3, 149400));
        assertFalse(BTC.checkValueSent(transaction, address3, 149401));
    }
}
