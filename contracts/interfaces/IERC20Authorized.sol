// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// These are all the functions that will be called from the client, but they will be implemented by the server as well
interface IERC20Authorized is IERC20
{
    /// Should be called by owner
    function authorize(address owner, address authorized, uint256 cap) external;

    function getAuthorizedCap(address client, address owner, address authorized) view external returns (uint256);

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) external returns (uint256);

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) external returns (uint256);

    function isAuthorized(address client, address owner, address authorized) external view returns (bool);

    function revokeAuthorization(address owner, address authorized) external;

    function approveFor(address owner, address authorized, address spender, uint256 amount) external returns (uint256);

    // TODO: Consider moving this functionality to Client
    // Supports approving multiple spenders in a single transaction
    // function approveFor(address owner, address authorized, address[] calldata spenders, uint256[] calldata amounts) external;
}
