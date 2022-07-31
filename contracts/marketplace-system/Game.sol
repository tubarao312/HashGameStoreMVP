// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

contract Game {
    // Developer Address
    address public developer;
    
    // Marketplace Address
    address public marketplace;

    // Download links
    uint256 public totalVersions;
    mapping(uint256 => string) versionToLink;

    constructor(address _developer, address _marketplace) {
        developer = _developer;
        marketplace = _marketplace;
    }

    // Submits new version of the game's files
    function submitNewGameFile(string memory link) public {
        require(msg.sender == developer, "GAME: msg.sender is not developer address.");

        versionToLink[totalVersions] = link; // Adds a new link 
        totalVersions++; // Increments version counter
    }

    // Gets total versions of the game
    function getDownloadLink(uint256 version) public view returns (string memory) {
        require(version >= 0 && version < totalVersions, "GAME: Requested version not valid.");
        require(msg.sender == marketplace, "GAME: Requester is not marketplace.");

        return versionToLink[version];
    }

}