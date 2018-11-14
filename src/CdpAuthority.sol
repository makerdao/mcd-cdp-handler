pragma solidity ^0.4.24;

import {DSAuth, DSAuthority} from "ds-proxy/proxy.sol";

contract CdpAuthority is DSAuth, DSAuthority {
    event Approval(address indexed guy, bool status);
    mapping(address => bool) allowance;

    function rely(address guy) public auth {
        allowance[guy] = true;
        emit Approval(guy, true);
    }

    function deny(address guy) public auth {
        allowance[guy] = false;
        emit Approval(guy, false);
    }

    function canCall(address caller, address, bytes4) public view returns (bool) {
        return allowance[caller];
    }
}
