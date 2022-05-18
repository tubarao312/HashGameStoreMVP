// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./HashToken.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract HashGameStore {
    // Structs
    struct Developer {
        string username;
        address payable walletAddress;
    }

    struct Game {
        string title;
        uint256 basePrice;
        Developer developer;
        uint256 id;
    }

    struct GameKey {
        Game game;
        Player owner;
        uint256 price;
        uint256 cooldown;
        uint256 id;
    }

    struct Player {
        string username; // The player's username
        address payable walletAddress; // The player's wallet address
        //GameKey[] gameLibrary; // Games the player has in their library
        //GameKey[] gamesForSale; // Games the player has listed for sale
    }

    // Global Variables
    Player[] private players;
    Developer[] private developers;
    Game[] private games;
    mapping(string => Game) private titleToGame;
    mapping(string => Player) private usernameToPlayer;
    mapping(address => Player) private addressToPlayer;
    mapping(address => Developer) private addressToDeveloper;
    mapping(address => GameKey[]) private addressToGameLibrary;
    mapping(address => GameKey[]) private addressToGamesForSale;
    mapping(string => uint256) public gameTitleToPrice;

    address payable minter;

    uint256 REVENUE_SHARE = 1; // (1/100) - Percentage that Hash Game Store takes from developers
    uint256 TRADING_COOLDOWN = 5;

    HashToken public token;
    AggregatorV3Interface internal priceFeed;

    // Run when contract is deployed
    constructor() public {
        minter = msg.sender;
        token = new HashToken(500);
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    function getLatestETHPrice() public view returns (int256) {
        (uint80 a, int256 price, uint256 b, uint256 c, uint80 d) = priceFeed
            .latestRoundData();

        return price;
    }

    // Functions
    function playerRegister(string calldata username) public {
        Player memory newPlayer = Player({
            username: username,
            walletAddress: msg.sender
            //gameLibrary: gameLibrary,
            //gamesForSale: gamesForSale
        });

        players.push(newPlayer);
        usernameToPlayer[username] = newPlayer;
        addressToPlayer[msg.sender] = newPlayer;
    }

    function getAddressBalance(address a) public view returns (uint256) {
        return token.balanceOf(a);
    }

    function givePlayerTokens(string calldata username, uint256 amount) public {
        Player memory player = usernameToPlayer[username];

        token.transfer(player.walletAddress, amount);
    }

    function developerRegister(string calldata username) public {
        Developer memory newDeveloper = Developer({
            username: username,
            walletAddress: msg.sender
        });

        developers.push(newDeveloper);
        addressToDeveloper[msg.sender] = newDeveloper;
    }

    function gameRegister(string calldata title, uint256 price) public {
        Developer memory developer = addressToDeveloper[msg.sender];

        Game memory newGame = Game({
            title: title,
            developer: developer,
            basePrice: price,
            id: games.length
        });

        titleToGame[title] = newGame;
        gameTitleToPrice[title] = price;
        games.push(newGame);
    }

    function generateNewKey(Game memory game) private returns (GameKey memory) {
        // Generates a new key
        GameKey memory newKey;
        newKey.game = game;

        return newKey;
    }

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

    function addKeyToPlayerLibrary(GameKey memory key, Player memory player)
        private
    {
        // Adds key to player's library
        addressToGameLibrary[player.walletAddress].push(key);
        key.id = addressToGameLibrary[player.walletAddress].length;
    }

    function removeKeyFromPlayerLibrary(GameKey memory key) private {
        // Removes key from player's library
        removeKeyFromArray(
            addressToGamesForSale[key.owner.walletAddress],
            key.id
        );
    }

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

    function getGamePrice(string calldata title) public view returns (uint256) {
        return titleToGame[title].basePrice;
    }

    function getGameTitle(uint256 id) public view returns (string memory) {
        return games[id].title;
    }

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

    function getToken() public view returns (HashToken) {
        return token;
    }
}
