pragma solidity ^0.4.24;

import "ds-proxy/proxy.sol";

contract CdpHandler is DSProxy {
    CdpRegistry public registry;

    event Approval(address indexed src, address indexed guy, bool status);

    constructor(address _registry, address _owner) public DSProxy(CdpRegistry(_registry).cache()) {
        registry = CdpRegistry(_registry);
        owner = _owner;
    }

    function setOwner(address owner_) public {
        registry.setOwner(owner_);
        super.setOwner(owner_);
    }
}

contract CdpRegistry is DSProxyFactory {
    mapping(address => CdpHandler[]) public handlers;
    mapping(address => uint) public pos;
    mapping(address => bool) public inRegistry;

    function getCount(address owner) public view returns (uint count) {
        count = handlers[owner].length;
    }

    function build() public returns (address handler) {
        handler = build(msg.sender);
    }

    function build(address owner) public returns (address handler) {
        handler = new CdpHandler(this, owner);
        pos[handler] = handlers[owner].push(CdpHandler(handler)) - 1;
        inRegistry[handler] = true;
    }

    function setOwner(address owner_) public {
        require(inRegistry[msg.sender], "Sender is not a CdpHandler from the Registry");
        CdpHandler handler = CdpHandler(msg.sender);
        delete handlers[handler.owner()][pos[handler]];
        pos[handler] = handlers[owner_].push(handler) - 1;
    }
}
