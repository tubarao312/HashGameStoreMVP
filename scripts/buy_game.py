from brownie import HashGameStore, HashToken
from scripts.helpful_scripts import get_account, get_account_player, get_account_developer


def playerRegister(username):  # Registers a player
    hashGameStore = HashGameStore[-1]
    account = get_account_player()

    hashGameStore.playerRegister(username, {"from": account})


def developerRegister(username):  # Registers a developer
    hashGameStore = HashGameStore[-1]
    account = get_account_developer()

    hashGameStore.developerRegister(username, {"from": account})


def gameRegister(title, price):  # Registers a game on the developer's behalf
    hashGameStore = HashGameStore[-1]
    account = get_account_developer()

    hashGameStore.gameRegister(title, price, {"from": account})


def buyOriginalKey(title):  # Buys a key of a game with the player's account
    hashGameStore = HashGameStore[-1]
    account = get_account_player()

    approve(getGamePrice(title))

    hashGameStore.buyOriginalKey(title, {"from": account})


def getGamePrice(title):  # Returns the price of a game
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getGamePrice(title)


def getPlayerGameList(username):  # Gets the list of titles in a player's library
    hashGameStore = HashGameStore[-1]
    account = get_account()

    gameIDArray = hashGameStore.getPlayerLibrary(username)
    gameIDCount = {}

    for i in gameIDArray:  # Run through the list of keys and count them
        if i not in gameIDCount:
            gameIDCount[i] = 1
        else:
            gameIDCount[i] += 1

    finalString = ""  # String that will get returned

    for i in gameIDCount:
        gameString = hashGameStore.getGameTitle(i)

        if gameIDCount[i] > 1:
            gameString += "(" + str(gameIDCount[i]) + ")"

        gameString += ", "
        finalString += gameString

    return finalString


def getETHPrice():  # Returns the ETH -> USD value
    hashGameStore = HashGameStore[-1]
    account = get_account()

    return hashGameStore.getLatestETHPrice()


def fundPlayer(username, amount):  # Gives the player tokens
    hashGameStore = HashGameStore[-1]

    hashGameStore.givePlayerTokens(username, amount)


def getTokenAddress():  # Gets the address of the token contract
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getToken()


def approve(amount):  # Approves the HGS Contract to spend Hash Tokens on the player's behalf
    hashGameStore = HashGameStore[-1]
    account = get_account_player()
    token = HashToken.at(getTokenAddress())

    token.approve(hashGameStore, amount, {"from": account})


def getAddressBalance(address):  # Gets the Hash Token Balance of a specific wallet
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getAddressBalance(address)


def main():

    # print("ETH PRICE IS " + str(getETHPrice()))

    # Print ERC20 Token Contract Address
    print("Token contract address: " + str(getTokenAddress()))
    print("-----------------------------------------------------------")

    # Register Entities
    playerRegister("Pedro")
    print("Registered Player 'Pedro'")
    print("-----------------------------------------------------------")
    developerRegister("PP")
    print("Registered Developer 'PP'")
    print("-----------------------------------------------------------")

    approve(20)

    # Fund Player
    fundPlayer("Pedro", 50)
    print("Gave the player Pedro 50 HASH")
    print("-----------------------------------------------------------")

    # Know player's tokens
    print("Pedro's balance is: " + str(getAddressBalance(get_account_player())))
    print("Hash Game Stores's balance is: " +
          str(getAddressBalance(HashGameStore[-1])))
    print("-----------------------------------------------------------")

    # Register Games
    gameRegister("Idle Paladin", 5)
    print("Registered Game 'Idle Paladin' with base price of 5 HASH")
    print("-----------------------------------------------------------")
    gameRegister("Death Stranding", 10)
    print("Registered Game 'Death Stranding' with base price of 10 HASH")
    print("-----------------------------------------------------------")

    # Buy Games
    buyOriginalKey("Idle Paladin")
    print("Player Pedro bought Idle Paladin game key for 5 HASH")
    print("-----------------------------------------------------------")
    buyOriginalKey("Idle Paladin")
    print("Player Pedro bought Idle Paladin game key for 5 HASH")
    print("-----------------------------------------------------------")
    buyOriginalKey("Death Stranding")
    print("Player Pedro bought Death Stranding game key for 10 HASH")
    print("-----------------------------------------------------------")

    # Know player's tokens
    print("Pedro's balance is: " + str(getAddressBalance(get_account_player())))
    print("Developers's balance is: " +
          str(getAddressBalance(get_account_developer())))
    print("Hash Game Stores's balance is: " +
          str(getAddressBalance(HashGameStore[-1])))
    print("-----------------------------------------------------------")

    # Print Library
    print("Pedro's library is: " + str(getPlayerGameList("Pedro")))
    print("-----------------------------------------------------------")
