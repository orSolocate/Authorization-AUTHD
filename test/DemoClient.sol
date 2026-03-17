// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC20AuthorizedClient} from "../contracts/ERC20AuthorizedClient.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DemoClient is ERC20("DemoClient", "DEMO"), ERC20AuthorizedClient
{
    constructor(address _authorizationServerAddr) ERC20AuthorizedClient(_authorizationServerAddr) {}

    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20AuthorizedClient)
    {
        return super._update(from, to, value);
    }
}
