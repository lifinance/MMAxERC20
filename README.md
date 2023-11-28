# xERC20 <> Multi-Message Aggregation (MMA)
A demonstration model for an xERC20 token, as outlined by [ERC-7281](https://www.xerc20.com/), utilizing the Multiple Arbitrary Message Bridge framework built by [Uniswap Foundation](https://github.com/MultiMessageAggregation/multibridge) in partnership with LI.FI.

## Introduction
xERC20 addresses the challenges of fragmented liquidity across various blockchains and the risks associated with relying on a single Arbitrary Message Bridge (AMB). However, it faces limitations related to the minting and burning caps. To overcome these drawbacks, this model employs a combination of message bridges without any constraints, effectively resolving these issues on a broader level.

![Diagram](https://github.com/lifinance/MMAxERC20/blob/develop/img/Flowchart.jpg)

## Local Development

**Step 1:** Clone the repository

```sh
$   git clone https://github.com/lifinance/MMAxERC20
```

**note:** Please make sure [foundry](https://github.com/foundry-rs/foundry) is installed to proceed further.

**Step 2:** Install required forge submodules

```sh
$  forge install
```

**Step 3:** Compile

```sh
$  forge build
```

**Step 4:** Run Tests

To run the tests, you will need a local fork of Ethereum, Polygon, and BSC mainnet states. To accomplish this, you must specify RPC endpoints for each of these networks. You can obtain RPC endpoints to use for Ethereum and Polygon, from Alchemy, Infura, or other infrastructure providers. For BSC, you can choose from a list of public RPC endpoints available [here](https://docs.bscscan.com/misc-tools-and-utilities/public-rpc-nodes).

To set the RPC endpoints, make a copy of the `.env.sample` file and name it `.env`. The file contains a list of parameter names (e.g. `ETH_FORK_URL`) that correspond to each network. Set the respective values of each of these parameters to the RPC endpoints you wish to use.

Once you have set these values, you can run both the unit and integration tests using the following command:

```sh 

```sh
$  forge test
```

**note:** We use [pigeon](https://github.com/exp-table/pigeon/tree/docs) to simulate the cross-chain behavior on forked mainnets.

## How to contribute ?
#### Reporting bugs and issues
If you find any bugs or issues with the project, please create a GitHub issue and include as much detail as possible. 

#### Code contribution
If you want to contribute code to the project, please follow these guidelines:

1. Fork the project repository and clone it to your local machine.
1. Create a new branch for your changes.
1. Make your changes and test them thoroughly.
1. Ensure that your changes are well-documented.
1. Create a pull request and explain your changes in detail.
1. Code review
1. All code changes will be reviewed by the project maintainers. The maintainers may ask for additional changes, and once the changes have been approved, they will be merged into the main branch.

#### Testing
All code changes must be thoroughly tested. Please ensure that your tests cover all new functionality and edge cases.

## Contracts
```
contracts
├── MultiBridgeMessageReceiver.sol
├── MultiBridgeMessageSender.sol
├── adapters
│   ├── BaseSenderAdapter.sol
│   ├── axelar
│   │   ├── AxelarReceiverAdapter.sol
│   │   ├── AxelarSenderAdapter.sol
│   │   ├── interfaces
│   │   │   ├── IAxelarExecutable.sol
│   │   │   ├── IAxelarGasService.sol
│   │   │   └── IAxelarGateway.sol
│   │   └── libraries
│   │       └── StringAddressConversion.sol
│   └── wormhole
│       ├── WormholeReceiverAdapter.sol
│       └── WormholeSenderAdapter.sol
├── controllers
│   ├── GAC.sol
│   └── GovernanceTimelock.sol
├── interfaces
│   ├── EIP5164
│   │   ├── ExecutorAware.sol
│   │   ├── MessageDispatcher.sol
│   │   ├── MessageExecutor.sol
│   │   └── SingleMessageDispatcher.sol
│   ├── IGAC.sol
│   ├── IGovernanceTimelock.sol
│   ├── IMessageReceiverAdapter.sol
│   ├── IMessageSenderAdapter.sol
│   └── IMultiBridgeMessageReceiver.sol
└── token
    ├── xERC20.sol
└── libraries
    ├── Error.sol
    ├── Message.sol
    ├── TypeCasts.sol
    └── Types.sol
```

## License
By contributing to the project, you agree that your contributions will be licensed under the project's [LICENSE](https://github.com/MultiMessageAggregation/multibridge/blob/main/LICENSE).