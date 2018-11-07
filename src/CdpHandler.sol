pragma solidity ^0.4.24;

import "ds-proxy/proxy.sol";

contract CdpHandler is DSProxy {
    CdpRegistry public registry;
    mapping(address => mapping(address => bool)) allowance;

    event Approval(address indexed src, address indexed guy, bool status);

    constructor(DSProxyCache _cacheAddr, address _owner) public DSProxy(_cacheAddr) {
        registry = CdpRegistry(msg.sender);
        owner = _owner;
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig) || allowance[this.owner()][msg.sender], "No rights to execute this action");
        _;
    }

    function setOwner(address owner_) public {
        registry.setOwner(owner_);
        super.setOwner(owner_);
    }

    function rely(address guy) public {
        allowance[msg.sender][guy] = true;
        emit Approval(msg.sender, guy, true);
    }

    function deny(address guy) public {
        allowance[msg.sender][guy] = false;
        emit Approval(msg.sender, guy, false);
    }
}

contract CdpRegistry is DSProxyFactory {
    mapping(address => CdpHandler[]) public cdps;
    mapping(address => uint) public pos;
    mapping(address => bool) public inRegistry;

    function getCount(address owner) public view returns (uint count) {
        count = cdps[owner].length;
    }

    function create() public returns (CdpHandler handler) {
        handler = new CdpHandler(cache, msg.sender);
        cdps[msg.sender].push(handler);
        pos[handler] = cdps[msg.sender].length - 1;
        inRegistry[handler] = true;
    }

    function setOwner(address owner_) public {
        require(inRegistry[msg.sender], "Sender is not a CdpHandler from the Registry");
        CdpHandler handler = CdpHandler(msg.sender);
        delete cdps[handler.owner()][pos[handler]];
        cdps[owner_].push(handler);
        pos[handler] = cdps[owner_].length - 1;
    }
}
