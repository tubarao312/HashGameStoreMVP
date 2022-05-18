// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./HashToken.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract HashGameStore {
    // Structs
    struct Developer {
        string username; // Name of the developer
        address walletAddress; // Wallet address of the developer
    }

    struct Game {
        string title; // Title of the game
        uint256 basePrice; // Base price of the game
        Developer developer; // Developer the game belongs to
        uint256 id; // ID of the game within all games
    }

    struct GameKey {
        Game game; // The game the key gives access to
        Player owner; // The player that owns the key
        uint256 price; // The price it is set to
        uint256 cooldown; // The date of when the key will be tradable again
        uint256 id; // The ID within the player's library
    }

    struct Player {
        string username; // The player's username
        address payable walletAddress; // The player's wallet address
    }

    // Global Variables
    Game[] private games; // List of all games on the platform
    mapping(string => Game) private titleToGame; // Maps game title to game struct
    mapping(string => Player) private usernameToPlayer; // Maps username to player struct
    mapping(address => Player) private addressToPlayer; // Maps wallet address to player struct
    mapping(address => Developer) private addressToDeveloper; // Maps wallet address to developer struct
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
        token = new HashToken(500); // Creates the token contract
        priceFeed = AggregatorV3Interface( // Price feed to get ETH -> USD conversion
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    // Functions ==========================================================================

    // Returns the ETH -> USD price conversion
    function getLatestETHPrice() public view returns (int256) {
        (uint80 a, int256 price, uint256 b, uint256 c, uint80 d) = priceFeed
            .latestRoundData();

        return price;
    }

    // Registers a player with the wallet as the msg.sender
    function playerRegister(string calldata username) public {
        Player memory newPlayer = Player({
            username: username,
            walletAddress: msg.sender
        });

        usernameToPlayer[username] = newPlayer;
        addressToPlayer[msg.sender] = newPlayer;
    }

    // Gets the HASH Token Balance of a specific wallet
    function getAddressBalance(address a) public view returns (uint256) {
        return token.balanceOf(a);
    }

    // Gives a player Hash tokens from the contract's wallet
    function givePlayerTokens(string calldata username, uint256 amount) public {
        Player memory player = usernameToPlayer[username];

        token.transfer(player.walletAddress, amount);
    }

    // Registers a developer with the wallet as the msg.sender
    function developerRegister(string calldata username) public {
        Developer memory newDeveloper = Developer({
            username: username,
            walletAddress: msg.sender
        });

        addressToDeveloper[msg.sender] = newDeveloper;
    }

    // Registers a game with the developer as the msg.sender's developer
    function gameRegister(string calldata title, uint256 price) public {
        Developer memory developer = addressToDeveloper[msg.sender];

        Game memory newGame = Game({
            title: title,
            developer: developer,
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
    function addKeyToPlayerLibrary(GameKey memory key, Player memory player)
        private
    {
        // Adds key to player's library
        addressToGameLibrary[player.walletAddress].push(key);
        key.id = addressToGameLibrary[player.walletAddress].length;
    }

    // Removes a key from a player's library
    function removeKeyFromPlayerLibrary(GameKey memory key) private {
        // Removes key from player's library
        removeKeyFromArray(
            addressToGamesForSale[key.owner.walletAddress],
            key.id
        );
    }

    // Buys and generates a new key from a developer as a player
    function buyOriginalKey(string memory gameTitle) public {
        Player memory player = addressToPlayer[msg.sender];
        Game memory game = titleToGame[gameTitle];
        Developer memory developer = game.developer;

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
        token.transferFrom(msg.sender, developer.walletAddress, devRevenue);

        // Transfer part to Hash
        uint256 hashRevenue = (game.basePrice * (REVENUE_SHARE)) / 100;
        token.transferFrom(msg.sender, minter, hashRevenue);

        // Generates new key
        GameKey memory newKey = generateNewKey(game);

        // Adds key to player's library
        addKeyToPlayerLibrary(newKey, player);

        // Set Cooldown for Key
        newKey.cooldown = now + 5 minutes;
    }

    // Gets the price of a key from a player's sale library
    function getKeyPrice(string calldata sellerUsername, uint256 keyID)
        public
        view
        returns (uint256)
    {
        return
            addressToGamesForSale[
                usernameToPlayer[sellerUsername].walletAddress
            ][keyID].price;
    }

    // Gets the base price of a game
    function getGamePrice(string calldata title) public view returns (uint256) {
        return titleToGame[title].basePrice;
    }

    // Gets the game title of a game based on its ID
    function getGameTitle(uint256 id) public view returns (string memory) {
        return games[id].title;
    }

    // Gets an array with the IDs of all the games a player owns
    function getPlayerLibrary(string calldata username)
        public
        view
        returns (uint256[] memory)
    {
        // Returns an array with the IDs for all of the player's keys
        Player memory player = usernameToPlayer[username];
        GameKey[] memory gameLibrary = addressToGameLibrary[
            player.walletAddress
        ];
        uint256[] memory gameIDArray = new uint256[](gameLibrary.length);

        // Build Array
        for (uint256 i = 0; i < gameLibrary.length; i++) {
            gameIDArray[i] = gameLibrary[i].game.id;
        }

        return gameIDArray;
    }

    // Returns the contract address of the token
    function getToken() public view returns (HashToken) {
        return token;
    }
}
