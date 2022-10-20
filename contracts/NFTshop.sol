// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interface/INFTShop.sol";
import "./interface/IMintsLab.sol";

contract NFTstore is ERC721URIStorage, INFTShop, IERC721Receiver {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address owner;
    address mintslabFactory;

    mapping(uint256 => Post) public idToPost;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier newOwner(uint256 postId) {
        require(msg.sender == idToPost[postId].newOwner);
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenIds.increment();
        uint256 profileId = _tokenIds.current();
        _mint(msg.sender, profileId);
    }

    function createPost(
        uint256 price,
        fileType ftype,
        string memory tokenURI
    ) external override onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 postId = _tokenIds.current();
        Post storage post = idToPost[postId];
        post.postId = postId;
        post.price = price;
        post.newOwner = msg.sender;
        post.ftype = ftype;
        _mint(msg.sender, postId);
        _setTokenURI(postId, tokenURI);

        return (postId);
    }

    function updatePost(
        uint256 _tokenId,
        uint256 price,
        string memory tokenURI
    ) external newOwner(_tokenId) {
        if (_tokenId != 1) {
            Post storage post = idToPost[_tokenId];
            post.price = price;
        }

        _setTokenURI(_tokenId, tokenURI);
    }

    function updateOwner(address _newOwner) external onlyOwner {
        emit Owner(address(this), owner, owner = _newOwner);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");

        Post memory cache = idToPost[tokenId];
        (bool royalityStatus, uint256 royalityFee) = IMintsLab(mintslabFactory).checkRoyality(uint256(cache.ftype));

        idToPost[tokenId].newOwner = msg.sender;

        uint256 royality = ((idToPost[tokenId].price * royalityFee) / 100);

        if (royalityStatus) {
            (address wallet, address dev, uint256 govShare) = IMintsLab(mintslabFactory).governanceDetails();
            _payRoyality(tokenId, wallet, dev, royality, govShare);
        }

        (bool success2, ) = payable(cache.newOwner).call{ value: idToPost[tokenId].price - royality }("");
        require(success2);

        safeTransferFrom(from, to, tokenId, _data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");
        (bool royalityStatus, uint256 royalityFee) = IMintsLab(mintslabFactory).checkRoyality(
            uint256(idToPost[tokenId].ftype)
        );

        idToPost[tokenId].newOwner = msg.sender;

        uint256 royality = ((idToPost[tokenId].price * royalityFee) / 100);

        if (royalityStatus) {
            (address wallet, address dev, uint256 govShare) = IMintsLab(mintslabFactory).governanceDetails();
            _payRoyality(tokenId, wallet, dev, royality, govShare);
        }

        (bool success2, ) = payable(idToPost[tokenId].newOwner).call{ value: idToPost[tokenId].price - royality }("");
        require(success2);

        safeTransferFrom(from, to, tokenId);
    }

    function _payRoyality(
        uint256 tokenId,
        address wallet,
        address dev,
        uint256 _royality,
        uint256 govShare
    ) internal {
        require(idToPost[tokenId].price <= msg.value, "Failed");

        uint256 share = (govShare / _royality) * 100;

        (bool success1, ) = payable(wallet).call{ value: share }("");

        require(success1);

        share = 100 - govShare;

        share = (share / _royality) * 100;

        (success1, ) = payable(dev).call{ value: share }("");

        require(success1);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sendNFTgift(uint256 tokenId, address claimer) external onlyOwner {
        require(claimer != address(0) && tokenId > 0, "ZA");
        IERC721(address(this)).safeTransferFrom(msg.sender, claimer, tokenId);
    }

    receive() external payable {
        (bool success1, ) = payable(owner).call{ value: msg.value }("");
        require(success1, "Failed");
    }
}
