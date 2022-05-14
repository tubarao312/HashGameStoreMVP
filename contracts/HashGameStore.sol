// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

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

    uint256 REVENUE_SHARE = 5; // (5/100) - Percentage that Hash Game Store takes from developers
    uint256 TRADING_COOLDOWN = 5;

    // Run when contract is deployed
    constructor() public {
        minter = msg.sender;
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

    function buyOriginalKey(string memory gameTitle) public payable {
        Player memory player = addressToPlayer[msg.sender];
        Game memory game = titleToGame[gameTitle];
        Developer memory developer = game.developer;

        // Check price
        require(msg.value == game.basePrice);

        // Send (100 - REVENUE_SHARE)% to developer, REVENUE_SHARE% to hash game store
        developer.walletAddress.transfer(
            (msg.value * (100 - REVENUE_SHARE)) / 100
        );
        minter.transfer((msg.value * (REVENUE_SHARE)) / 100);

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

    function listKeyForSale(uint256 keyID, uint256 price) public {
        Player memory player = addressToPlayer[msg.sender];
        GameKey memory key = addressToGameLibrary[player.walletAddress][keyID];

        // Cooldown needs to be over
        require(key.cooldown < now);

        // Adds to marketplace and removes from library
        removeKeyFromPlayerLibrary(key);
        addressToGamesForSale[player.walletAddress].push(key);
        key.id = addressToGamesForSale[player.walletAddress].length;

        // Sets price
        key.price = price;
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

    function buyOldKey(string calldata sellerUsername, uint256 keyID)
        public
        payable
    {
        Player memory buyer = addressToPlayer[msg.sender]; // The player buying the key
        Player memory seller = usernameToPlayer[sellerUsername]; // The player selling the key
        GameKey memory key = addressToGamesForSale[seller.walletAddress][keyID]; // The key being transfered

        // Make sure key is for sale and value transfered is enough
        require(now >= key.cooldown);
        require(msg.value == key.price);

        // Transfer ETH
        seller.walletAddress.transfer(msg.value);

        // Transfer Ownership
        removeKeyFromPlayerLibrary(key);
        addKeyToPlayerLibrary(key, buyer);

        // Reset trade cooldown
        key.cooldown = now + 5 minutes;
    }
}
