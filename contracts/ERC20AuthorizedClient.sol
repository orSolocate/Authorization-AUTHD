// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
abstract contract ERC20AuthorizedClient is IERC20Authorized, ERC20
{
    // Would be changed once ERC20Authorizer official deploy is uploaded in Sepolia
    address immutable private authorizationServerAddr;

    constructor (address _authorizationServerAddr)
    {
        authorizationServerAddr = _authorizationServerAddr;
    }

    /// client authorize docstring
    function authorize(address authorizer, uint256 cap) public
    {
        IERC20Authorized(authorizationServerAddr).authorize(authorizer, cap);
    }

}
