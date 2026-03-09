// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// For Debug:
//import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";

/// The "server"
contract ERC20Authorized is ERC20, Ownable, IERC20Authorized
{
    // For registration verification
    mapping(address => bool) public registeredClients;

    uint256 private constant INITIAL_AUTHD_SUPPLY = 1_000_000 * 10**18;

    // Simple capstone-friendly registration economics
    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant REGISTRATION_AUTHD_AMOUNT = 20 * 10**18;

    // Cap = 0 is the default and means no authorization.
    // Usage: authorizedCaps[token][owner][authorized]
    mapping(address => mapping(address => mapping(address => uint256))) public authorizedCaps;

    /*
     * Registration / treasury events
     */
    event ClientRegistered(address indexed client, address indexed payer, uint256 ethPaid, uint256 authdSent);
    event ClientRegistrationRevoked(address indexed client);
    event TreasuryWithdrawal(address indexed to, uint256 amount);

    /*
     * INTERFACE / AUTHORIZATION EVENTS
     */
    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event ApproveFor(address indexed, address indexed, address, uint256);

    constructor() ERC20("AuthorizedToken", "AUTHD") Ownable(msg.sender)
    {
        // The server contract itself holds the AUTHD supply
        _mint(address(this), INITIAL_AUTHD_SUPPLY);
    }

    /*
     * -----------------------------
     * For E: Registration / Treasury
     * -----------------------------
     */

    modifier onlyRegisteredClient()
    {
        require(registeredClients[msg.sender], "Client contract not registered");
        _;
    }

    function isRegisteredClient(address client) public view returns (bool)
    {
        return registeredClients[client];
    }

    /**
     * Register a client token contract so it can use the AUTHD authorization logic.
     *
     * Simple capstone model:
     * - payer sends ETH
     * - server marks `client` as registered
     * - server sends a fixed amount of AUTHD to the client address
     */
    function registerClient(address client) external payable
    {
        require(client != address(0), "Invalid client address");
        require(!registeredClients[client], "Client already registered");
        require(msg.value >= REGISTRATION_FEE, "Insufficient registration fee");
        require(balanceOf(address(this)) >= REGISTRATION_AUTHD_AMOUNT, "Insufficient AUTHD supply");

        registeredClients[client] = true;

        // send AUTHD to the client contract address
        _transfer(address(this), client, REGISTRATION_AUTHD_AMOUNT);

        emit ClientRegistered(client, msg.sender, msg.value, REGISTRATION_AUTHD_AMOUNT);
    }

    /**
     * Optional admin function in case you want to disable a client later.
     */
    function revokeClientRegistration(address client) external onlyOwner
    {
        require(registeredClients[client], "Client not registered");
        registeredClients[client] = false;
        emit ClientRegistrationRevoked(client);
    }

    /**
     * Withdraw ETH accumulated from client registrations.
     */
    function withdrawTreasury(address payable to) external onlyOwner
    {
        require(to != address(0), "Invalid withdraw address");

        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH withdrawal failed");

        emit TreasuryWithdrawal(to, amount);
    }

    receive() external payable {}

    /*
     * -----------------------------
     * Existing authorization logic
     * -----------------------------
     */

    modifier validCap(uint256 cap)
    {
        require(cap > 0, "Cap amount cannot be empty");
        _;
    }

    modifier currentlyAuthorized(address addr, address owner, address authorized)
    {
        require(isAuthorized(addr, owner, authorized), "Address not authorized");
        _;
    }

    /// authorize docstring - assuming msg.sender is the registered token contract
    function authorize(address owner, address authorized, uint256 cap) public
        validCap(cap)
        onlyRegisteredClient
    {
        require(owner != authorized, "Self authorization is prohibited");
        require(!isAuthorized(msg.sender, owner, authorized), "Address already authorized, call increase/decrease instead");
        require(IERC20(msg.sender).balanceOf(owner) >= cap, "Cannot authorize more than balance");

        authorizedCaps[msg.sender][owner][authorized] = cap;
        emit Authorization(msg.sender, owner, authorized, cap);
    }

    /// This is the read function
    function getAuthorizedCap(address addr, address owner, address authorized) view public returns (uint256)
    {
        return authorizedCaps[addr][owner][authorized];
    }

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(addedCap)
        returns (uint256)
    {
        uint256 currentCap = authorizedCaps[msg.sender][owner][authorized];
        unchecked
        {
            uint256 newCap = currentCap + addedCap;
            if (newCap < currentCap)
            {
                // Overflow occurred
                newCap = type(uint256).max;
            }

            require(IERC20(msg.sender).balanceOf(owner) >= newCap, "Cannot authorize more than balance");

            authorizedCaps[msg.sender][owner][authorized] = newCap;
            emit IncreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
            return newCap;
        }
    }

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(subtractedCap)
        returns (uint256)
    {
        uint256 currentCap = authorizedCaps[msg.sender][owner][authorized];
        uint256 newCap;

        if (subtractedCap >= currentCap)
        {
            newCap = 0;
        }
        else
        {
            unchecked
            {
                // currentCap >= subtractedCap, no underflow
                newCap = currentCap - subtractedCap;
            }
        }

        authorizedCaps[msg.sender][owner][authorized] = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
        return newCap;
    }

    function isAuthorized(address addr, address owner, address authorized) public view returns (bool)
    {
        return authorizedCaps[addr][owner][authorized] > 0;
    }

    function revokeAuthorization(address owner, address authorized) public onlyRegisteredClient
    {
        require(isAuthorized(msg.sender, owner, authorized), "Cannot revoke authorization without authorizing first");
        delete authorizedCaps[msg.sender][owner][authorized];
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    function approveFor(address owner, address authorized, address spender, uint256 amount) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(amount)
    {
        require(spender != authorized, "Self approval is prohibited");
        require(spender != owner, "Approval to owner is prohibited");
        // ERC20 allows approval > balance, so leave balance check out
        require(getAuthorizedCap(msg.sender, owner, authorized) >= amount, "Authorized doesn't have enough cap");

        decreaseAuthorizedCap(owner, authorized, amount);
        emit ApproveFor(msg.sender, owner, authorized, amount);

        // Approval itself done by client
    }

    /*
    // TODO: Consider moving this functionality to Client
    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address authorized, address[] calldata spenders, uint256[] calldata amounts) public
    {
        require((spenders.length == amounts.length) && (amounts.length > 0), "Spenders and amounts array length should be non-zero and same");
        for (uint256 i = 0; i < spenders.length; ++i)
        {
            approveFor(owner, authorized, spenders[i], amounts[i]);
        }
    }
    */
}