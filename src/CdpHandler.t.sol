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
        handler = registry.create();
        user = new FakeUser();
    }

    function testCdpHandlerCreateMultipleHandlers() public {
        assertEq(registry.getCount(this), 1);
        registry.create();
        assertEq(registry.getCount(this), 2);
        registry.create();
        assertEq(registry.getCount(this), 3);
    }

    function testCdpHandlerCreateMultipleHandlers2() public {
        assertEq(registry.getCount(this), 1);
        handler = registry.create();
        assertEq(registry.getCount(this), 2);
        handler.setOwner(address(123));
        registry.create();
        assertEq(registry.getCount(this), 3);
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

    function testCdpHandlerJoinERC20() public {
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

    function testCdpHandlerExitERC20() public {
        deploy();
        dgx.mint(1 ether);
        dgx.approve(dgxJoin, 1 ether);
        dgx.approve(handler, 1 ether);
        this.gemJoin_join(dgxJoin, bytes32(address(handler)), 1 ether);
        this.gemJoin_exit(dgxJoin, address(handler), 1 ether);
        assertEq(dgx.balanceOf(handler), 1 ether);
        assertEq(vat.gem("DGX", bytes32(address(handler))), 0);
    }

    function testCdpHandlerDrawDai() public {
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

    function testCdpHandlerPaybackDai() public {
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
}
