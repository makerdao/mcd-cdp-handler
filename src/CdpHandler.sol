pragma solidity ^0.4.24;

import "ds-proxy/proxy.sol";

contract CdpHandler is DSProxy {
    CdpRegistry public registry;

    constructor(DSProxyCache _cacheAddr, address _owner) public DSProxy(_cacheAddr) {
        registry = CdpRegistry(msg.sender);
        owner = _owner;
    }

    // Overwirtes setOwner method be executed only by the registry
    function setOwner(address owner_) public {
        require(msg.sender == address(registry), "Only registry can set new owner");
        owner = owner_;
        emit LogSetOwner(owner);
    }
}

contract CdpRegistry is DSProxyFactory {
    mapping(address => CdpHandler[]) public cdps;

    function getCount(address owner) public view returns (uint count) {
        count = cdps[owner].length;
    }

    function create() public returns (CdpHandler handler) {
        handler = new CdpHandler(cache, msg.sender);
        cdps[msg.sender].push(handler);
    }

    function setOwner(uint pos, address newOwner) public {
        CdpHandler handler = cdps[msg.sender][pos];
        require(handler != address(0), "Handler doesn't exist");
        handler.setOwner(newOwner);
        delete cdps[msg.sender][pos]; // Check this
        cdps[newOwner].push(handler);
    }
}
