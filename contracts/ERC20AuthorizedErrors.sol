// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ERC20AuthorizedErrors
{
    // Thrown when trying to authorize an address already authorized by owner in client, should call increase/decrease
    // instead
    error AlreadyAuthorized(address client, address owner, address authorized);

    // Thrown when trying to register a client address already registered in the server
    error AlreadyRegistered(address client);

    // Thrown when a non-registered client tries to interact with authorization features
    error ClientNotRegistered(address client);

    // Thrown when the trying to register on an exhausted client pool
    error ClientPoolExhuasted(uint256 clientPoolRemaining, uint256 registerationAuthdAmount);

    // Thrown when requested amount is invalid
    error InvalidAmount(uint256 amount);

    // Thrown when there is not enough AUTHD tokens in the server supply
    error InsufficientAuthdSupply(uint256 supply, uint256 registerationAuthdAmount);

    // Thrown when an authorized address (by owner in client) tries to approve on more than its cap
    error InsufficientAuthorizedCap(address client, address owner, address authroized, uint256 currentCap,
        uint256 amountRequested);

    // Thrown when a client tries to register and doesn't supply the minimal registration fee
    error InsufficientRegistrationFee(uint256 providedFee, uint256 registerationFee);

    // Thrown when trying to authorize on insufficient owner balance in client
    error InsufficientOwnerBalance(address client, address owner, uint256 capAmount);

    // Thrown when approveFor spender address is invalid
    error InvalidSpender(address spender);

    // Thrown when the authorized address in not currently authorized by owner in client
    error NotCurrentlyAuthorized(address client, address owner, address authorized);

    // Thrown on a request to self-authorize
    error SelfAuthorizationProhibited();
}
