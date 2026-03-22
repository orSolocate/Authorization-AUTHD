// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Non view function will be called by a client. View function could be called from any user
interface IERC20Authorized is IERC20
{
    /*
     * Registration / treasury events
     */
    event ClientRegistered(address indexed client, uint256 ethPaid, uint256 authdSent);
    event ClientRegistrationRevoked(address indexed client);
    event TreasuryWithdrawal(address indexed to, uint256 amount);

    /*
     * INTERFACE / AUTHORIZATION EVENTS
     */
    event Authorization(address indexed client, address indexed owner, address authorized, uint256 cap);
    event RevokeAuthorization(address indexed client, address indexed owner, address authorized);
    event IncreaseAuthorizedCap(address indexed client, address indexed owner, address authorized, uint256 newCap);
    event DecreaseAuthorizedCap(address indexed client, address indexed owner, address authorized, uint256 newCap);
    event ApproveFor(address indexed client, address indexed owner, address authorized, address spender, uint256 approvedAmount);

    function approveFor(address owner, address authorized, address spender, uint256 amount) external returns (uint256);

    function authorize(address owner, address authorized, uint256 cap) external;

    function getAuthorizedCap(address client, address owner, address authorized) view external returns (uint256);

    function getAuthorizersList(address client, address owner) external view returns (address[] memory);

    function getOwnersList(address client, address authorized) external view returns (address[] memory);

    function getRegistrationFee() external view returns (uint256);

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) external returns (uint256);

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) external returns (uint256);

    function isAuthorized(address client, address owner, address authorized) external view returns (bool);

    function isRegisteredClient(address client) external view returns (bool);

    function registerClient() external payable;

    function revokeAuthorization(address owner, address authorized) external;

    function revokeClientRegistration(address client) external;
}
