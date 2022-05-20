from brownie import HashGameStore, HashToken
from scripts.helpful_scripts import get_account, get_account_player, get_account_developer


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


def fundPlayer(amount):  # Gives the player tokens
    hashGameStore = HashGameStore[-1]
    account = get_account_player()

    hashGameStore.givePlayerTokens(amount, {"from": account})


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

    # Print ERC20 Token Contract Address
    print("Token contract address: " + str(getTokenAddress()))
    print("-----------------------------------------------------------")

    # Fund Player
    fundPlayer("Pedro", 5000000000000000000)
    print("Gave the player Pedro 50 HASH")
    print("-----------------------------------------------------------")

    # Register Games
    gameRegister("Idle Paladin", 500000000000000000)
    print("Registered Game 'Idle Paladin' with base price of 500000000000000000 HASH")
    print("-----------------------------------------------------------")
    gameRegister("Red Dead Redemption II", 500000000000000000)
    print("Registered Game 'Red Dead Redemption II' with base price of 500000000000000000 HASH")
    print("-----------------------------------------------------------")
    gameRegister("FIFA 22", 500000000000000000)
    print("Registered Game 'FIFA 22' with base price of 500000000000000000 HASH")
    print("-----------------------------------------------------------")
    gameRegister("Cyberpunk 2077", 500000000000000000)
    print("Registered Game 'Cyberpunk 2077' with base price of 500000000000000000 HASH")
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
