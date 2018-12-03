/// CdpAuthority.sol

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
