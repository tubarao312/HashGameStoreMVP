// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Beacon is Ownable {
    address public implementation;
    bool public locked;

    // Changes the implementation address where the upgradeable contract will get its logic from
    function upgrade(address newImplementation) public onlyOwner {
        require(
            !locked,
            "BEACON: Beacon is locked and may never change implementation again."
        );

        implementation = newImplementation;
    }
}
