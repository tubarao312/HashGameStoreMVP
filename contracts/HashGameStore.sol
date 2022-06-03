// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./HashToken.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract HashGameStore {
    struct Game {
        uint256 id; // ID of the game
        address developerAddress; // Developer the game belongs to
        uint256 quantityAvailable; // How many keys can still be minted
        bool limited; // If the game has a limited amount of keys that can be minted
        uint256 price; // TEMPORARY - Base price of each game key
        string downloadLink; // Filecoin Location
    }

    // Global Variables

    // List of all games on the platform
    Game[] private games;

    // Maps wallet address to a map of gameIDs to quantity of keys owned
    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToKeysInLibrary;

    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToKeysForSale; // NOTE: How many keys of the library are for sale

    // Maps wallet address to a map of gameIDs to price of keys in said wallet
    mapping(address => mapping(uint256 => uint256))
        public addressToGameIDToPrice;

    // Keeps track of if an address has been registered
    mapping(address => bool) public addressIsRegistered;
    address[] public registeredAddresses;

    // The address of our company's wallet
    address payable minter;

    // Constants
    uint256 REVENUE_SHARE = 1; // (1/100) - Percentage that Hash Game Store takes from developers

    HashToken public token;
    AggregatorV3Interface internal priceFeed;

    // Run when contract is deployed
    constructor() public {
        minter = msg.sender; // Sets the minter as us so we can retrieve the Tokens
        token = new HashToken(5000000000000000000000); // Creates the token contract (5000 HASH)
        priceFeed = AggregatorV3Interface( // Price feed to get ETH -> USD conversion
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    // Functions ==================================================================================================================

    // Returns the ETH -> USD price conversion

    /*
    function getLatestETHPrice() private view returns (int256) {
        (uint80 a, int256 ethPrice, uint256 b, uint256 c, uint80 d) = priceFeed
            .latestRoundData();

        return ethPrice;
    }
    */

    // Checks if an address has been registered. If it hasn't, start keep tracking of it
    // PRIVATE
    function registerAddress(address a) private {
        if (!addressIsRegistered[a]) {
            addressIsRegistered[a] = true;
            registeredAddresses.push(a);
        }
    }

    // Registers a game with the developer as the msg.sender's developer (0 for infinite)
    // PUBLIC
    function gameRegister(
        uint256 price,
        uint256 quantityAvailable,
        string memory downloadLink
    ) public returns (uint256) {
        Game memory newGame;
        newGame.developerAddress = msg.sender;
        newGame.id = games.length;
        newGame.price = price;
        newGame.downloadLink = downloadLink;

        if (quantityAvailable == 0) {
            newGame.limited = false;
        } else {
            newGame.limited = true;
            newGame.quantityAvailable = quantityAvailable;
        }

        games.push(newGame);
        return games.length - 1;
    }

    // Buys and generates a new key from a developer
    // PUBLIC
    function buyOriginalKey(uint256 gameID) public {
        Game storage game = games[gameID];

        // If the game has limited quantity, said quantity must not be 0
        require(
            (!game.limited) || (game.quantityAvailable > 0),
            "All of this game's copies have sold out"
        );

        // Get the cheapest deal for the game
        uint256 price = game.price;

        // Player must have the necessary balance
        require(
            token.balanceOf(msg.sender) >= price,
            "The caller didn't have enough Hash tokens"
        );

        // Give the contract permission to transfer $HASH
        require(
            token.allowance(msg.sender, address(this)) >= price,
            "The caller didn't allow the platform to spend enough Hash tokens on their behalf"
        );

        // Subtract from the key's available stock if needed
        if (game.limited) {
            game.quantityAvailable--;
        }

        // Transfer part to Developer
        uint256 devRevenue = (price * (100 - REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, game.developerAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = (price * (REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Add key to player's wallet
        addressToGameIDToKeysInLibrary[msg.sender][gameID]++;

        // If the address isn't registered, then start keeping track of it
        registerAddress(msg.sender);
    }

    // Lists X keys of a game for sale
    // PUBLIC
    function setKeysForSale(
        uint256 gameID,
        uint256 quantity,
        uint256 price
    ) public {
        require( // The wallet must at least as many keys as it is trying to sell
            quantity <= addressToGameIDToKeysInLibrary[msg.sender][gameID],
            "The wallet does quantitynot own as many keys as it is trying to list"
        );

        // Set 'quantity' amount of keys for sale
        addressToGameIDToKeysForSale[msg.sender][gameID] = quantity;

        // Set the price of said amount of keys
        addressToGameIDToPrice[msg.sender][gameID] = price;
    }

    // Buy keys from an account
    // PRIVATE
    function buyOldKey(
        uint256 gameID,
        address walletAddress,
        uint256 quantity
    ) private {
        uint256 price = addressToGameIDToPrice[walletAddress][gameID] *
            quantity;
        uint256 availableQuantity = addressToGameIDToKeysForSale[walletAddress][
            gameID
        ];

        Game memory game = games[gameID];
        address developerAddress = game.developerAddress;

        require( // The wallet must at least as many keys as are being bought
            availableQuantity >= quantity,
            "The wallet does not own as many keys as are being bought"
        );

        require( // The wallet must own enough tokens
            token.balanceOf(msg.sender) >= price,
            "The wallet doesn't own enough funds to buy this much"
        );

        // Give the contract permission to transfer $HASH
        require(
            token.allowance(msg.sender, address(this)) >= price,
            "The caller didn't allow the platform to spend enough Hash tokens on their behalf"
        );

        // Transfer part to Reseller
        uint256 userRevenue = ((price * 89) / 100);
        token.transferFrom(msg.sender, walletAddress, userRevenue);

        // Transfer part to Developer
        uint256 devRevenue = ((price * 10) / 100);
        token.transferFrom(msg.sender, developerAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = ((price * 1) / 100);
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Transfer key quantities
        addressToGameIDToKeysForSale[walletAddress][gameID] -= quantity;
        addressToGameIDToKeysInLibrary[walletAddress][gameID] -= quantity;
        addressToGameIDToKeysInLibrary[msg.sender][gameID] += quantity;

        // If the address isn't registered, then start keeping track of it
        registerAddress(msg.sender);
    }

    // Buy the lowest priced key of a specific game
    // PUBLIC
    function buyLowestPriceKey(uint256 gameID, uint256 quantity) public {
        // Find the address that is selling a key with the lowest price
        address lowestPriceAddress = getLowestPriceReseller(gameID, msg.sender);

        buyOldKey(gameID, lowestPriceAddress, quantity);
    }

    // Public Getter Functions ---------------------------------------------------------

    // Returns the contract address of the token
    function getTokenAddress() public view returns (HashToken) {
        return token;
    }

    // Get the lowest price key for a specific game
    function getLowestKeyPrice(uint256 gameID, address exceptionAddress)
        public
        view
        returns (uint256)
    {
        address lowestPriceAddress = getLowestPriceReseller(
            gameID,
            exceptionAddress
        );

        return addressToGameIDToPrice[lowestPriceAddress][gameID];
    }

    // Get the lowest price key quantity for a specific game
    function getLowestPriceKeyQuantity(uint256 gameID, address exceptionAddress)
        public
        view
        returns (uint256)
    {
        address lowestPriceAddress = getLowestPriceReseller(
            gameID,
            exceptionAddress
        );

        return addressToGameIDToKeysForSale[lowestPriceAddress][gameID];
    }

    // Returns the lowest key price reseller for a specific game
    function getLowestPriceReseller(uint256 gameID, address exceptionAddress)
        public
        view
        returns (address)
    {
        uint256 lowestPrice;
        address lowestPriceAddress;

        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            address a = registeredAddresses[i];

            // The message sender cannot buy from himself
            if (a != exceptionAddress) {
                // There are any keys on sale
                if (addressToGameIDToKeysForSale[a][gameID] > 0) {
                    uint256 price = addressToGameIDToPrice[a][gameID];

                    // If the price is lower
                    if (lowestPrice < price) {
                        lowestPrice = price;
                        lowestPriceAddress = a;
                    }
                }
            }
        }

        return lowestPriceAddress;
    }

    // Returns the price of a key from a player's library
    function getOldGameKeyPrice(address walletAddress, uint256 keyID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToPrice[walletAddress][keyID];
    }

    // Returns the amount of keys an account owns
    function getKeysForAddress(address a, uint256 gameID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToKeysInLibrary[a][gameID];
    }

    // Returns the amount of keys an account has listed for sale
    function getKeysForAddressForSale(address a, uint256 gameID)
        public
        view
        returns (uint256)
    {
        return addressToGameIDToKeysForSale[a][gameID];
    }

    // Returns a list with the IDs of the games a wallet owns
    function getLibrary(address walletAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory walletLibrary = new uint256[](games.length);
        uint256 j;

        // Go through games list and check if the address has any copies of the game
        for (uint256 i = 0; i < games.length; i++) {
            if (addressToGameIDToKeysInLibrary[walletAddress][i] > 0) {
                walletLibrary[j++] = i;
            }
        }

        // Create an array that will be more compact than 'walletLibrary'
        uint256[] memory returnedLibrary = new uint256[](j);

        // Append all the elements from the big array to the smaller one
        for (uint256 i = 0; i < j; i++) {
            returnedLibrary[i] = walletLibrary[i];
        }

        return returnedLibrary;
    }

    // Returns the HASH Token Balance of a specific wallet
    function getAddressBalance(address a) public view returns (uint256) {
        return token.balanceOf(a);
    }

    // Returns the price of an original key for a game
    function getOriginalGamePrice(uint256 gameID)
        public
        view
        returns (uint256)
    {
        return games[gameID].price;
    }

    // Returns the link to the download of a game [OPTIONAL -> msg.sender must own the game]
    function getGameDownloadLink(uint256 gameID)
        public
        view
        returns (string memory)
    {
        // The msg.sender must own the game to request the link to its download
        /*
        require(
            addressToGameIDToKeysInLibrary[msg.sender][gameID] > 0,
            "The account request the link to this game's download does not own it"
        );*/

        return games[gameID].downloadLink;
    }

    // Test Functions -------------------------------------------------------------------

    // Sends Hash Tokens for free (FOR TESTING PURPOSES)
    function acquireHashTokens(uint256 hashTokens) public {
        token.transfer(msg.sender, hashTokens);
    }
}
