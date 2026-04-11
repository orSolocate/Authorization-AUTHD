Authorization extension of ERC20 to enable authorized users to approve on owner's behalf on blockchain network

### Project Setup
- Solidity compiler version: 0.8.28.
- Framework: Hardhat3 - version 3.1.10.
- Dependencies:
  - @openzeppelin/contracts version 5.6.1:
    To install it:  npm install @openzeppelin/contracts@5.6.1
  - Typescript 5.8.0, node 22.19.13.
  - Forge-std assertion library 1.9.7.
  To install it follow the hardhat3 tutorial just modify the version to 1.9.7:
  https://hardhat.org/docs/tutorial/assertions-library

### Project Logic

The *contracts* folder:

#### Interfaces/IERC20Authorized.sol

This file contains an interface for the authorization server (`ERC20Authorized.sol`) which is based on IERC20: includes exposed server functionality and events. Note about security: only registered clients can use the authorization interface (except for ‘view’/read-only functions).

#### Lib/AddressArrayUtills.sol

Includes utility functions to add and remove elements from an array of solidity addresses.

#### Lib/LinearRate.sol

Includes a mathematical utility function.

#### ERC20Authorized.sol

The authorization server. Contains implementation of IERC20Authorized and ERC20AuthorizedErrors and based on ERC20 and Ownable. Includes storage states and implementation of server functionalities (the light green areas on the first page of the whitepaper).

#### ERC20AuthorizedClient.sol

The authorization client. Contains abstract implementation of a client (the pink square in the whitepaper first page), to be adapted by an ERC20 based contract that would be a specific client. Acts as a proxy to send requests and receive information from the authorization server and modifies the client's storage states accordingly. Note about security: We avoid reentrancy in the client by calling all state changes before calling the client in all public functions. Only registered clients can call the server, and so users will only use client interface to use authorization features. The logic is per the whitepaper requirements, but extensive details will follow in the project's final report.

#### ERC20AuthorizedErrors.sol

Contains a contract that includes errors associated with the authorization server with explanation for each error.

#### CustomClient.sol

A realization of a client based on a real ERC20 token, with the required functionality to buy tokens and perform authorization scenarios for demo purposes.

To compile the source code: `npx hardhat build`

### Security considerations
1. All client public functions use the best practice to avoid reentrancy (when calling the server) by modifying all internal states before an external call to the server is made.
2. Any real client that would adapt/inherit the client code would use the hardcoded address of the authorization server (it is part of the documentation of our dApp, like other service protocols e.g. ChainLink).  This prevents a malicious server pretending to be the authorization server and gives the client false information.
3. The server restricts all its non-view public functionality to registered clients only. This prevents any malicious actor from calling server interface function and modifying its storage state.
4. We also reserved some admin functionalities that enhance security like revoking a registered client, in cases that a suspicious client activity is observed and the authorization server wants to prevent it. The last feature was not part of the original proposal, but we decided to add it because it introduces more security into our dApp.

### Tests
The *test* folder:

#### ERC20Authorized.t.sol

Unit-test for the authorization server. Tests the server interface, events and errors calling the server functions directly by another contract who acts like a client. To keep this README short, we will provide details on each tests case in the final report.

#### DemoClient.sol

A realization of a client implementing ERC20AuthorizedClient to be used in client unit-tests.

#### ERC20AuthorizedClient.t.sol

Unit-test for the authorized client. Tests the client interface with the client, including the approve logic in the client, authorization related events and errors calling authorization function from the client. To keep this README short, we will provide details on each tests case in the final report.

To run all tests: `npx hardhat test`
