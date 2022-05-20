from brownie import HashGameStore, MockV3Aggregator, network, config
from scripts import buy_game
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


def deploy_hashGameStore():
    account = get_account()
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    hashGameStore = HashGameStore.deploy(
        {"from": account}, publish_source=True)
    #    print(HashGameStore.get_verification_info())
    #    price_feed_address,
    #    {"from": account},
    #    publish_source=config["networks"][network.show_active()].get("verify"),
    # )
    print(f"Contract deployed to {hashGameStore.address}")
    return hashGameStore


def main():
    deploy_hashGameStore()
