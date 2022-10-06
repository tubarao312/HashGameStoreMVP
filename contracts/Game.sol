// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract GameStorage {
    // Developer and marketplace addresses
    address public developer;
    address public marketplace;

    // Download IPFS Links
    uint256 public totalVersions; // Total versions that have been submitted by the developer
    mapping(uint256 => string) internal versionToDownloadLink; // All links to IPFS downloadds submitted by the developer

    // Key Information
    mapping(uint256 => address) public keyToOwner; // Maps each key to its owner
    mapping(uint256 => uint256) public keyToLastTimeTraded; // Maps each key to last time it was transfered
    mapping(uint256 => bool) public keyApprovedForTransfer; // Maps keys to permission to be traded by the marketplace

    // Keeps track of the amount of keys owned by each owner
    mapping(address => uint256) public ownerToKeyCount;

    // Total Key Info
    uint256 public totalKeysMinted; // Keeps track of total keys minted
    uint256 public maximumKeysMinted; // Keeps track of maximum amount of keys that can be minted
}

contract Game is GameStorage, Initializable {
    // Events
    event KeyTransfered(address from, address to); // Emitted whenever a key is minted or transfered

    // Constructor
    function initialize(
        address _developer,
        address _marketplace,
        uint256 _maximumKeysMinted
    ) public initializer {
        developer = _developer;
        marketplace = _marketplace;
        maximumKeysMinted = _maximumKeysMinted;
    }

    // Submits new version of the game's files
    function submitNewGameFile(string memory link) public {
        require(
            msg.sender == developer,
            "GAME: msg.sender is not developer address."
        );

        versionToDownloadLink[totalVersions] = link; // Adds a new version
        totalVersions++; // Increments version counter
    }

    // Gets total versions of the game
    function getDownloadLink(uint256 version)
        public
        view
        returns (string memory)
    {
        require(
            version >= 0 && version < totalVersions,
            "GAME: Requested version not valid."
        );
        require(
            msg.sender == marketplace,
            "GAME: Requester is not marketplace."
        );

        return versionToDownloadLink[version];
    }

    // Transfer key from one address to another
    function transferTo(uint256 _keyID, address _to) public {
        require(
            msg.sender == marketplace,
            "TGK: msg.sender is not the marketplace address"
        );
        require(
            keyApprovedForTransfer[_keyID] == true,
            "TGK: The key is not approved by the owner for trading"
        );

        address previousKeyOwner = keyToOwner[_keyID]; // Gets previous owner of key
        emit KeyTransfered(previousKeyOwner, _to); // Emits event

        ownerToKeyCount[previousKeyOwner]--; // Decrements the owner's key count
        keyToOwner[_keyID] = _to; // Updates the key's owner
        ownerToKeyCount[_to]++; // Increments the new owner's key count
        updateLastTimeTraded(_keyID); // Updates last time key was traded
        setApprovedForTrade(_keyID, false); // Updates key's tradibility status to false
    }

    // Updates last time a key was traded
    function updateLastTimeTraded(uint256 _keyID) private {
        keyToLastTimeTraded[_keyID] = block.timestamp;
    }

    // Approves key to be traded by marketplace
    function setApprovedForTrade(uint256 _keyID, bool _approved) public {
        require(
            msg.sender == keyToOwner[_keyID],
            "TGK: msg.sender is not the owner of the key"
        );

        keyApprovedForTransfer[_keyID] = _approved; // Sets to True or False
    }

    // Mints an individual key
    function mint(address _to) public {
        require(
            msg.sender == marketplace,
            "TGK: msg.sender is not marketplace address"
        );
        require(
            maximumKeysMinted <= 0 || totalKeysMinted <= maximumKeysMinted,
            "TGK: maximum amount of keys minted reached"
        );
        require(_to != address(0), "TGK: mint to the zero address");
        require(!exists(totalKeysMinted), "TGK: key already minted");

        uint256 keyID = totalKeysMinted;

        emit KeyTransfered(address(0), _to); // Emits event
        keyToOwner[keyID] = _to; // Sets key ownership to _to address
        ownerToKeyCount[_to]++; // Increments the new owner's key count
        updateLastTimeTraded(keyID); // Updates last time key was traded
        totalKeysMinted++; // Increments total keys minted
    }

    // Returns whether or not a key has been minted
    function exists(uint256 _keyID) internal view returns (bool) {
        return keyToOwner[_keyID] != address(0);
    }

    // Returns whether or not someone owns more than one key
    function ownsKey(address _keyOwner) public view returns (bool) {
        return (ownerToKeyCount[_keyOwner] > 0);
    }
}
