// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

contract TaxableGameKey {
    
    // Marketplace in which this key can be traded
    address public marketplace;

    // Maps each key to its owner
    mapping(uint256 => address) public keyToOwner;

    // Maps keys to permission to be traded by the marketplace
    mapping(uint256 => bool) public keyApprovedForTransfer;

    // Keeps track of total keys minted
    uint256 public totalMinted;

    constructor(address _marketplace) {
        marketplace = _marketplace;
    }
    
    // Transfer key from one address to another
    function transferTo(uint256 _keyID, address _to) public {
        require(msg.sender == marketplace, "TGK: msg.sender is not the marketplace address");
        require(keyApprovedForTransfer[_keyID] == true, "TGK: The key is not approved by the owner for trading");

        keyToOwner[_keyID] = _to; // Updates the key's owner

        setApprovedForTrade(_keyID, false); // Updates key's tradibility status to false
    }

    // Approves key to be traded by marketplace
    function setApprovedForTrade(uint256 _keyID, bool _approved) public {
        require(msg.sender == keyToOwner[_keyID], "TGK: msg.sender is not the owner of the key");

        keyApprovedForTransfer[_keyID] = _approved; // Sets to True or False
    }

    // Mints an individual key
    function mint(address _to) public {
        require(msg.sender == marketplace, "TGK: msg.sender is not marketplace address");
        require(_to != address(0), "TGK: mint to the zero address");
        require(!exists(totalMinted), "TGK: key already minted");

        keyToOwner[totalMinted] = _to; // Sets key ownership to _to address
        totalMinted++; // Increments total keys minted
    }

    // Returns whether or not a key has been minted
    function exists(uint256 _keyID) internal view returns (bool) {
        return keyToOwner[_keyID] != address(0);
    }

}