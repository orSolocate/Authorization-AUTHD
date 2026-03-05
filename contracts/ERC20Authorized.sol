// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// The "server"
contract ERC20Authorized is IERC20Authorized, ERC20("AuthorizedToken", "AUTHD")
{
    // For registration verification
    mapping(address => bool) public registeredClients;

    // for E: Add More logic related to registration if needed here
    //
    //

    // Cap = 0 is the default and means no authorization. Usage: authorizerCaps[owner][authorizer]
    mapping(address => mapping(address => uint256)) public authorizerCaps;


    /* for E: Add a constructor and:
     * function to validate a contract is registered - also create a modifier
     * decide what events you want to emit upon: "registration", "rejection"
     * function to register a new address (client contract) - you need to think about how much ETH should be payed
     * create the supply of AUTHD, and the constructor, receive ETH - make this contract "Ownable"
     * Maybe a function to withdraw the ETH to the contract (server) creator/us
     */

    // for E: Your code here


    /*
     * INTERFACE FUNCTIONS (this is a placeholder to avoid merge conflicts
     */

    /// authorize docstring
    function authorize(address authorizer, uint256 cap) public
    {
        // require the call to be from a registered client
        // Actual implementation of authorization: update authorizer, approve authorizer
    }

    function increaseAuthorizerCap(address authorizer, uint256 addedCap) public
    {

    }

    function decreaseAuthorizerCap(address authorizer, uint256 subtractedCap) public
    {

    }

    function revokeAuthorizer(address authorizer) public
    {

    }

    /// This is the read function
    function AuthorizedCap(address authorizer) public
    {

    }

    /// Should be called by authorizer
    function approveFor(address owner, address spender, uint256 amount) public
    {

    }

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address[] memory spenders, uint256[] memory amounts) public
    {

    }
}
