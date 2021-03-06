// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Game.sol";
import "./TaxableGameKey.sol";

contract KeyMarketplace {
    
    // Maps Game to Key Contract
    mapping(address => address) public gameToKeyAddress;

    // Maps Game to Receiver Contract
    mapping(address => address payable) public gameToReceiver;
    
    // Maps Keys Contract to KeyID to Price
    mapping(address => mapping(uint256 => uint256)) public keyAddressToKeyIDToPrice;

    // Maps keys to last time they were traded
    mapping(address => mapping(uint256 => uint256)) public keyAddressToKeyIDToLastTimeTrasfered;

    // Maps Keys Contract to Original (New) Key Price
    mapping(address => uint256) public gameAddressToOriginalPrice;

    // Maps how much revenue has been accumulated for each address (be it developer or store)
    mapping(address => uint256) public addressToBalance;

    // Maps key address to revenue share calculator between key reseller and publisher
    mapping(address => address) public keyAddressToRevenueCalculator;

    // How much (0 to 100)% of each transaction the marketplace takes
    uint256 public royalties;

    // The Store's Address
    address public store;

    constructor(address _store, uint256 _royalties) {
        store = _store;
        royalties = _royalties;
    }

    // Sets key for sale
    function setKeyForSale(address _keyAddress, uint256 _keyID, uint256 price) public {
        TaxableGameKey key = TaxableGameKey(_keyAddress);

        require(msg.sender == key.keyToOwner(_keyID), "KEY MARKETPLACE: msg.sender is not key owner");
        require(key.keyApprovedForTransfer(_keyID) == true, "KEY MARKETPLACE: key is not approved for sale");

        keyAddressToKeyIDToPrice[_keyAddress][_keyID] = price; // Sets key price
    }
    
    // Buys original new key
    function buyOriginalKey(address _gameAddress) payable public {
        address keyAddress = gameToKeyAddress[_gameAddress];
        TaxableGameKey key = TaxableGameKey(keyAddress);

        uint256 price = gameAddressToOriginalPrice[_gameAddress];

        require(msg.value >= price, "KEY MARKETPLACE: msg.value is not enough");
        
        /*
            TODO: Implement Royalties for all parties
        */

        addressToBalance[store] += price * (royalties / 100); // Transfers royalties to store
        price -= (royalties / 100) * price; // Reduces price by store royalties %

        addressToBalance[gameToReceiver[_gameAddress]] += price; // Transfers royalties to receiver
        
        key.mint(msg.sender); // Mints key to msg.sender
    }

    // Buys lowest priced key
    function buyLowestPriceKey(address _gameAddress) payable public {
        address keyAddress = gameToKeyAddress[_gameAddress];
        TaxableGameKey key = TaxableGameKey(keyAddress);
        uint256 keyID = getLowestPriceKey(keyAddress); // Gets keyID of lowest price key
        
        require(msg.sender == key.keyToOwner(keyID), "KEY MARKETPLACE: msg.sender is not key owner");
        
        uint256 price = keyAddressToKeyIDToPrice[keyAddress][keyID]; // Gets price of lowest price key
        
        require(msg.value >= price, "KEY MARKETPLACE: msg.value is not enough to buy key");

        /*
            TODO: Transfer to receiver and key owner 
        */
        
        uint256 keyOwnerRoyalties = 50; // TEMPORARY REVENUE SHARE

        addressToBalance[store] += price * (royalties / 100); // Transfers royalties to store
        price -= (royalties / 100) * price; // Reduces price by store royalties %
        
        addressToBalance[key.keyToOwner(keyID)] += price * (keyOwnerRoyalties / 100); // Transfers royalties to key owner
        price -= (keyOwnerRoyalties / 100) * price; // Reduces price by owner royalties %

        addressToBalance[gameToReceiver[_gameAddress]] += price; // Transfers royalties to receiver

        transferKey(msg.sender, keyAddress, keyID); // Transfer key to msg.sender
        keyAddressToKeyIDToPrice[keyAddress][keyID] = uint256(0); // Removes key from marketplace
    }

    // Returns the lowest priced key for a specific key address (Excluding keys sould by msg.sender)
    function getLowestPriceKey(address _keyAddress) public view returns (uint256) {
        TaxableGameKey key = TaxableGameKey(_keyAddress);

        uint256 lowestPrice = uint256(0); // Lowest price found
        uint256 lowestKeyID = uint256(0); // Lowest key ID found
        bool keyFound = false; // Whether or not a key was found
        
        for (uint256 keyID = uint256(0); keyID < key.totalMinted(); keyID++) {
            
            if (key.keyApprovedForTransfer(keyID) == true) { // Key must be approved for sale
                
                keyFound = true; // At least one key needs to be found
                
                if (key.keyToOwner(keyID) != msg.sender && keyAddressToKeyIDToPrice[_keyAddress][keyID] < lowestPrice) { // Key must be lowest price yet and cannot belong to msg.sender
                    lowestPrice = keyAddressToKeyIDToPrice[_keyAddress][keyID]; // Sets new lowest price
                    lowestKeyID = keyID; // Sets new lowest priced key ID
                }
            }
        }

        require(keyFound == true, "KEY MARKETPLACE: No keys for sale found for this key address.");

        return lowestKeyID;
    }

    // Registers a new game on the platform or binds it to a new 
    function registerNewGame(address _developer, address payable _receiver, uint256 _originalKeyPrice) public {
        TaxableGameKey key = new TaxableGameKey(address(this)); // Creates a new key to access the game
        Game game = new Game(_developer, address(this)); // Creates a new game tethered to this marketplace
        
        gameToReceiver[address(game)] = _receiver; // Sets receiver for game's revenue
        gameToKeyAddress[address(game)] = address(key); // Sets key address for game
        gameAddressToOriginalPrice[address(game)] = _originalKeyPrice; // Sets original key price for game
    }

    // Returns a game's download link to the player
    function getGameLink(address _gameAddress, uint256 _keyID, uint256 _version) public view returns (string memory) {
        TaxableGameKey key = TaxableGameKey(gameToKeyAddress[_gameAddress]);
        require(key.keyToOwner(_keyID) == msg.sender, "KEY MARKETPLACE: msg.sender is not key owner");

        Game game = Game(_gameAddress);
        return game.getDownloadLink(_version); // Returns game's link
    }

    // Updates last time key was traded
    function updateKeyLastTimeTransfered(address _keyAddress, uint256 _keyID) private {
        keyAddressToKeyIDToLastTimeTrasfered[_keyAddress][_keyID] = block.timestamp;
    }

    // Transfers Key to another address
    function transferKey(address _to, address _keyAddress, uint256 _keyID) private {
        TaxableGameKey key = TaxableGameKey(_keyAddress);

        require(key.keyApprovedForTransfer(_keyID) == true, "KEY MARKETPLACE: key is not approved for transfering");

        key.transferTo(_keyID, _to); // Transfer key to _to
        updateKeyLastTimeTransfered(_keyAddress, _keyID); // Updates last time key was traded
    }

}
