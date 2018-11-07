pragma solidity ^0.4.24;

import {DssDeployTest} from "dss-deploy/DssDeploy.t.sol";

import "./CdpHandler.sol";
import {CdpLib, GemLike} from "./CdpLib.sol";

contract ProxyCalls {
    CdpHandler handler;
    CdpLib lib;

    function ethJoin_join(address, bytes32) public payable {
        assert(address(handler).call.value(msg.value)(bytes4(keccak256("execute(address,bytes)")), lib, uint256(0x40), msg.data.length, msg.data));
    }

    function ethJoin_exit(address, address, uint) public payable {
        handler.execute(lib, msg.data);
    }

    function daiJoin_join(address, bytes32, uint) public payable {
        handler.execute(lib, msg.data);
    }

    function daiJoin_exit(address, address, uint) public payable {
        handler.execute(lib, msg.data);
    }

    function frob(address, bytes32, int, int) public {
        handler.execute(lib, msg.data);
    }
}

contract MaliciousHandler is CdpHandler {
    constructor(address registry_) public CdpHandler(DSProxyFactory(registry_).cache(), msg.sender) {
        registry = CdpRegistry(registry_);
    }
}

contract CdpHandlerTest is DssDeployTest, ProxyCalls {
    CdpRegistry registry;

    function setUp() public {
        super.setUp();
        lib = new CdpLib();
        registry = new CdpRegistry();
        handler = registry.create();
    }

    function testCDPHandlerCreateMultipleHandlers() public {
        assertEq(registry.getCount(this), 1);
        registry.create();
        assertEq(registry.getCount(this), 2);
        registry.create();
        assertEq(registry.getCount(this), 3);
    }

    function testCDPHandlerCreateMultipleHandlers2() public {
        assertEq(registry.getCount(this), 1);
        handler = registry.create();
        assertEq(registry.getCount(this), 2);
        handler.setOwner(address(123));
        registry.create();
        assertEq(registry.getCount(this), 3);
    }

    function testCDPHandlerTransferOwnership() public {
        assertEq(handler.owner(), this);
        assertEq(registry.cdps(this, 0).owner(), this);
        handler.setOwner(address(123));
        assertEq(handler.owner(), address(123));
        assertEq(registry.cdps(this, 0), address(0));
        assertEq(registry.cdps(address(123), 0).owner(), address(123));
    }

    function testFailCDPHandlerTransferOwnershipNotInRegistry() public {
        handler = new MaliciousHandler(registry);
        handler.setOwner(address(123));
    }

    function testCDPHandlerJoinCollateral() public {
        deploy();
        assertEq(vat.gem("ETH", bytes32(address(handler))), 0);
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        assertEq(vat.gem("ETH", bytes32(address(handler))), mul(ONE, 1 ether));
    }

    function testCDPHandlerExitCollateral() public {
        deploy();
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        this.ethJoin_exit(ethJoin, address(handler), 1 ether);
        assertEq(vat.gem("ETH", bytes32(address(handler))), 0);
    }

    function testCDPHandlerDrawDai() public {
        deploy();
        assertEq(dssDeploy.dai().balanceOf(address(handler)), 0);
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));

        this.frob(pit, "ETH", 0.5 ether, 60 ether);
        assertEq(vat.gem("ETH", bytes32(address(handler))), mul(ONE, 0.5 ether));
        assertEq(vat.dai(bytes32(address(handler))), mul(ONE, 60 ether));

        this.daiJoin_exit(dssDeploy.daiJoin(), address(this), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 60 ether);
        assertEq(vat.dai(bytes32(address(this))), 0);
    }

    function testCDPHandlerPaybackDai() public {
        deploy();
        this.ethJoin_join.value(1 ether)(ethJoin, bytes32(address(handler)));
        this.frob(pit, "ETH", 0.5 ether, 60 ether);
        this.daiJoin_exit(dssDeploy.daiJoin(), address(this), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 60 ether);
        dssDeploy.dai().approve(handler, uint(-1));
        this.daiJoin_join(dssDeploy.daiJoin(), bytes32(address(handler)), 60 ether);
        assertEq(dssDeploy.dai().balanceOf(address(this)), 0);

        assertEq(vat.dai(bytes32(address(handler))), mul(ONE, 60 ether));
        this.frob(pit, "ETH", 0 ether, -60 ether);
        assertEq(vat.dai(bytes32(address(handler))), 0);
    }
}
