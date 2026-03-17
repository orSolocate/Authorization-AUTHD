// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
abstract contract ERC20AuthorizedClient is ERC20
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

    function _getIncreasedCap(uint256 currentCap, uint256 addedCapRequested) internal pure
    returns (uint256 newCap)
    {
        unchecked
        {
            newCap = currentCap + addedCapRequested;
            if (newCap < currentCap)
            {
                // Overflow occurred
                newCap = type(uint256).max;
            }
        }
    }

    /**
     * @param authorized - existing address authorized by caller
     * @param addedCap - token amount added to existing cap
     */
    function increaseAuthorizedCap(address authorized, uint256 addedCap) public
    {
        uint256 currentCap = GetAuthorizedCap(authorized);
        uint256 clientNewCap = _getIncreasedCap(currentCap, addedCap);
        approve(authorized, clientNewCap);
        uint256 serverNewCap = IERC20Authorized(authorizationServerAddr).increaseAuthorizedCap(
            msg.sender, authorized, addedCap);
        require(serverNewCap == clientNewCap);
    }

    function _GetDecreasedCap(uint256 currentCap, uint256 subtractedCapRequested) internal pure
        returns (uint256 newCap, uint256 actualSubtractedCap)
    {
        if (subtractedCapRequested >= currentCap)
        {
            // Underflow clips at 0
            newCap = 0;
            actualSubtractedCap = currentCap;
        }
        else
        {
            unchecked
            {
            // currentCap >= subtractedCap, no underflow
                newCap = currentCap - subtractedCapRequested;
                actualSubtractedCap = subtractedCapRequested;
            }
        }
    }

    /**
     * @param authorized - existing address authorized by caller
     * @param subtractedCap - token amount subtracted from existing cap (clipped to 0 in case larger than current cap).
     */
    function decreaseAuthorizedCap(address authorized, uint256 subtractedCap) public
    {
        uint256 currentCap = GetAuthorizedCap(authorized);
        (uint256 clientNewCap, ) = _GetDecreasedCap(currentCap, subtractedCap);
        approve(authorized, clientNewCap);
        uint256 serverNewCap = IERC20Authorized(authorizationServerAddr).decreaseAuthorizedCap(
            msg.sender, authorized, subtractedCap);
        require(serverNewCap == clientNewCap);
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
        (uint256 clientNewCap, uint256 clientApprovedAmount) =
                        _GetDecreasedCap(currentCap, amount);
        approve(msg.sender, clientNewCap);
        approve(spender, clientApprovedAmount);
        uint256 serverApprovedAmount = IERC20Authorized(authorizationServerAddr).approveFor(
            owner, msg.sender, spender, amount);
        require(serverApprovedAmount == clientApprovedAmount);
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

    // TODO: Modify server storage to accommodate this functionality
    function areAuthorizedByOwner(address owner) internal view returns (address[] memory)
    {
        address[] memory authorizers = new address[](1);
        authorizers[0] = owner;
        return authorizers;
    }


    function _update(address from, address to, uint256 value) internal virtual override
    {
        // Assume balances of 'from'/owner are updated here
        super._update(from, to, value);
        if ((from != address(0)) && (to != address(0)))
        {
            address[] memory authorizers = areAuthorizedByOwner(from);
            for (uint256 i = 0; i < authorizers.length; ++i)
            {
                if (IERC20Authorized(authorizationServerAddr).isAuthorized(
                    address(this), from, authorizers[i]))
                {
                    uint256 currentCap = IERC20Authorized(authorizationServerAddr).getAuthorizedCap(
                                            address(this), from, authorizers[i]);
                    uint256 ownerBalance = balanceOf(from);
                    if (currentCap > ownerBalance)
                    {
                        IERC20Authorized(authorizationServerAddr).decreaseAuthorizedCap(
                            from, authorizers[i], currentCap - ownerBalance);
                    }
                }
            }
        }
    }
}
