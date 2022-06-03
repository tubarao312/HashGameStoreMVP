from brownie import HashGameStore, HashToken
from scripts.helpful_scripts import get_account, get_account_player, get_account_developer, get_account_player_2


def gameRegister(price, amount, link):  # Registers a game on the developer's behalf
    hashGameStore = HashGameStore[-1]
    account = get_account_developer()

    hashGameStore.gameRegister(price, amount, link, {"from": account})


def buyOriginalKey(account, id):  # Buys a key of a game with the player's account
    hashGameStore = HashGameStore[-1]
    price = hashGameStore.getOriginalGamePrice(id, {"from": account})

    approve((price), account)

    hashGameStore.buyOriginalKey(id, {"from": account})


def listKeyForSale(account, id, quantity, price):  # Lists a game key for sale
    hashGameStore = HashGameStore[-1]

    hashGameStore.setKeysForSale(id, quantity, price, {"from": account})


def buyResoldKey(account, id, quantity):  # Buys a second-hand key of the game
    hashGameStore = HashGameStore[-1]
    lowestPrice = hashGameStore.getLowestKeyPrice(id, account)

    approve(lowestPrice * quantity, account)

    hashGameStore.buyLowestPriceKey(id, quantity, {"from": account})


def getGamePrice(id):  # Returns the price of a game
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getOriginalGamePrice(id)


def fundAccount(account, amount):  # Gives the player tokens
    hashGameStore = HashGameStore[-1]

    hashGameStore.acquireHashTokens(amount, {"from": account})


def getTokenAddress():  # Gets the address of the token contract
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getTokenAddress()


def approve(amount, account):  # Approves the HGS Contract to spend Hash Tokens on the player's behalf
    hashGameStore = HashGameStore[-1]
    token = HashToken.at(getTokenAddress())

    token.approve(hashGameStore, amount, {"from": account})


def getAddressBalance(address):  # Gets the Hash Token Balance of a specific wallet
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getAddressBalance(address)


def getWalletKeys(gameID, address):
    hashGameStore = HashGameStore[-1]

    return hashGameStore.getKeysForAddress(address, gameID)


def main():

    # Print ERC20 Token Contract Address
    print("Token contract address: " + str(getTokenAddress()))
    print("-----------------------------------------------------------")

    # Fund Player
    account1 = get_account_player()
    account2 = get_account_player_2()

    fundAccount(account1, 1000000000000000000000)
    print("Gave the player Pedro 1000 HASH")
    print("-----------------------------------------------------------")
    fundAccount(account2, 500000000000000000000)
    print("Gave the player Leandro 500 HASH")
    print("-----------------------------------------------------------")

    # Register Games

    # IPFS Link to download Idle Paladin - Used for all games for testing purposes
    ipLink = 'https://bafybeihhpjgk6lo42qppiwjgtztvcr3clcpizgqckrvg4rlnsw6mtd6uc4.ipfs.dweb.link/Idle%20Paladin.exe'

    idlePaladinID = gameRegister(19990000000000000000, 0, ipLink)  # gameID = 0
    print("Registered Game 'Idle Paladin' for 19.99 HASH")
    print("-----------------------------------------------------------")
    rdrID = gameRegister(29990000000000000000, 0, ipLink)  # gameID = 1
    print("Registered Game 'Red Dead Redemption II' for 29.99 HASH")
    print("-----------------------------------------------------------")
    fifaID = gameRegister(34990000000000000000, 0, ipLink)  # gameID = 2
    print("Registered Game 'FIFA 22' for 34.99 HASH")
    print("-----------------------------------------------------------")
    cpID = gameRegister(59990000000000000000, 0, ipLink)  # gameID = 3
    print("Registered Game 'Cyberpunk 2077' for 59.99 HASH")
    print("-----------------------------------------------------------")

    # Know accounts' tokens
    print("Pedro's balance is: " + str(getAddressBalance(account1)))
    print("Leandro's balance is: " + str(getAddressBalance(account2)))
    print("Developers's balance is: " +
          str(getAddressBalance(get_account_developer())))
    print("Hash Game Stores's balance is: " +
          str(getAddressBalance(HashGameStore[-1])))
    print("-----------------------------------------------------------")

    # Player buys games
    buyOriginalKey(account1, 0)
    print("Pedro buys Idle Paladin")

    print("Idle Paladin download link is the following:")
    print(
        HashGameStore[-1].getGameDownloadLink(idlePaladinID, {"from": account1}))

    # Player 1 lists games for reselling
    listKeyForSale(account1, 0, 1, 2500000000000000000)
    print("Pedro lists Idle Paladin key for sale")
    print("-----------------------------------------------------------")

    # Player 2 buys game from Player 1
    buyResoldKey(account2, 0, 1)
    print("Leandro buys a copy of Idle Paladin from Pedro")
    print("-----------------------------------------------------------")

    # Player 2 lists games for reselling
    listKeyForSale(account2, 0, 1, 2500000000000000000)
    print("Leandro lists Idle Paladin key for sale")
    print("-----------------------------------------------------------")

    # Know accounts' tokens
    print("Pedro's balance is: " + str(getAddressBalance(account1)))
    print("Leandro's balance is: " + str(getAddressBalance(account2)))
    print("Developers's balance is: " +
          str(getAddressBalance(get_account_developer())))
    print("Hash Game Stores's balance is: " +
          str(getAddressBalance(HashGameStore[-1])))
    print("-----------------------------------------------------------")
