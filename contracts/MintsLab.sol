// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interface/IMintsLab.sol";
import "./NFTshop.sol";

contract MintsLabFactory is IMintsLab {
    bool royalityStatus;
    address private wallet;
    address private immutable dev;

    uint256 govShare;
    uint256 signupFees;

    mapping(address => address) public userToShop;
    mapping(uint256 => uint256) public ftypetoRoyality;

    constructor(
        address _wallet,
        address _dev,
        uint256 _govShare,
        uint256 _signupFees,
        uint256 _initialRoyality
    ) {
        wallet = _wallet;
        dev = _dev;
        govShare = _govShare;
        signupFees = _signupFees;

        ftypetoRoyality[0] = _initialRoyality;
        ftypetoRoyality[1] = _initialRoyality;
        ftypetoRoyality[2] = _initialRoyality;
        ftypetoRoyality[3] = _initialRoyality;
        ftypetoRoyality[4] = _initialRoyality;
    }

    modifier onlyGovernance() {
        require(msg.sender == wallet, "NA");
        _;
    }

    function changeGovernance(address newGov) external onlyGovernance {
        wallet = newGov;
    }

    function updateRoyality(
        uint256 _ftype,
        uint256 _royality,
        bool _royalityStatus
    ) external onlyGovernance {
        if (_ftype < 5) {
            ftypetoRoyality[_ftype] = _royality;
        } else {
            signupFees = _royality;
            royalityStatus = _royalityStatus;
        }
    }

    function updateGovernanceShare(uint256 _govSharePercentage, bool _royalityStatus) external onlyGovernance {
        govShare = _govSharePercentage;
        royalityStatus = _royalityStatus;
    }

    function governanceDetails()
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (wallet, dev, govShare);
    }

    function checkRoyality(uint256 ftype) public view override returns (bool, uint256) {
        return (royalityStatus, ftypetoRoyality[ftype]);
    }

    function createNFTshop(string calldata name, string calldata symbol) external returns (address _shop) {
        require(userToShop[msg.sender] == address(0), "AE");
        if (signupFees > 0) {
            (bool sent, ) = wallet.call{ value: signupFees }("");
            require(sent, "Failed");
        }

        _shop = address(new NFTstore(name, symbol));
        userToShop[msg.sender] = _shop;
    }
}
