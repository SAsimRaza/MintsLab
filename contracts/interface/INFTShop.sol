// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INFTShop {
    struct Post {
        uint256 postId;
        uint256 price;
        uint256 highestBid;
        bool bidActive;
        address newOwner;
        fileType ftype;
    }

    enum fileType {
        image,
        audio,
        video,
        gif,
        other
    }

    event Owner(address shop, address lastOwner, address newOwner);

    function createPost(
        uint256 price,
        fileType ftype,
        string memory tokenURI
    ) external returns (uint256);

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data
    // ) external payable;
}
