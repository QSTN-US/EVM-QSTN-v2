# QSTN + EVM Networks - work in progress

<p align="center">
  <a href="https://qstn.us/"><img src="https://qstn.us/icon-256x256.png" alt="QSTN Marketplace"></a>
</p>

**_🚀 QSTN is a platform that connects businesses and individuals through market research surveys. We partner with companies that are looking for feedback from consumers like you, and we provide the opportunity for you to earn rewards while sharing your opinions._**

**QSTN Survey Smart Contracts Documentation**

Welcome to the QSTN Survey Smart Contracts repository. This guide will help you understand how to deploy and use our smart contracts for business funding on the Solana blockchain.

Table of Contents
Introduction
Prerequisites
Installation
Contract Overview
Deploying the Contracts
Using the Contracts
Examples
Contributing
Support
License

**Introduction**

QSTN provides a decentralized solution for businesses to fund surveys using smart contracts on the EVM blockchains. This guide explains how to set up, deploy, and interact with the QSTN survey smart contracts.

**Prerequisites**

To run, test, or deploy this smart contract, make sure you have everything necessary to run the project. You can find all the necessary instructions for setting up the Hardhat environment [here](https://hardhat.org/hardhat-runner/docs/getting-started).

**Installation**

Clone the repository and navigate to the contracts directory:

```bash
git clone https://github.com/QSTN-US/EVM-QSTN-v2
cd EVM-QSTN-v2
yarn
npx hardhat test
```

**Contract Overview**

This repository contains smart contract designed for creating and funding surveys. Key components include:

Quizzler.sol: Smart contract for creating and managing surveys with rewards in Native tokens.
QuizzlerNFT.sol: Smart contract for creating and managing surveys with rewards in NFT tokens.

The Quizzler.sol smart contract allows users to create surveys, fund them, and manage survey data. Key functions include:

```solidity
function createSurvey(
        bytes memory _signature,
        bytes32 _token,
        uint256 _timeToExpire,
        address _owner,
        string memory _surveyId,
        uint256 _participantsLimit,
        uint256 _rewardAmount,
        bytes32 _surveyHash,
        uint256 _amountToGasStation
    ) external payable nonReentrant {}
```

The `createSurvey` function is used to initialize a new object responsible for a specific survey. This function receives key data about the survey and reward configurations. Additionally, as a security measure, the function should receive a signature signed by the backend. At this stage, the contract is also funded with the native currency, which will later be used as a reward.

```solidity
function payRewards(
        bytes memory _signature,
        bytes32 _token,
        uint256 _timeToExpire,
        string[] memory _surveyIds,
        address[] memory _participantsEncoded
    ) external nonReentrant {}
```

The `payRewards` function is used to initiate reward payments to users for completed surveys. This function can only be called by an account that has manager status in the system; at this stage, only the backend can act as such an account.

**Deploying the Contracts**

Follow these steps to deploy the contracts on the EVM blockchain:

% npx hardhat run scripts/quizzler.deploy.js --network _YOUR_NETWORK_

**Contributing**

We welcome contributions! Please read our contributing guide to get started.

**Support**

If you encounter any issues or have questions, please open an issue on GitHub or contact our support team at support@qstn.us.

**License**

This project is licensed under the MIT License. See the LICENSE file for details.

```

```
