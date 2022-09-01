// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./GameNew.sol";
import "./RevenueCutCalculator.sol";

contract KeyMarketplace {
    // Marketplace information
    uint256 public royalties; // How much (0 to 100)% of each transaction the marketplace takes
    uint256 public owner; // Owner of the contract (Hash Game Store)

    // Maps Game to Receiver Contract
    mapping(address => address payable) public gameToReceiver;

    // Game Information
    mapping(address => mapping(uint256 => uint256))
        public gameAddressToKeyIDToPrice; // Maps game contract to key ID to price of said key
    mapping(address => address) public gameAddressToRevenueCalculator; // Maps key address to revenue share calculator between key reseller and publisher
    mapping(address => uint256) public gameAddressToOriginalPrice; // Maps Keys Contract to Original (New) Key Price

    // Maps how much revenue has been accumulated for each address (be it developer or store)
    mapping(address => uint256) public addressToBalance;

    constructor(uint256 _royalties) {
        royalties = min(100, _royalties);
        royalties = max(0, royalties);

        owner = msg.sender;
    }

    // Sets key for sale
    function setKeyForSale(
        address _gameAddress,
        uint256 _keyID,
        uint256 price
    ) public {
        Game game = Game(_gameAddress);

        require(
            msg.sender == game.keyToOwner(_keyID),
            "KEY MARKETPLACE: msg.sender is not key owner"
        );
        require(
            game.keyApprovedForTransfer(_keyID) == true,
            "KEY MARKETPLACE: key is not approved for sale"
        );

        gameAddressToKeyIDToPrice[_gameAddress][_keyID] = price; // Sets key price
    }

    // Buys original new key
    function buyOriginalKey(address _gameAddress) public payable {
        Game game = Game(_gameAddress);

        uint256 price = gameAddressToOriginalPrice[_gameAddress];

        require(
            msg.value >= price,
            "KEY MARKETPLACE: msg.value is not enough to purchase original key"
        );

        /*
            TODO: Implement Royalties for all parties
        */

        addressToBalance[store] += price * (royalties / 100); // Transfers royalties to store
        price -= (royalties / 100) * price; // Reduces price by store royalties %

        addressToBalance[gameToReceiver[_gameAddress]] += price; // Transfers royalties to receiver

        game.mint(msg.sender); // Mints key to msg.sender
    }

    // Buys lowest priced key
    function buyLowestPriceKey(address _gameAddress) public payable {
        Game game = Game(_gameAddress);
        uint256 keyID = getLowestPriceKey(_gameAddress); // Gets keyID of lowest price key

        require(
            msg.sender == game.keyToOwner(keyID),
            "KEY MARKETPLACE: msg.sender is not key owner"
        );

        uint256 price = gameAddressToKeyIDToPrice[_gameAddress][keyID]; // Gets price of lowest price key

        require(
            msg.value >= price,
            "KEY MARKETPLACE: msg.value is not enough to buy resold key"
        );

        /*
            TODO: Transfer to receiver and key owner 
        */

        // Get the deterministic revenue cut calculator contract
        RevenueCutCalculator revenueCalculator = RevenueCutCalculator(
            gameAddressToRevenueCalculator[_gameAddress]
        );

        // Gets last time key was traded
        uint256 lastTransferDate = game.keyToLastTimeTraded(keyID);

        // Gets royalties for key owner based on how long they've held the key for
        uint256 keyOwnerRoyalties = revenueCalculator.getResult(
            lastTransferDate,
            block.timestamp
        );

        // Must be between 0 and 100
        keyOwnerRoyalties = min(100, keyOwnerAddress);
        keyOwnerRoyalties = max(0, keyOwnerAddress);

        /* BIG QUESTION: Let's say a certain game costs $100, developer has 90% resale royalties, 
        and Hash Game Store has 10% royalties. Our tax is always applied first so we automatically
        get $10. How should the royalties for the developer now work? Should they get 90% of the 
        remaining $90 or should they get $90 and leave the player with 0$?

        I see two options here:
        1. We apply the developer's royalties AFTER taking the store's cut, meaning they'd get 
        $81 dollars in this situation. If we do this, we must communicate it extremely well
        to the developers and players reselling.
        2. We apply the developer's royalties on the TOTAL cake, meaning in this case they'd 
        get the 90$. I think is a bit unfair and also less intuitive from a programming
        point of view. In my honest opinion we should opt for the first option. */

        // Transfers royalties to owner
        addressToBalance[store] += price * (royalties / 100);
        price -= (royalties / 100) * price; // Reduces price by store royalties %

        // Transfer royalties to player
        address keyOwnerAddress = game.keyToOwner(keyID); // Gets address of current key owner
        addressToBalance[keyOwnerAddress] += price * (keyOwnerRoyalties / 100); // Transfers royalties to key owner
        price -= (keyOwnerRoyalties / 100) * price; // Reduces price by owner royalties %

        // Transfer royalties to developer
        address receiverAddress = gameToReceiver[_gameAddress]; // Gets receiver address
        addressToBalance[receiverAddress] += price; // Transfers royalties to receiver

        transferKey(msg.sender, gameAddress, keyID); // Transfer key to msg.sender
        gameAddressToKeyIDToPrice[gameAddress][keyID] = uint256(0); // Removes key from marketplace
    }

    // Returns the lowest priced key for a specific key address (Excluding keys sould by msg.sender)
    function getLowestPriceKey(address _gameAddress)
        public
        view
        returns (uint256)
    {
        Game game = Game(_gameAddress);

        uint256 lowestPrice = uint256(0); // Lowest price found
        uint256 lowestKeyID = uint256(0); // Lowest key ID found
        bool keyFound = false; // Whether or not a key was found
        uint256 totalKeysMinted = game.totalMinted();

        for (uint256 keyID = 0; keyID < totalKeysMinted; keyID++) {
            if (
                game.keyApprovedForTransfer(keyID) == true && // Key must be approved for transfer
                game.keyToOwner(keyID) != msg.sender && // Key must not belong to msg.sender
                (lowestPrice == 0 ||
                    gameAddressToKeyIDToPrice[_gameAddress][keyID] <
                    lowestPrice) // Key must be lowest price yet
            ) {
                    keyFound = true; // At least one key has been found
                    lowestPrice = gameAddressToKeyIDToPrice[_gameAddress][keyID]; // Sets new lowest price
                    lowestPricedKeyID = keyID; // Sets new lowest priced key ID
                }
            }
        }

        require(
            keyFound == true,
            "KEY MARKETPLACE: No keys for sale found for this game address."
        );

        return lowestPricedKeyID;
    }

    // Registers a new game on the platform or binds it to a new. Keep maximum keys as <= 0 for infinite keys
    function registerNewGame(
        address _developer,
        address payable _receiver,
        uint256 _originalKeyPrice,
        uint256 _maximumKeys
    ) public {
        Game game = new Game(_developer, address(this), _maximumKeys); // Creates a new game tethered to this marketplace

        gameToReceiver[address(game)] = _receiver; // Sets receiver for game's revenue
        gameAddressToOriginalPrice[address(game)] = _originalKeyPrice; // Sets original key price for game
    }

    // Returns a game's download link to the player
    function getGameLink(
        address _gameAddress,
        uint256 _keyID,
        uint256 _version
    ) public view returns (string memory) {
        Game game = Game(_gameAddress);

        require(
            game.keyToOwner(_keyID) == msg.sender,
            "KEY MARKETPLACE: msg.sender is not key owner"
        );

        return game.getDownloadLink(_version); // Returns game's link
    }

    // Transfers Key to another address
    function transferKey(
        address _to,
        address _gameAddress,
        uint256 _keyID
    ) private {
        Game game = Game(_gameAddress);

        require(
            game.keyApprovedForTransfer(_keyID) == true,
            "KEY MARKETPLACE: key is not approved for transfering"
        );

        game.transferTo(_keyID, _to); // Transfer key to _to
    }

