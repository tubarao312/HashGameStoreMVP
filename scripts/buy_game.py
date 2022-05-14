from brownie import HashGameStore
from scripts.helpful_scripts import get_account


def playerRegister(username):
    hashGameStore = HashGameStore[-1]
    account = get_account()

    hashGameStore.playerRegister(username, {"from": account})


def developerRegister(username):
    hashGameStore = HashGameStore[-1]
    account = get_account()

    hashGameStore.developerRegister(username, {"from": account})


def gameRegister(title, price):
    hashGameStore = HashGameStore[-1]
    account = get_account()

    hashGameStore.gameRegister(title, price, {"from": account})


def buyOriginalKey(title):
    hashGameStore = HashGameStore[-1]
    account = get_account()
    price = hashGameStore.gameTitleToPrice(title)

    hashGameStore.buyOriginalKey(title, {"from": account, "value": price})


def getPlayerGameList(username):
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


def main():

    # Register Entities
    playerRegister("Pedro")
    print("Registered Player 'Pedro'")
    developerRegister("PP")
    print("Registered Developer 'PP'")

    # Register Games
    gameRegister("Idle Paladin", 2500000000000000)
    print("Registered Game 'Idle Paladin' with base price of '0.0025' ETH")
    gameRegister("Death Stranding", 5000000000000000)
    print("Registered Game 'Death Stranding' with base price of '0.005' ETH")

    # Buy Games
    buyOriginalKey("Idle Paladin")
    print("Player Pedro bought Idle Paladin game key for '0.0025' ETH")
    buyOriginalKey("Idle Paladin")
    print("Player Pedro bought Idle Paladin game key for '0.0025' ETH")
    buyOriginalKey("Death Stranding")
    print("Player Pedro bought Death Stranding game key for '0.005' ETH")

    # Print Library
    print("Pedro's library is: " + str(getPlayerGameList("Pedro")))
