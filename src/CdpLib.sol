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

contract VatLike {
    function ilks(bytes32) public view returns (uint, uint);
    function dai(bytes32) public view returns (uint);
}

contract PitLike {
    function frob(bytes32, int, int) public;
    function vat() public view returns (VatLike);
}

contract CdpLib {
    uint256 constant ONE = 10 ** 27;

    // Internal methods
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function _getLockDink(
        address pit,
        bytes32 ilk,
        uint wad
    ) internal view returns (int dink) {
        (uint take,) = PitLike(pit).vat().ilks(ilk);
        dink = int(mul(wad, ONE) / take);
    }

    function _getFreeDink(
        address pit,
        bytes32 ilk,
        uint wad
    ) internal view returns (int dink) {
        (uint take,) = PitLike(pit).vat().ilks(ilk);
        dink = - int(mul(wad, ONE) / take);
    }

    function _getDrawDart(
        address pit,
        bytes32 ilk,
        uint wad
    ) internal view returns (int dart) {
        (, uint rate) = PitLike(pit).vat().ilks(ilk);
        uint dai = PitLike(pit).vat().dai(bytes32(uint(address(this))));

        if (dai < mul(wad, ONE)) {
            // If there was already enough DAI generated but not extracted as token, ignore this statement and do the exit directly
            // Otherwise generate the missing necessart part
            dart = int(sub(mul(wad, ONE), dai) / rate);
            dart = int(mul(uint(dart), rate) < mul(wad, ONE) ? dart + 1 : dart); // This is neeeded due lack of precision of dart value
        }
    }

    function _getWipeDart(
        address pit,
        bytes32 ilk
    ) internal view returns (int dart) {
        uint dai = PitLike(pit).vat().dai(bytes32(uint(address(this))));
        (, uint rate) = PitLike(pit).vat().ilks(ilk);
        // Decrease the whole allocated dai balance: dai / rate
        dart = - int(dai / rate);
    }

    // Public methods
    function ethJoin_join(address apt, bytes32 urn) public payable {
        ETHJoinLike(apt).join.value(msg.value)(urn);
    }

    function ethJoin_exit(address apt, address guy, uint wad) public {
        ETHJoinLike(apt).exit(guy, wad);
    }

    function gemJoin_join(address apt, bytes32 urn, uint wad) public payable {
        GemJoinLike(apt).gem().transferFrom(msg.sender, address(this), wad);
        GemJoinLike(apt).gem().approve(apt, uint(-1));
        GemJoinLike(apt).join(urn, wad);
    }

    function gemJoin_exit(address apt, address guy, uint wad) public {
        GemJoinLike(apt).exit(guy, wad);
    }

    function daiJoin_join(address apt, bytes32 urn, uint wad) public {
        DaiJoinLike(apt).dai().transferFrom(msg.sender, address(this), wad);
        DaiJoinLike(apt).dai().approve(apt, uint(-1));
        DaiJoinLike(apt).join(urn, wad);
    }

    function daiJoin_exit(address apt, address guy, uint wad) public {
        DaiJoinLike(apt).exit(guy, wad);
    }

    function frob(address pit, bytes32 ilk, int dink, int dart) public {
        PitLike(pit).frob(ilk, dink, dart);
    }

    function lockETH(
        address ethJoin,
        address pit
    ) public payable {
        ethJoin_join(ethJoin, bytes32(uint(address(this))));
        frob(pit, "ETH", _getLockDink(pit, "ETH", msg.value), 0);
    }

    function lockGem(
        address gemJoin,
        address pit,
        bytes32 ilk,
        uint wad
    ) public {
        gemJoin_join(gemJoin, bytes32(uint(address(this))), wad);
        frob(pit, ilk, _getLockDink(pit, ilk, wad), 0);
    }

    function freeETH(
        address ethJoin,
        address pit,
        address guy,
        uint wad
    ) public {
        frob(pit, "ETH", _getFreeDink(pit, "ETH", wad), 0);
        ethJoin_exit(ethJoin, guy, wad);
    }

    function freeGem(
        address gemJoin,
        address pit,
        bytes32 ilk,
        address guy,
        uint wad
    ) public {
        frob(pit, ilk, _getFreeDink(pit, ilk, wad), 0);
        gemJoin_exit(gemJoin, guy, wad);
    }

    function draw(
        address daiJoin,
        address pit,
        bytes32 ilk,
        address guy,
        uint wad
    ) public {
        frob(pit, ilk, 0, _getDrawDart(pit, ilk, wad));
        daiJoin_exit(daiJoin, guy, wad);
    }

    function wipe(
        address daiJoin,
        address pit,
        bytes32 ilk,
        uint wad
    ) public {
        daiJoin_join(daiJoin, bytes32(uint(address(this))), wad);
        frob(pit, ilk, 0, _getWipeDart(pit, ilk));
    }

    function lockETHAndDraw(
        address ethJoin,
        address daiJoin,
        address pit,
        address guy,
        uint wadD
    ) public payable {
        ethJoin_join(ethJoin, bytes32(uint(address(this))));
        frob(pit, "ETH", _getLockDink(pit, "ETH", msg.value), _getDrawDart(pit, "ETH", wadD));
        daiJoin_exit(daiJoin, guy, wadD);
    }

    function lockGemAndDraw(
        address gemJoin,
        address daiJoin,
        address pit,
        bytes32 ilk,
        address guy,
        uint wadC,
        uint wadD
    ) public {
        gemJoin_join(gemJoin, bytes32(uint(address(this))), wadC);
        frob(pit, ilk, _getLockDink(pit, ilk, wadC), _getDrawDart(pit, ilk, wadD));
        daiJoin_exit(daiJoin, guy, wadD);
    }

    function wipeAndFreeETH(
        address ethJoin,
        address daiJoin,
        address pit,
        address guy,
        uint wadC,
        uint wadD
    ) public {
        daiJoin_join(daiJoin, bytes32(uint(address(this))), wadD);
        frob(pit, "ETH", _getFreeDink(pit, "ETH", wadC), _getWipeDart(pit, "ETH"));
        ethJoin_exit(ethJoin, guy, wadC);
    }

    function wipeAndFreeGem(
        address gemJoin,
        address daiJoin,
        address pit,
        bytes32 ilk,
        address guy,
        uint wadC,
        uint wadD
    ) public {
        daiJoin_join(daiJoin, bytes32(uint(address(this))), wadD);
        frob(pit, ilk, _getFreeDink(pit, ilk, wadC), _getWipeDart(pit, ilk));
        gemJoin_exit(gemJoin, guy, wadC);
    }
}
