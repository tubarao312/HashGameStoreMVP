// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./HashToken.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract HashGameStore {
    struct Game {
        string title; // Title of the game
        uint256 basePrice; // Base price of the game
        address developerAddress; // Developer the game belongs to
        uint256 id; // ID of the game within all games
    }

    struct GameKey {
        Game game; // The game the key gives access to
        uint256 price; // The price it is set to
        uint256 cooldown; // The date of when the key will be tradable again
        uint256 id; // The ID within the player's library
    }

    // Global Variables
    Game[] private games; // List of all games on the platform
    mapping(string => Game) private titleToGame; // Maps game title to game struct
    mapping(address => GameKey[]) private addressToGameLibrary; // Maps wallet address to game library
    mapping(address => GameKey[]) private addressToGamesForSale; // Maps wallet address to games for sale

    // The address of our company's wallet
    address payable minter;

    // Constants
    uint256 REVENUE_SHARE = 1; // (1/100) - Percentage that Hash Game Store takes from developers
    uint256 TRADING_COOLDOWN = 5; // Cooldown for game trading

    HashToken public token;
    AggregatorV3Interface internal priceFeed;

    // Run when contract is deployed
    constructor() public {
        minter = msg.sender; // Sets the minter as us so we can retrieve the Tokens
        token = new HashToken(50000000000000000000); // Creates the token contract
        priceFeed = AggregatorV3Interface( // Price feed to get ETH -> USD conversion
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    // Functions ==========================================================================

    // Returns the ETH -> USD price conversion
    function getLatestETHPrice() private view returns (int256) {
        (uint80 a, int256 ethPrice, uint256 b, uint256 c, uint80 d) = priceFeed
            .latestRoundData();

        return ethPrice;
    }

    // Gets the HASH Token Balance of a specific wallet
    function getAddressBalance(address a) public view returns (uint256) {
        return token.balanceOf(a);
    }

    // Gives a player Hash tokens from the contract's wallet
    function giveTokens(address walletAddress, uint256 amount) public {
        token.transfer(walletAddress, amount);
    }

    // Registers a game with the developer as the msg.sender's developer
    function gameRegister(string calldata title, uint256 price) public {
        Game memory newGame = Game({
            title: title,
            developerAddress: msg.sender,
            basePrice: price,
            id: games.length
        });

        titleToGame[title] = newGame;

        games.push(newGame);
    }

    // Generates a new key
    function generateNewKey(Game memory game) private returns (GameKey memory) {
        // Generates a new key
        GameKey memory newKey;
        newKey.game = game;

        return newKey;
    }

    // Removes a key from an array of keys
    function removeKeyFromArray(GameKey[] storage array, uint256 index)
        private
    {
        if (index >= array.length) return;

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
            array[i].id = i + 1;
        }
        delete array[array.length - 1];
    }

    // Adds a key to a player's library
    function addKeyToWallet(GameKey memory key, address walletAddress) private {
        addressToGameLibrary[walletAddress].push(key);
        key.id = addressToGameLibrary[walletAddress].length;
    }

    // Buys and generates a new key from a developer as a player
    function buyOriginalKey(string memory gameTitle) public {
        Game memory game = titleToGame[gameTitle];

        // Player must have the necessary balance
        require(
            token.balanceOf(msg.sender) >= game.basePrice,
            "The caller didn't have enough Hash tokens"
        );

        // Give the contract permission to transfer $HASH
        require(
            token.allowance(msg.sender, address(this)) >= game.basePrice,
            "The caller didn't allow the platform to spend enough Hash tokens on their behalf"
        );

        // Transfer part to Developer
        uint256 devRevenue = (game.basePrice * (100 - REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, game.developerAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = (game.basePrice * (REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Generates new key
        GameKey memory newKey = generateNewKey(game);

        // Adds key to player's library
        addKeyToWallet(newKey, msg.sender);

        // Set Cooldown for Key
        newKey.cooldown = now + 5 minutes;
    }

    // Gets the base price of a game
    function getGamePrice(string calldata title) public view returns (uint256) {
        return titleToGame[title].basePrice;
    }

    // Gets the game title of a game based on its ID
    function getGameTitle(uint256 id) public view returns (string memory) {
        return games[id].title;
    }

    // Returns the contract address of the token
    function getToken() public view returns (HashToken) {
        return token;
    }
}
