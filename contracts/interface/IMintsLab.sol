// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMintsLab {
    enum fileType {
        image,
        audio,
        video,
        gif,
        other
    }

    function checkRoyality(uint256 ftype) external view returns (bool, uint256);

    function governanceDetails()
        external
        view
        returns (
            address wallet,
            address dev,
            uint256 govShare
        );
}
