// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20AuthorizedClient} from "../contracts/ERC20AuthorizedClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// This contract should only be uploaded to testnet (e.g. Sepolia)
contract CustomClient is ERC20("CustomClient", "CUST"), ERC20AuthorizedClient
{
    // TODO: change the value once ERC20Authorizer official contract is deployed in Sepolia
    address private constant _authorizationServerAddr = address(0);
    constructor() ERC20AuthorizedClient(_authorizationServerAddr) {}

    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20AuthorizedClient)
    {
        return super._update(from, to, value);
    }

    /// A dummy function for users to get free tokens for debug in Sepolia
    function buyTokens(uint256 amount) public
    {
        _mint(msg.sender, amount * 10 ** decimals());
    }
}