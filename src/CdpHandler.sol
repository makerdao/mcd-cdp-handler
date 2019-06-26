pragma solidity >=0.5.0;

import "ds-proxy/proxy.sol";

contract CdpHandler is DSProxy {
    CdpRegistry public registry;

    event Approval(address indexed src, address indexed guy, bool status);

    constructor(address _registry, address _owner) public DSProxy(address(CdpRegistry(_registry).cache())) {
        registry = CdpRegistry(_registry);
        owner = _owner;
    }

    function setOwner(address owner_) public {
        registry.setOwner(owner_);
        super.setOwner(owner_);
    }
}

contract CdpRegistry is DSProxyFactory {
    mapping(address => address payable []) public handlers;
    mapping(address => uint) public pos;
    mapping(address => bool) public inRegistry;

    function getCount(address owner) public view returns (uint count) {
        count = handlers[owner].length;
    }

    function build() public returns (address payable handler) {
        handler = build(msg.sender);
    }

    function build(address owner) public returns (address payable handler) {
        handler = address(new CdpHandler(address(this), owner));
        pos[handler] = handlers[owner].push(handler) - 1;
        inRegistry[handler] = true;
    }

    function setOwner(address owner_) public {
        require(inRegistry[msg.sender], "Sender is not a CdpHandler from the Registry");
        delete handlers[CdpHandler(msg.sender).owner()][pos[msg.sender]];
        pos[msg.sender] = handlers[owner_].push(msg.sender) - 1;
    }
}
