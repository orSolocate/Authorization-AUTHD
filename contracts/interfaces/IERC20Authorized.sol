// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// These are all the functions that will be called from the client, but they will be implemented by the server as well
interface IERC20Authorized
{
    /// Should be called by owner
    function authorize(address authorizer, uint256 cap) external;

    function increaseAuthorizerCap(address authorizer, uint256 addedCap) external;

    function decreaseAuthorizerCap(address authorizer, uint256 subtractedCap) external;

    function revokeAuthorizer(address authorizer) external;

    /// This is the read function
    function AuthorizedCap(address authorizer) external;

    /// Should be called by authorizer
    function approveFor(address owner, address spender, uint256 amount) external;

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address[] memory spenders, uint256[] memory amounts) external;
}
