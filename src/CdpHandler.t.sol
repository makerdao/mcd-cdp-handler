pragma solidity >=0.5.0;

import {DssDeployTest} from "dss-deploy/DssDeploy.t.sol";

import "./CdpHandler.sol";
import "./CdpAuthority.sol";

import {CdpLib, GemLike} from "./CdpLib.sol";

contract ProxyCalls {
    CdpHandler handler;
    address lib;

    function ethJoin_join(address, bytes32) public payable {
        (bool success,) = address(handler).call.value(msg.value)(abi.encodeWithSignature("execute(address,bytes)", lib, msg.data));
        require(success, "");
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

    function frob(address, bytes32, bytes32, int, int) public {
        handler.execute(lib, msg.data);
    }

    function lockETH(address, address) public payable {
        (bool success,) = address(handler).call.value(msg.value)(abi.encodeWithSignature("execute(address,bytes)", lib, msg.data));
        require(success, "");
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
        (bool success,) = address(handler).call.value(msg.value)(abi.encodeWithSignature("execute(address,bytes)", lib, msg.data));
        require(success, "");
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
        lib = address(new CdpLib());
        registry = new CdpRegistry();
        handler = CdpHandler(registry.build());
        user = new FakeUser();
    }

    function ink(bytes32 ilk, bytes32 urn) public view returns (uint inkV) {
        (inkV,) = vat.urns(ilk, urn);
    }

    function testCdpHandlerCreateMultipleHandlers() public {
        assertEq(registry.getCount(address(this)), 1);
        CdpHandler(registry.build());
        assertEq(registry.getCount(address(this)), 2);
        CdpHandler(registry.build());
        assertEq(registry.getCount(address(this)), 3);
    }

    function testCdpHandlerCreateMultipleHandlers2() public {
        assertEq(registry.getCount(address(this)), 1);
        handler = CdpHandler(registry.build());
        assertEq(registry.getCount(address(this)), 2);
        handler.setOwner(address(123));
        CdpHandler(registry.build());
        assertEq(registry.getCount(address(this)), 3);
    }

    function testCdpHandlerCreateHandlerForOtherAddress() public {
        handler = CdpHandler(registry.build(address(123)));
        assertEq(handler.owner(), address(123));
        assertEq(registry.handlers(address(123), 0), address(handler));
    }

    function testCdpHandlerTransferOwnership() public {
        assertEq(handler.owner(), address(this));
        assertEq(CdpHandler(registry.handlers(address(this), 0)).owner(), address(this));
        handler.setOwner(address(123));
        assertEq(handler.owner(), address(123));
        assertEq(registry.handlers(address(this), 0), address(0));
        assertEq(CdpHandler(registry.handlers(address(123), 0)).owner(), address(123));
    }

    function testFailCdpHandlerTransferOwnershipNotInRegistry() public {
        handler = new MaliciousHandler(address(registry));
        handler.setOwner(address(123));
    }

    function testCdpHandlerTransferFromOwnership() public {
        handler.setAuthority(new CdpAuthority());
        CdpAuthority(address(handler.authority())).rely(address(user));
        user.doSetOwner(handler, address(123));
        assertEq(handler.owner(), address(123));
    }

    function testFailCdpHandlerTransferFromOwnership() public {
        user.doSetOwner(handler, address(123));
    }

    function testFailCdpHandlerTransferFromOwnership2() public {
        handler.setAuthority(new CdpAuthority());
        CdpAuthority(address(handler.authority())).rely(address(user));
        CdpAuthority(address(handler.authority())).deny(address(user));
        user.doSetOwner(handler, address(123));
    }

    function testCdpHandlerJoinETH() public {
        deploy();
        assertEq(vat.gem("ETH", bytes32(bytes20(address(handler)))), 0);
        this.ethJoin_join.value(1 ether)(address(ethJoin), bytes32(bytes20(address(handler))));
        assertEq(vat.gem("ETH", bytes32(bytes20(address(handler)))), mul(ONE, 1 ether));
    }

    function testCdpHandlerJoinGem() public {
        deploy();
        dgx.mint(1 ether);
        assertEq(dgx.balanceOf(address(this)), 1 ether);
        assertEq(vat.gem("DGX", bytes32(bytes20(address(handler)))), 0);
        dgx.approve(address(handler), 1 ether);
        this.gemJoin_join(address(dgxJoin), bytes32(bytes20(address(handler))), 1 ether);
        assertEq(dgx.balanceOf(address(this)), 0);
        assertEq(vat.gem("DGX", bytes32(bytes20(address(handler)))), mul(ONE, 1 ether));
    }

    function testCdpHandlerExitETH() public {
        deploy();
        this.ethJoin_join.value(1 ether)(address(ethJoin), bytes32(bytes20(address(handler))));
        this.ethJoin_exit(address(ethJoin), address(handler), 1 ether);
        assertEq(vat.gem("ETH", bytes32(bytes20(address(handler)))), 0);
    }

    function testCdpHandlerExitGem() public {
        deploy();
        dgx.mint(1 ether);
        dgx.approve(address(dgxJoin), 1 ether);
        dgx.approve(address(handler), 1 ether);
        this.gemJoin_join(address(dgxJoin), bytes32(bytes20(address(handler))), 1 ether);
        this.gemJoin_exit(address(dgxJoin), address(handler), 1 ether);
        assertEq(dgx.balanceOf(address(handler)), 1 ether);
        assertEq(vat.gem("DGX", bytes32(bytes20(address(handler)))), 0);
    }

    function testCdpHandlerFrobDraw() public {
        deploy();
        assertEq(dai.balanceOf(address(handler)), 0);
        this.ethJoin_join.value(1 ether)(address(ethJoin), bytes32(bytes20(address(handler))));

        this.frob(address(pit), bytes32(bytes20(address(handler))), "ETH", 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", bytes32(bytes20(address(handler)))), mul(ONE, 0.5 ether));
        assertEq(vat.dai(bytes32(bytes20(address(handler)))), mul(ONE, 60 ether));

        this.daiJoin_exit(address(daiJoin), address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(bytes32(bytes20(address(handler)))), 0);
    }

    function testCdpHandlerFrobWipe() public {
        deploy();
        this.ethJoin_join.value(1 ether)(address(ethJoin), bytes32(bytes20(address(handler))));
        this.frob(address(pit), bytes32(bytes20(address(handler))), "ETH", 0.5 ether, 60 ether);
        this.daiJoin_exit(address(daiJoin), address(this), 60 ether);
        assertEq(dai.balanceOf(address(this)), 60 ether);
        dai.approve(address(handler), uint(-1));
        this.daiJoin_join(address(daiJoin), bytes32(bytes20(address(handler))), 60 ether);
        assertEq(dai.balanceOf(address(this)), 0);

        assertEq(vat.dai(bytes32(bytes20(address(handler)))), mul(ONE, 60 ether));
        this.frob(address(pit), bytes32(bytes20(address(handler))), "ETH", 0 ether, -60 ether);
        assertEq(vat.dai(bytes32(bytes20(address(handler)))), 0);
    }

    function testCdpHandlerLockETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 0);
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 2 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testCdpHandlerLockGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(address(handler), 2 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 0);
        this.lockGem(address(dgxJoin), address(pit), "DGX", 2 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 2 ether);
        assertEq(dgx.balanceOf(address(this)), 3 ether);
    }

    function testCdpHandlerfreeETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        this.freeETH(address(ethJoin), address(pit), address(this), 1 ether);
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 1 ether);
        assertEq(address(this).balance, initialBalance - 1 ether);
    }

    function testCdpHandlerfreeGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(address(handler), 2 ether);
        this.lockGem(address(dgxJoin), address(pit), "DGX", 2 ether);
        this.freeGem(address(dgxJoin), address(pit), "DGX", address(this), 1 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 1 ether);
        assertEq(dgx.balanceOf(address(this)), 4 ether);
    }

    function testCdpHandlerDraw() public {
        deploy();
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        assertEq(dai.balanceOf(address(this)), 0);
        this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        assertEq(dai.balanceOf(address(this)), 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(bytes20(address(handler))));
        assertEq(art, 300 ether);
    }

    function testCdpHandlerDrawAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        assertEq(dai.balanceOf(address(this)), 0);
        this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        assertEq(dai.balanceOf(address(this)), 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(bytes20(address(handler))));
        assertEq(art, mul(300 ether, ONE) / (1.05 * 10 ** 27) + 1); // Extra wei due rounding
    }

    function testCdpHandlerWipe() public {
        deploy();
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        dai.approve(address(handler), 100 ether);
        this.wipe(address(daiJoin), address(pit), "ETH", 100 ether);
        assertEq(dai.balanceOf(address(this)), 200 ether);
    }

    function testCdpHandlerWipeAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        dai.approve(address(handler), 100 ether);
        this.wipe(address(daiJoin), address(pit), "ETH", 100 ether);
        assertEq(dai.balanceOf(address(this)), 200 ether);
        (, uint art) = vat.urns("ETH", bytes32(bytes20(address(handler))));
        assertEq(art, mul(200 ether, ONE) / (1.05 * 10 ** 27) + 1);
    }

    function testCdpHandlerWipeAllAfterDrip() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        this.lockETH.value(2 ether)(address(ethJoin), address(pit));
        this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        dai.approve(address(handler), 300 ether);
        this.wipe(address(daiJoin), address(pit), "ETH", 300 ether);
        (, uint art) = vat.urns("ETH", bytes32(bytes20(address(handler))));
        assertEq(art, 0);
    }

    function testCdpHandlerWipeAllAfterDrip2() public {
        deploy();
        this.file(address(drip), bytes32("ETH"), bytes32("tax"), uint(1.05 * 10 ** 27));
        hevm.warp(now + 1);
        drip.drip("ETH");
        uint times = 30;
        this.lockETH.value(2 ether * times)(address(ethJoin), address(pit));
        for (uint i = 0; i < times; i++) {
            this.draw(address(daiJoin), address(pit), "ETH", address(this), 300 ether);
        }
        dai.approve(address(handler), 300 ether * times);
        this.wipe(address(daiJoin), address(pit), "ETH", 300 ether * times);
        (, uint art) = vat.urns("ETH", bytes32(bytes20(address(handler))));
        assertEq(art, 0);
    }

    function testCdpHandlerLockETHAndDraw() public {
        deploy();
        uint initialBalance = address(this).balance;
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 0);
        assertEq(dai.balanceOf(address(this)), 0);
        this.lockETHAndDraw.value(2 ether)(address(ethJoin), address(daiJoin), address(pit), address(this), 300 ether);
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 2 ether);
        assertEq(dai.balanceOf(address(this)), 300 ether);
        assertEq(address(this).balance, initialBalance - 2 ether);
    }

    function testCdpHandlerLockGemAndDraw() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(address(handler), 2 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 0);
        assertEq(dai.balanceOf(address(this)), 0);
        this.lockGemAndDraw(address(dgxJoin), address(daiJoin), address(pit), "DGX", address(this), 2 ether, 10 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 2 ether);
        assertEq(dai.balanceOf(address(this)), 10 ether);
        assertEq(dgx.balanceOf(address(this)), 3 ether);
    }

    function testCdpHandlerWipeAndFreeETH() public {
        deploy();
        uint initialBalance = address(this).balance;
        this.lockETHAndDraw.value(2 ether)(address(ethJoin), address(daiJoin), address(pit), address(this), 300 ether);
        dai.approve(address(handler), 250 ether);
        this.wipeAndFreeETH(address(ethJoin), address(daiJoin), address(pit), address(this), 1.5 ether, 250 ether);
        assertEq(ink("ETH", bytes32(bytes20(address(handler)))), 0.5 ether);
        assertEq(dai.balanceOf(address(this)), 50 ether);
        assertEq(address(this).balance, initialBalance - 0.5 ether);
    }

    function testCdpHandlerWipeAndFreeGem() public {
        deploy();
        dgx.mint(5 ether);
        dgx.approve(address(handler), 2 ether);
        this.lockGemAndDraw(address(dgxJoin), address(daiJoin), address(pit), "DGX", address(this), 2 ether, 10 ether);
        dai.approve(address(handler), 8 ether);
        this.wipeAndFreeGem(address(dgxJoin), address(daiJoin), address(pit), "DGX", address(this), 1.5 ether, 8 ether);
        assertEq(ink("DGX", bytes32(bytes20(address(handler)))), 0.5 ether);
        assertEq(dai.balanceOf(address(this)), 2 ether);
        assertEq(dgx.balanceOf(address(this)), 4.5 ether);
    }
}
