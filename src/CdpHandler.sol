/// CdpHandler.sol

// Copyright (C) 2018 Gonzalo Balabasquer <gbalabasquer@gmail.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
