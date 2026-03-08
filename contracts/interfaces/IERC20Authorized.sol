// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// These are all the functions that will be called from the client, but they will be implemented by the server as well
interface IERC20Authorized is IERC20
{
    /// Should be called by owner
    function authorize(address addr, address authorized, uint256 cap) external;

    function getAuthorizedCap(address addr, address owner, address authorized) view external returns (uint256);

    function increaseAuthorizedCap(address addr, address authorized, uint256 addedCap) external;

    function decreaseAuthorizedCap(address addr, address authorized, uint256 subtractedCap) external;

    function isAuthorizedByMe(address addr, address authorized) external view returns (bool);

    function revokeAuthorization(address addr, address authorized) external;

    /// Should be called by authorized
    function approveFor(address owner, address spender, uint256 amount) external;

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address[] memory spenders, uint256[] memory amounts) external;
}
