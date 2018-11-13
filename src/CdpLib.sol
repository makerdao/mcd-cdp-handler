pragma solidity ^0.4.24;

contract GemLike {
    function approve(address, uint) public;
    function transferFrom(address, address, uint) public;
}

contract ETHJoinLike {
    function join(bytes32) public payable;
    function exit(address, uint) public;
}

contract GemJoinLike {
    function gem() public returns (GemLike);
    function join(bytes32, uint) public payable;
    function exit(address, uint) public;
}

contract DaiJoinLike {
    function dai() public returns (GemLike);
    function join(bytes32, uint) public payable;
    function exit(address, uint) public;
}

contract PitLike {
    function frob(bytes32, int, int) public;
}

contract CdpLib {
    function ethJoin_join(address apt, bytes32 urn) public payable {
        ETHJoinLike(apt).join.value(msg.value)(urn);
    }

    function ethJoin_exit(address apt, address guy, uint wad) public {
        ETHJoinLike(apt).exit(guy, wad);
    }

    function gemJoin_join(address apt, bytes32 urn, uint wad) public payable {
        GemJoinLike(apt).gem().transferFrom(msg.sender, this, wad);
        GemJoinLike(apt).gem().approve(apt, uint(-1));
        GemJoinLike(apt).join(urn, wad);
    }

    function gemJoin_exit(address apt, address guy, uint wad) public {
        GemJoinLike(apt).exit(guy, wad);
    }

    function daiJoin_join(address apt, bytes32 urn, uint wad) public {
        DaiJoinLike(apt).dai().transferFrom(msg.sender, this, wad);
        DaiJoinLike(apt).dai().approve(apt, uint(-1));
        DaiJoinLike(apt).join(urn, wad);
    }

    function daiJoin_exit(address apt, address guy, uint wad) public {
        DaiJoinLike(apt).exit(guy, wad);
    }

    function frob(address pit, bytes32 ilk, int dink, int dart) public {
        PitLike(pit).frob(ilk, dink, dart);
    }
}
