// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ReqCash} from "src/ReqCash.sol";
import {MockToken} from "src/MockToken.sol";

contract ReqCashTest is Test {
    ReqCash public reqCash;
    MockToken public token;

    event Payment(
        uint256 indexed requestId,
        address token,
        uint256 value,
        address indexed payee,
        address indexed payer,
        string memo
    );

    function setUp() public {
        reqCash = new ReqCash();
        token = new MockToken();
    }

    function testPayNative() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        uint256 originalBal = payee.balance;

        vm.deal(payer, 5000);

        vm.expectEmit(address(reqCash));
        emit Payment(0, address(0), 1000, payee, payer, "beer");

        reqCash.pay{value: 1000}(payee, "beer");

        assert(payee.balance == (originalBal + 1000));
    }

    function testPayERC20() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        uint256 originalBal = token.balanceOf(payee);

        token.mint(payer, 5000);
        token.approve(address(reqCash), 5000);

        vm.expectEmit(address(reqCash));
        emit Payment(0, address(token), 1000, payee, payer, "beer");

        reqCash.pay(address(token), 1000, payee, "beer");

        assert(token.balanceOf(payee) == (originalBal + 1000));
    }

    function testPayRequestNative() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        uint256 originalBal = payee.balance;
        bytes memory signature =
            hex"929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f4533547d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e1b";

        vm.deal(payer, 5000);

        vm.expectEmit(address(reqCash));
        emit Payment(1, address(0), 1000, payee, payer, "beer");

        reqCash.pay{value: 1000}(1, payee, "beer", signature);

        assert(payee.balance == (originalBal + 1000));
    }

    function testPayRequestNative2() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        uint256 originalBal = payee.balance;
        uint8 v = 0x1b;
        bytes32 r = 0x929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f45335;
        bytes32 s = 0x47d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e;

        vm.deal(payer, 5000);

        vm.expectEmit(address(reqCash));
        emit Payment(1, address(0), 1000, payee, payer, "beer");

        reqCash.pay{value: 1000}(1, payee, "beer", v, r, s);

        assert(payee.balance == (originalBal + 1000));
    }

    function testFailPayRequestNativeWrongRequestId() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        bytes memory signature =
            hex"929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f4533547d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e1b";

        vm.deal(payer, 5000);

        reqCash.pay{value: 1000}(5, payee, "beer", signature);
    }

    function testFailPayRequestNativeWrongValue() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        bytes memory signature =
            hex"929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f4533547d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e1b";

        vm.deal(payer, 5000);

        reqCash.pay{value: 999}(1, payee, "beer", signature);
    }

    function testFailPayRequestNativeWrongPayee() public {
        address payer = address(this);
        address payable payee = payable(0xBeEf09EE2B36Ebf9B7A4B4b142E11929B6965A9B);
        bytes memory signature =
            hex"929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f4533547d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e1b";

        vm.deal(payer, 5000);

        reqCash.pay{value: 1000}(1, payee, "beer", signature);
    }

    function testFailPayRequestNativeWrongMemo() public {
        address payer = address(this);
        address payable payee = payable(0x5c7709EE2b36ebF9b7A4b4B142E11929B6965a9B);
        bytes memory signature =
            hex"929f8fafedc6231f7b46e8248d9461042cd3f4fe832f6942fc6e5c9877f4533547d813c32098d2c5ced932370b985f1920fe668de0ca8666f7ae0f951e00c03e1b";

        vm.deal(payer, 5000);

        reqCash.pay{value: 1000}(1, payee, "snacks", signature);
    }

    // function testPayRequestERC20(address payable to) public {}

    // function testRequest(address payable to) public {}
}
