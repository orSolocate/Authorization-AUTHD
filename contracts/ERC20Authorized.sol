// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// For Debug:
//import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import {ERC20AuthorizedErrors} from "./ERC20AuthorizedErrors.sol";
import "./lib/AddressArrayUtils.sol";
import {LinearRate} from "./lib/LinearRate.sol";

/// The "server"
contract ERC20Authorized is ERC20, Ownable, IERC20Authorized, ERC20AuthorizedErrors
{
    using AddressArrayUtils for address[];
    // For registration verification
    mapping(address => bool) public isRegisteredClient;

    uint256 internal constant INITIAL_AUTHD_SUPPLY = 1_000_000;
    // 25% of total supply reserved for client registrations
    uint256 internal constant CLIENT_AUTHD_POOL = 250_000;

    // Simple capstone-friendly registration economics
    uint256 internal constant REGISTRATION_FEE = 0.01 ether;

    uint256 public constant REGISTRATION_AUTHD_AMOUNT = 20;

    // Remaining AUTHD reserved for clients
    uint256 internal clientPoolRemaining;

    struct AuthorizationDataEntry
    {
        uint256 cap;
        bool isAuthorized;
    }
    struct AuthorizationOwner
    {
        mapping(address => AuthorizationDataEntry) authorizationInfo;
        address[] authorizers;
    }
    struct AuthorizationClient
    {
        mapping(address => AuthorizationOwner) authorizationOwner;
        mapping (address => address[]) delegatedBy;
    }

    mapping(address => AuthorizationClient) internal authorizationData;

    constructor() ERC20("AuthorizedToken", "AUTHD") Ownable(msg.sender)
    {
        clientPoolRemaining = CLIENT_AUTHD_POOL;

        // 25% for client registrations sits in the contract
        _mint(address(this), CLIENT_AUTHD_POOL);

        // Remaining 75% goes to deployer/owner
        _mint(msg.sender, INITIAL_AUTHD_SUPPLY - CLIENT_AUTHD_POOL);
    }

    /*
     * -----------------------------
     * For E: Registration / Treasury
     * -----------------------------
     */

    modifier onlyRegisteredClient()
    {
        if (!isRegisteredClient[msg.sender])
        {
            revert ClientNotRegistered(msg.sender);
        }
        _;
    }

    /**
     * Piecewise linear pricing preview.
     *
     * remainingWholeTokens is the number of whole AUTHD tokens left in the client pool
     * (not 18-decimal units).
     *
     * Tier 1: 250000 -> 200000 maps 0.00002 ETH -> 0.0004 ETH
     * Tier 2: 200000 ->  50000 maps 0.0004 ETH -> 0.002 ETH
     * Tier 3:  50000 ->      0 maps 0.002 ETH -> 0.01 ETH
     */
    function previewAuthdRate(uint256 remainingWholeTokens) internal pure returns (uint256) {
        if (remainingWholeTokens >= 200_000) {
            return LinearRate.linearRate(
                remainingWholeTokens,
                250_000,
                200_000,
                0.00002 ether,
                0.0004 ether
            );
        }

        if (remainingWholeTokens >= 50_000) {
            return LinearRate.linearRate(
                remainingWholeTokens,
                200_000,
                50_000,
                0.0004 ether,
                0.002 ether
            );
        }

        return LinearRate.linearRate(
            remainingWholeTokens,
            50_000,
            0,
            0.002 ether,
            0.01 ether
        );
    }

    /**
     * Current ETH price per 1 AUTHD token (1 whole token, not 1 wei of AUTHD).
     */
    function getAuthdRate() internal view returns (uint256) {
        uint256 remainingWholeTokens = clientPoolRemaining / 1e18;
        return previewAuthdRate(remainingWholeTokens);
    }

    /**
     * ETH fee to register a client for REGISTRATION_AUTHD_AMOUNT (20 AUTHD).
     */
    function getRegistrationFee() public view returns (uint256) {
        uint256 dynamicFee = (REGISTRATION_AUTHD_AMOUNT * getAuthdRate()) / 1e18;

        if (dynamicFee < REGISTRATION_FEE) {
            return REGISTRATION_FEE;
        }

        return dynamicFee;
    }

    /**
     * Register a client token contract so it can use the AUTHD authorization logic.
     *
     * Simple capstone model:
     * - payer sends ETH
     * - server marks `client` as registered
     * - server sends a fixed amount of AUTHD to the client address
     */
    /**
     * Register a client token contract.
     * The caller (client) pays ETH according to the current rate and receives back AUTHD tokens
     */
    function registerClient() public payable validAddress(msg.sender) {
        address client = msg.sender;
        if (isRegisteredClient[client])
        {
            revert AlreadyRegistered(client);
        }
        uint256 fee = getRegistrationFee();
        if (msg.value < fee)
        {
            revert InsufficientRegistrationFee(msg.value, fee);
        }
        if (clientPoolRemaining < REGISTRATION_AUTHD_AMOUNT)
        {
            revert ClientPoolExhuasted(clientPoolRemaining, REGISTRATION_AUTHD_AMOUNT);
        }
        if (balanceOf(address(this)) < REGISTRATION_AUTHD_AMOUNT)
        {
            revert InsufficientAuthdSupply(balanceOf(address(this)), REGISTRATION_AUTHD_AMOUNT);
        }
        isRegisteredClient[client] = true;
        clientPoolRemaining -= REGISTRATION_AUTHD_AMOUNT;

        _transfer(address(this), client, REGISTRATION_AUTHD_AMOUNT);

        emit ClientRegistered(client, msg.value, REGISTRATION_AUTHD_AMOUNT);
    }

    /**
     * Optional admin function in case you want to disable a client later.
     */
    function revokeClientRegistration(address client) external onlyOwner
    {
        if (!isRegisteredClient[client])
        {
            revert ClientNotRegistered(client);
        }
        isRegisteredClient[client] = false;
        delete authorizationData[client];
        emit ClientRegistrationRevoked(client);
    }

    /**
     * Withdraw ETH accumulated from client registrations.
     */
    function withdrawTreasury(address payable to) external onlyOwner validAddress(to)
    {
        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");
        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH withdrawal failed");

        emit TreasuryWithdrawal(to, amount);
    }

    receive() external payable {}

    /*
     * -----------------------------
     * Authorization server-side logic
     * -----------------------------
     */

    modifier validCapAmount(uint256 capAmount)
    {
        if (capAmount == 0)
        {
            revert InvalidAmount(capAmount);
        }
        _;
    }

    modifier validAddress(address client)
    {
        require(client != address(0), "InvalidAddress");
        _;
    }

    modifier currentlyAuthorized(address client, address owner, address authorized)
    {
        if (!isAuthorized(client, owner, authorized))
        {
            revert NotCurrentlyAuthorized(client, owner, authorized);
        }
        _;
    }

    function authorize(address owner, address authorized, uint256 cap) public
        onlyRegisteredClient
        validAddress(owner)
        validAddress(authorized)
    {
        if (owner == authorized) {
            revert SelfAuthorizationProhibited();
        }

        if (isAuthorized(msg.sender, owner, authorized)) {
            revert AlreadyAuthorized(msg.sender, owner, authorized);
        }

        if (IERC20(msg.sender).balanceOf(owner) < cap) {
            revert InsufficientOwnerBalance(msg.sender, owner, cap);
        }
        authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].isAuthorized = true;
        authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap = cap;
        authorizationData[msg.sender].authorizationOwner[owner].authorizers.push() = authorized;
        authorizationData[msg.sender].delegatedBy[authorized].push() = owner;
        emit Authorization(msg.sender, owner, authorized, cap);
    }

    function getAuthorizedCap(address client, address owner, address authorized) view public returns (uint256)
    {
        return authorizationData[client].authorizationOwner[owner].authorizationInfo[authorized].cap;
    }

    function getAuthorizersList(address client, address owner) public view returns (address[] memory)
    {
        return authorizationData[client].authorizationOwner[owner].authorizers;
    }

    function getOwnersList(address client, address authorized) public view returns (address[] memory)
    {
        return authorizationData[client].delegatedBy[authorized];
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

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(addedCap)
        returns (uint256 newCap)
    {
        uint256 currentCap = authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap;
        newCap = _getIncreasedCap(currentCap, addedCap);
        if (IERC20(msg.sender).balanceOf(owner) < newCap)
        {
           revert InsufficientOwnerBalance(msg.sender, owner, newCap);
        }
        authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap = newCap;
        emit IncreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
    }

    function _getDecreasedCap(uint256 currentCap, uint256 subtractedCapRequested) internal pure
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

    function _decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) internal
        returns (uint256 newCap, uint256 approvedAmount)
    {
        uint256 currentCap = authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap;
        (newCap, approvedAmount) = _getDecreasedCap(currentCap, subtractedCap);
        authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
    }

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(subtractedCap)
        returns (uint256 newCap)
    {
        (newCap, ) = _decreaseAuthorizedCap(owner, authorized, subtractedCap);
    }

    function isAuthorized(address client, address owner, address authorized) public view returns (bool)
    {
        return authorizationData[client].authorizationOwner[owner].authorizationInfo[authorized].isAuthorized;
    }

    function revokeAuthorization(address owner, address authorized) public onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
    {
        delete authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized];
        authorizationData[msg.sender].authorizationOwner[owner].authorizers.removeAddressFromArray(authorized);
        authorizationData[msg.sender].delegatedBy[authorized].removeAddressFromArray(owner);
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    // Approval itself done by client, it is possible to approve on more than owner's current balance, as per ERC20's
    // approve() method
    function approveFor(address owner, address authorized, address spender, uint256 amount) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validAddress(spender)
        returns (uint256)
    {
        if ((spender == authorized) || (spender == owner))
        {
            revert InvalidSpender(spender);
        }
        uint256 currentCap = authorizationData[msg.sender].authorizationOwner[owner].authorizationInfo[authorized].cap;
        if (currentCap < amount)
        {
            revert InsufficientAuthorizedCap(
                msg.sender, owner, authorized, currentCap, amount);
        }
        if (amount > 0)
        {
            _decreaseAuthorizedCap(owner, authorized, amount);
        }
        emit ApproveFor(msg.sender, owner, authorized, spender, amount);
        return amount;
    }
}