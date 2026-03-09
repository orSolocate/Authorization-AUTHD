// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
abstract contract ERC20AuthorizedClient is IERC20Authorized, ERC20
{
    // Would be changed once ERC20Authorizer official contract is deployed in Sepolia
    address immutable private authorizationServerAddr;

    constructor (address _authorizationServerAddr)
    {
        authorizationServerAddr = _authorizationServerAddr;
    }

    /**
     * @param authorized - address to enable authorization by caller
     * @param cap - authorized token amount limit/cap
     */
    function authorize(address authorized, uint256 cap) public
    {
        IERC20Authorized(authorizationServerAddr).authorize(
            msg.sender, authorized, cap);
        // Authorized address is automatically approved on its cap
        approve(authorized, cap);
    }

    /**
     * @param authorized - existing address authorized by caller
     * @return authorization cap or 0 if not authorized
     */
    function GetAuthorizedCap(address authorized) view public returns (uint256)
    {
        return IERC20Authorized(authorizationServerAddr).getAuthorizedCap(
            address(this), msg.sender, authorized);
    }

    /**
     * @dev A function for authorized users to verify authorization cap given by a specific owner
     * @param owner - The address that already authorized the caller
     * @return authorization cap or 0 if not authorized
     */

    function GetAuthorizedByCap(address owner) view public returns (uint256)
    {
        return IERC20Authorized(authorizationServerAddr).getAuthorizedCap(
            address(this), owner, msg.sender);
    }

    /**
     * @param authorized - existing address authorized by caller
     * @param addedCap - token amount added to existing cap
     */
    function increaseAuthorizedCap(address authorized, uint256 addedCap) public
    {
        uint256 newCap = IERC20Authorized(authorizationServerAddr).increaseAuthorizedCap(
            msg.sender, authorized, addedCap);
        approve(authorized, newCap);
    }

    /**
     * @param authorized - existing address authorized by caller
     * @param subtractedCap - token amount subtracted from existing cap (clipped to 0 in case larger than current cap).
     */
    function decreaseAuthorizedCap(address authorized, uint256 subtractedCap) public
    {
        uint256 newCap = IERC20Authorized(authorizationServerAddr).decreaseAuthorizedCap(
            msg.sender, authorized, subtractedCap);
        approve(authorized, newCap);
    }

    /**
     * @param authorized - existing address authorized by caller
     * @return true when authorized address have a positive cap
     */
    function isAuthorized(address authorized) public view returns (bool)
    {
        return IERC20Authorized(authorizationServerAddr).isAuthorized(
            address(this), msg.sender, authorized);
    }

    /**
     * @dev A function for authorized users to verify authorization from a specific owner
     * @param owner - address that authorized the caller
     * @return true when authorized address have a positive cap
     */
    function isAuthorizedBy(address owner) public view returns (bool)
    {
        return IERC20Authorized(authorizationServerAddr).isAuthorized(
            address(this), owner, msg.sender);
    }

    /**
     * @param authorized - existing address authorized by caller
     */
    function revokeAuthorization(address authorized) public
    {
        approve(authorized, 0);
        IERC20Authorized(authorizationServerAddr).revokeAuthorization(
            msg.sender, authorized);
    }

    /**
     * @param owner - address that authorized the caller
     * @param spender - address to approve
     * @param amount - token amount to approve spender to spend
     */
    function approveFor(address owner, address spender, uint256 amount) public
    {
        uint256 currentCap = GetAuthorizedByCap(owner);
        uint256 newAuthorizedCap;
        if (amount >= currentCap)
        {
            // Underflow clips at 0
            newAuthorizedCap = 0;
        }
        else
        {
            unchecked
            {
            // currentCap>=subtractedCap, no way for underflow
                newAuthorizedCap = currentCap - amount;
            }
        }
        approve(msg.sender, newAuthorizedCap);
        approve(spender, amount);
        IERC20Authorized(authorizationServerAddr).approveFor(
            owner, msg.sender, spender, amount);
    }

    /**
     * @param owner - address that authorized the caller
     * @param spenders - addresses of spenders to approve
     * @param amounts - token amounts to approve each respective spender (amount[i] corresponds to spenders[i])
     */
    function approveForMultiple(address owner,  address[] calldata spenders, uint256[] calldata amounts) public
    {
        require((spenders.length == amounts.length) && (amounts.length > 0),
            "Spenders and amounts array length should be non-zero and same");
        for (uint256 i = 0; i < spenders.length; ++i)
        {
            // TODO: consider maybe not revert all if some approvals fail
            IERC20Authorized(authorizationServerAddr).approveFor(
                owner, msg.sender, spenders[i], amounts[i]);
        }
    }
}
