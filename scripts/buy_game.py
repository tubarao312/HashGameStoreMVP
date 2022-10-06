from brownie import HashGameStore, HashToken
from scripts.helpful_scripts import get_account, get_account_player, get_account_developer, get_account_player_2

""" Test Order:

##### CONTRACT INTERACTION ############################################################
- Register two games on the marketplace: Idle Paladin (1) and Cyberpunk 2077 (2)
- Developer 1 registers Idle Paladin (1) and Cyberpunk 2077 (2) on the marketplace
- Player 1 buys Idle Paladin (1) for 1000 tokens
- Player 1 lists Idle Paladin for sale for 900 tokens
- Player 2 buys Idle Paladin from Player 1 for 900 tokens
- Developer 1 withdraws profit from the marketplace

"""

def main():
    # Get accounts
    account = get_account()
    account_player = get_account_player()
    account_developer = get_account_developer()
    account_player_2 = get_account_player_2()

    # Get contracts
    hash_game_store = HashGameStore[-1]
    hash_token = HashToken[-1]

    # Register two games on the marketplace: Idle Paladin (1) and Cyberpunk 2077 (2)
    hash_game_store.registerGame("Idle Paladin", "Idle Paladin is a game about a paladin who idles.", {"from": account_developer})
    hash_game_store.registerGame("Cyberpunk 2077", "Cyberpunk 2077 is a game about a cyberpunk.", {"from": account_developer})

    # Developer 1 registers Idle Paladin (1) and Cyberpunk 2077 (2) on the marketplace
    hash_game_store.registerGameOnMarketplace(1, {"from": account_developer})
    hash_game_store.registerGameOnMarketplace(2, {"from": account_developer})

    # Player 1 buys Idle Paladin (1) for 1000 tokens
    hash_token.approve(hash_game_store.address, 1000, {"from": account_player})
    hash_game_store.buyGame(1, {"from": account_player})

    # Player 1 lists Idle Paladin for sale for 900 tokens
    hash_game_store.listGameForSale(1, 900, {"from": account_player})

    # Player 2 buys Idle Paladin from Player 1 for 900 tokens
    hash_token.approve(hash_game_store.address, 900, {"from": account_player_2})
    hash_game_store.buyGameFromPlayer(1, {"from": account_player_2})

    # Developer 1 withdraws profit from the marketplace
    hash_game_store.withdrawProfit({"from": account_developer})

    # Player 1 lists Idle Paladin for sale for 900 tokens
    hash_game_store.listGameForSale(1, 900, {"from": account_player})

    # Player 2 buys Idle Paladin from Player 1 for 900 tokens
    hash_token.approve(hash_game_store.address, 900, {"from": account_player_2})
    hash_game_store.buyGameFromPlayer(1, {"from": account_player_2})

    # Developer 1 withdraws profit from the marketplace
    hash_game_store.withdrawProfit