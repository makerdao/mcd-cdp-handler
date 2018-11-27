pragma solidity ^0.4.24;

import {DssDeployTest} from "dss-deploy/DssDeploy.t.sol";

import "./CdpHandler.sol";
import "./CdpAuthority.sol";

import {CdpLib, GemLike} from "./CdpLib.sol";

contract ProxyCalls {
    CdpHandler handler;
    CdpLib lib;

    function ethJoin_join(address, bytes32) public payable {
        assert(address(handler).call.value(msg.value)(bytes4(keccak256("execute(address,bytes)")), lib, uint256(0x40), msg.data.length, msg.data));
    }

    function ethJoin_exit(address, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function gemJoin_join(address, bytes32, uint) public {
        handler.execute(lib, msg.data);
    }

    function gemJoin_exit(address, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function daiJoin_join(address, bytes32, uint) public {
        handler.execute(lib, msg.data);
    }

    function daiJoin_exit(address, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function frob(address, bytes32, int, int) public {
        handler.execute(lib, msg.data);
    }

    function lockETH(address, address) public payable {
        assert(address(handler).call.value(msg.value)(bytes4(keccak256("execute(address,bytes)")), lib, uint256(0x40), msg.data.length, msg.data));
    }

    function lockGem(address, address, bytes32, uint) public {
        handler.execute(lib, msg.data);
    }

    function freeETH(address, address, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function freeGem(address, address, bytes32, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function draw(address, address, bytes32, address, uint) public {
        handler.execute(lib, msg.data);
    }

    function wipe(address, address, bytes32, uint) public {
        handler.execute(lib, msg.data);
    }

    function lockETHAndDraw(address, address, address, address, uint) public payable {
        assert(address(handler).call.value(msg.value)(bytes4(keccak256("execute(address,bytes)")), lib, uint256(0x40), msg.data.length, msg.data));
    }

    function lockGemAndDraw(address, address, address, bytes32, address, uint, uint) public {
        handler.execute(lib, msg.data);
    }

    function wipeAndFreeETH(address, address, address, address, uint, uint) public {
        handler.execute(lib, msg.data);
    }

    function wipeAndFreeGem(address, address, address, bytes32, address, uint, uint) public {
        handler.execute(lib, msg.data);
    }
}

contract MaliciousHandler is CdpHandler {
    constructor(address registry_) public CdpHandler(registry_, msg.sender) {
        registry = CdpRegistry(registry_);
    }
}

contract FakeUser {
    function doSetOwner(CdpHandler handler, address newOwner) public {
        handler.setOwner(newOwner);
    }
}

contract CdpHandlerTest is DssDeployTest, ProxyCalls {
    CdpRegistry registry;
    FakeUser user;

    function setUp() public {
        super.setUp();
        lib = new CdpLib();
        registry = new CdpRegistry();
        handler = CdpHandler(registry.build());
        user = new FakeUser();
    }

    function ink(bytes32 ilk, address urn) public view returns (uint inkV) {
        (inkV,) = vat.urns(ilk, bytes32(urn));
    }

    function testCdpHandlerCreateMultipleHandlers() public {
        assertEq(registry.getCount(this), 1);
        CdpHandler(registry.build());
        assertEq(registry.getCount(this), 2);
        CdpHandler(registry.build());
        assertEq(registry.getCount(this), 3);
    }

    function testCdpHandlerCreateMultipleHandlers2() public {
        assertEq(registry.getCount(this), 1);
        handler = CdpHandler(registry.build());
        assertEq(registry.getCount(this), 2);
        handler.setOwner(address(123));
        CdpHandler(registry.build());
        assertEq(registry.getCount(this), 3);
    }

    function testCdpHandlerCreateHandlerForOtherAddress() public {
        handler = CdpHandler(registry.build(address(123)));
        assertEq(handler.owner(), address(123));
        assertEq(registry.handlers(address(123), 0), handler);
    }

    function testCdpHandlerTransferOwnership() public {
        assertEq(handler.owner(), this);
        assertEq(registry.handlers(this, 0).owner(), this);
        handler.setOwner(address(123));
        assertEq(handler.owner(), address(123));
        assertEq(registry.handlers(this, 0), address(0));
        assertEq(registry.handlers(address(123), 0).owner(), address(123));
    }

    function testFailCdpHandlerTransferOwnershipNotInRegistry() public {
        handler = new MaliciousHandler(registry);
        handler.setOwner(address(123));
    }

    function testCdpHandlerTransferFromOwnership() public {
        handler.setAuthority(new CdpAuthority());
        CdpAuthority(handler.authority()).rely(user);
        user.doSetOwner(handler, address(123));
        assertEq(handler.owner(), address(123));
    }

    function testFailCdpHandlerTransferFromOwnership() public {
        user.doSetOwner(handler, address(123));
    }

    function testFailCdpHandlerTransferFromOwnership2() public {
        handler.setAuthority(new CdpAuthority());
        CdpAuthority(handler.authority()).rely(user);
        CdpAuthority(handler.authority()).deny(user);
        user.doSetOwner(handler, address(123));
    }

    function testCdpHandlerJoinETH() public {
        deploy();
        assertEq(vat.gem("ETH", bytes32(address(handler))), 0);
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        assertEq(vat.gem("ETH", bytes32(address(handler))), mul(ONE, 1 ether));
    }

    function testCdpHandlerJoinGem() public {
        deploy();
        dgx.mint(1 ether);
        assertEq(dgx.balanceOf(this), 1 ether);
        assertEq(vat.gem("DGX", bytes32(address(handler))), 0);
        dgx.approve(handler, 1 ether);
        this.gemJoin_join(dgxJoin, bytes32(address(handler)), 1 ether);
        assertEq(dgx.balanceOf(this), 0);
        assertEq(vat.gem("DGX", bytes32(address(handler))), mul(ONE, 1 ether));
    }

    function testCdpHandlerExitETH() public {
        deploy();
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        this.ethJoin_exit(ethJoin, address(handler), 1 ether);
        assertEq(vat.gem("ETH", bytes32(address(handler))), 0);
    }

    function testCdpHandlerExitGem() public {
        deploy();
        dgx.mint(1 ether);
        dgx.approve(dgxJoin, 1 ether);
        dgx.approve(handler, 1 ether);
        this.gemJoin_join(dgxJoin, bytes32(address(handler)), 1 ether);
        this.gemJoin_exit(dgxJoin, address(handler), 1 ether);
        assertEq(dgx.balanceOf(handler), 1 ether);
        assertEq(vat.gem("DGX", bytes32(address(handler))), 0);
    }

    function testCdpHandlerFrobDraw() public {
        deploy();
        assertEq(dai.balanceOf(address(handler)), 0);
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));

        this.frob(pit, "ETH", 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", bytes32(address(handler))), mul(ONE, 0.5 ether));
        assertEq(vat.dai(bytes32(address(handler))), mul(ONE, 60 ether));

        this.daiJoin_exit(daiJoin, address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(bytes32(address(this))), 0);
    }

    function testCdpHandlerFrobWipe() public {
        deploy();
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        this.frob(pit, "ETH", 0.5 ether, 60 ether);
        this.daiJoin_exit(daiJoin, address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        dai.approve(handler, uint(-1));
        this.daiJoin_join(daiJoin, bytes32(address(handler)), 60 ether);
        assertEq(dai.balanceOf(address(this)), 0);

        assertEq(vat.dai(bytes32(address(handler))), mul(ONE, 60 ether));
        this.frob(pit, "ETH", 0 ether, -60 ether);
        assertEq(vat.dai(bytes32(address(handler))), 0);
    }

    function testCdpHandlerLockETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        assertEq(ink("ETH", address(handler)), 0);
        this.lockETH.value(2 ether)(ethJoin, pit);
        assertEq(ink("ETH", address(handler)), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testCdpHandlerLockGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(handler, 2 ether);
        assertEq(ink("DGX", handler), 0);
        this.lockGem(dgxJoin, pit, "DGX", 2 ether);
        assertEq(ink("DGX", handler), 2 ether);
        assertEq(dgx.balanceOf(this), 3 ether);
    }

    function testCdpHandlerfreeETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        this.lockETH.value(2 ether)(ethJoin, pit);
        this.freeETH(ethJoin, pit, address(this), 1 ether);
        assertEq(ink("ETH", handler), 1 ether);
        assertEq(address(this).balance, initialBalance - 1 ether);
    }

    function testCdpHandlerfreeGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(handler, 2 ether);
        this.lockGem(dgxJoin, pit, "DGX", 2 ether);
        this.freeGem(dgxJoin, pit, "DGX", address(this), 1 ether);
        assertEq(ink("DGX", handler), 1 ether);
        assertEq(dgx.balanceOf(this), 4 ether);
    }

    function testCdpHandlerDraw() public {
        deploy();
        this.lockETH.value(2 ether)(ethJoin, pit);
        assertEq(dai.balanceOf(this), 0);
        this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        assertEq(dai.balanceOf(this), 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(address(handler)));
        assertEq(art, 300 ether);
    }

    function testCdpHandlerDrawAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(ethJoin, pit);
        assertEq(dai.balanceOf(this), 0);
        this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        assertEq(dai.balanceOf(this), 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(address(handler)));
        assertEq(art, mul(300 ether, ONE) / (1.05 * 10 ** 27) + 1); // Extra wei due rounding
    }

    function testCdpHandlerWipe() public {
        deploy();
        this.lockETH.value(2 ether)(ethJoin, pit);
        this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        dai.approve(handler, 100 ether);
        this.wipe(daiJoin, pit, "ETH", 100 ether);
        assertEq(dai.balanceOf(this), 200 ether);
    }

    function testCdpHandlerWipeAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(ethJoin, pit);
        this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        dai.approve(handler, 100 ether);
        this.wipe(daiJoin, pit, "ETH", 100 ether);
        assertEq(dai.balanceOf(this), 200 ether);
        (, uint art) = vat.urns("ETH", bytes32(address(handler)));
        assertEq(art, mul(200 ether, ONE) / (1.05 * 10 ** 27) + 1);
    }

    function testCdpHandlerWipeAllAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(ethJoin, pit);
        this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        dai.approve(handler, 300 ether);
        this.wipe(daiJoin, pit, "ETH", 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(address(handler)));
        assertEq(art, 0);
    }

    function testCdpHandlerWipeAllAfterDrip2() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        uint times = 30;
        this.lockETH.value(2 ether * times)(ethJoin, pit);
        for (uint i = 0; i < times; i++) {
            this.draw(daiJoin, pit, "ETH", address(this), 300 ether);
        }
        dai.approve(handler, 300 ether * times);
        this.wipe(daiJoin, pit, "ETH", 300 ether * times);
        (, uint art) = vat.urns("ETH", bytes32(address(handler)));
        assertEq(art, 0);
    }

    function testCdpHandlerLockETHAndDraw() public {
        deploy();
        uint initialBalance = address(this).balance;
        assertEq(ink("ETH", handler), 0);
        assertEq(dai.balanceOf(this), 0);
        this.lockETHAndDraw.value(2 ether)(ethJoin, daiJoin, pit, address(this), 300 ether);
        assertEq(ink("ETH", handler), 2 ether);
        assertEq(dai.balanceOf(this), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testCdpHandlerLockGemAndDraw() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(handler, 2 ether);
        assertEq(ink("DGX", handler), 0);
        assertEq(dai.balanceOf(this), 0);
        this.lockGemAndDraw(dgxJoin, daiJoin, pit, "DGX", address(this), 2 ether, 10 ether);
        assertEq(ink("DGX", handler), 2 ether);
        assertEq(dai.balanceOf(this), 10 ether);
        assertEq(dgx.balanceOf(this), 3 ether);
    }

    function testCdpHandlerWipeAndFreeETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        this.lockETHAndDraw.value(2 ether)(ethJoin, daiJoin, pit, address(this), 300 ether);
        dai.approve(handler, 250 ether);
        this.wipeAndFreeETH(ethJoin, daiJoin, pit, address(this), 1.5 ether, 250 ether);
        assertEq(ink("ETH", handler), 0.5 ether);
        assertEq(dai.balanceOf(this), 50 ether);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testCdpHandlerWipeAndFreeGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(handler, 2 ether);
        this.lockGemAndDraw(dgxJoin, daiJoin, pit, "DGX", address(this), 2 ether, 10 ether);
        dai.approve(handler, 8 ether);
        this.wipeAndFreeGem(dgxJoin, daiJoin, pit, "DGX", address(this), 1.5 ether, 8 ether);
        assertEq(ink("DGX", handler), 0.5 ether);
        assertEq(dai.balanceOf(this), 2 ether);
        assertEq(dgx.balanceOf(this), 4.5 ether);
    }
}
