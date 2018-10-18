pragma solidity ^0.4.24;

import "ds-test/test.sol";

import "./CdpHandler.sol";

contract CdpHandlerTest is DSTest {
    CdpHandler handler;

    function setUp() public {
        handler = new CdpHandler();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
