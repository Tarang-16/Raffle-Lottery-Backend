require("@nomicfoundation/hardhat-chai-matchers")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            blockConfirmations: 1,
        },
        goerli: {
            chainId: 5,
            blockConfirmations: 4,
            accounts: [PRIVATE_KEY],
            url: GOERLI_RPC_URL,
        },
    },

    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },

    etherscan: {
        // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            goerli: ETHERSCAN_API_KEY,
        },
    },

    solidity: "0.8.7",
    mocha: {
        timeout: 500000,
    },
}
