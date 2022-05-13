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
    print(price)
    hashGameStore.buyOriginalKey(title, {"from": account, "value": price})


def main():
    playerRegister("Pedro")
    print("Registered Player 'Pedro'")
    developerRegister("PP")
    print("Registered Developer 'PP'")
    gameRegister("Idle Paladin", 5000000000000000)
    print("Registered Game 'Idle Paladin' with base price of '0.005' ETH")
    buyOriginalKey("Idle Paladin")
    print("Player Pedro bought Idle Paladin game key for '0.005' ETH")
