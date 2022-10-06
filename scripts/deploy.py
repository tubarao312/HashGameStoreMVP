from brownie import KeyMarketplace, Beacon, Proxy, Game, network, config
import json, os
from scripts.helpful_scripts import (
    get_account,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)

# Whether to verify the contracts on Etherscan
PUBLISH_CODE = False

# JSON Functions ########################################################

def get_json():
    path = os.path.dirname(os.path.abspath(__file__)) + "\\contractInfo.json"

    with open(path, "r") as file:
        addresses = json.load(file)

    return addresses

def update_json(dictionary):
    path = os.path.dirname(os.path.abspath(__file__)) + "\\contractInfo.json"

    with open(path, "w") as file:
        json.dump(dictionary, file)

# Deploying Contracts ##################################################

def deploy_marketplace_code():
    """ Deploys latest version of marketplace code. """

    account = get_account()

    marketplace = KeyMarketplace.deploy(
        {"from": account}, publish_source=PUBLISH_CODE)

    return marketplace

def deploy_game_code():
    """ Deploys latest version of game code. """

    account = get_account()

    game = Game.deploy(
        {"from": account}, publish_source=PUBLISH_CODE)

    return game

def deploy_proxy(address: str):
    """ Deploys a proxy contract. """

    account = get_account()

    proxy = Proxy.deploy(address,
        {"from": account}, publish_source=PUBLISH_CODE)

    return proxy

def deploy_beacon():
    """ Deploys a beacon contract. """

    account = get_account()

    beacon = Beacon.deploy(
        {"from": account}, publish_source=PUBLISH_CODE)

    return beacon

def init_deploy():
    """ Deploy all contracts for the first time. """

    # Deploy Beacons
    gameBeacon = deploy_beacon()
    marketplaceBeacon = deploy_beacon()

    # Deploy Code Contracts
    gameCode = deploy_game_code()
    marketplaceCode = deploy_marketplace_code()

    # Point Beacons to Code Contracts
    gameBeacon.upgrade(gameCode, {"from": get_account()})
    marketplaceBeacon.upgrade(marketplaceCode, {"from": get_account()})

    # Deploy Proxy Contracts
    marketplaceProxy = deploy_proxy(marketplaceBeacon.address)

    # Update JSON file
    contractAddresses = get_json()
    contractAddresses["gameBeacon"] = gameBeacon.address
    contractAddresses["gameCode"] = gameCode.address
    contractAddresses["marketplaceBeacon"] = marketplaceBeacon.address
    contractAddresses["marketplaceProxy"] = marketplaceProxy.address
    contractAddresses["marketplaceCode"] = marketplaceCode.address
    update_json(contractAddresses)

# Updating Contracts ##################################################

def update_marketplace_code():
    """ Updates marketplace code."""

    newMarketplace = deploy_marketplace_code()

    addresses = get_json()
    addresses["marketplaceCode"] = newMarketplace.address
    update_json(addresses)

    marketplaceBeacon = Beacon.at(addresses["marketplaceBeacon"])
    marketplaceBeacon.upgrade(newMarketplace, {"from": get_account()})
    print("Marketplace Code Updated!")

def update_game_code():
    """ Updates game code."""

    newGame = deploy_game_code()

    addresses = get_json()
    addresses["gameCode"] = newGame.address
    update_json(addresses)

    gameBeacon = Beacon.at(addresses["gameBeacon"])
    gameBeacon.upgrade(newGame, {"from": get_account()})
    print("Game Code Updated!")

# Main Function ########################################################

def main():
    init_deploy()

    update_marketplace_code()
    update_game_code()
