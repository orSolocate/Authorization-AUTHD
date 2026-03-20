// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// For Debug:
//import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import {ERC20AuthorizedErrors} from "./ERC20AuthorizedErrors.sol";

/// The "server"
contract ERC20Authorized is ERC20, Ownable, IERC20Authorized, ERC20AuthorizedErrors
{
    // For registration verification
    mapping(address => bool) public registeredClients;

    uint256 private constant INITIAL_AUTHD_SUPPLY = 1_000_000;
    // 25% of total supply reserved for client registrations
    uint256 public constant CLIENT_AUTHD_POOL = 250_000;

    // Simple capstone-friendly registration economics
    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant REGISTRATION_AUTHD_AMOUNT = 20;

    // Remaining AUTHD reserved for clients
    uint256 public clientPoolRemaining;

    // Cap = 0 is the default and means no authorization.
    struct AuthorizationEntry
    {
        uint256 cap;
        bool isAuthorized;
    }
    mapping(address => mapping(address => mapping(address => AuthorizationEntry))) public authorizationData;

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
        require(registeredClients[msg.sender], "Client contract not registered");
        _;
    }

    function isRegisteredClient(address client) public view returns (bool)
    {
        return registeredClients[client];
    }

    function _linearRate(uint256 x, uint256 xHigh, uint256 xLow, uint256 yHigh, uint256 yLow) internal pure returns (uint256) {
        require(x <= xHigh && x >= xLow, "x out of range");
        if (xHigh == xLow) return yLow;

        // y = yHigh + (xHigh - x) * (yLow - yHigh) / (xHigh - xLow)
        return yHigh + ((xHigh - x) * (yLow - yHigh)) / (xHigh - xLow);
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
    function previewAuthdRate(uint256 remainingWholeTokens) public pure returns (uint256) {
        if (remainingWholeTokens >= 200_000) {
            return _linearRate(
                remainingWholeTokens,
                250_000,
                200_000,
                0.00002 ether,
                0.0004 ether
            );
        }

        if (remainingWholeTokens >= 50_000) {
            return _linearRate(
                remainingWholeTokens,
                200_000,
                50_000,
                0.0004 ether,
                0.002 ether
            );
        }

        return _linearRate(
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
    function getAuthdRate() public view returns (uint256) {
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
     * The caller pays ETH according to the current rate and the client receives 20 AUTHD.
     */
    function registerClient(address client) external payable {
        require(client != address(0), "Invalid client address");
        require(!registeredClients[client], "Client already registered");

        uint256 fee = getRegistrationFee();
        require(msg.value >= fee, "Insufficient registration fee");
        require(clientPoolRemaining >= REGISTRATION_AUTHD_AMOUNT, "Client pool exhausted");
        require(balanceOf(address(this)) >= REGISTRATION_AUTHD_AMOUNT, "Insufficient AUTHD in pool");
        // TODO: use custom errors instead of `require` to reduce code size
        registeredClients[client] = true;
        clientPoolRemaining -= REGISTRATION_AUTHD_AMOUNT;

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

    modifier validCapAmount(uint256 capAmount)
    {
        if (capAmount == 0)
        {
            revert InvalidAmount(capAmount);
        }
        _;
    }

    modifier validAddress(address addr)
    {
        require(addr != address(0), "InvalidAddress");
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

    /// authorize docstring - assuming msg.sender is the registered token contract
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
        authorizationData[msg.sender][owner][authorized].isAuthorized = true;
        authorizationData[msg.sender][owner][authorized].cap = cap;
        emit Authorization(msg.sender, owner, authorized, cap);
    }

    /// This is the read function
    function getAuthorizedCap(address client, address owner, address authorized) view public returns (uint256)
    {
        return authorizationData[client][owner][authorized].cap;
    }

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(addedCap)
        returns (uint256)
    {
        uint256 currentCap = authorizationData[msg.sender][owner][authorized].cap;
        unchecked
        {
            uint256 newCap = currentCap + addedCap;
            if (newCap < currentCap)
            {
                // Overflow occurred
                newCap = type(uint256).max;
            }
            if (IERC20(msg.sender).balanceOf(owner) < newCap)
            {
                revert InsufficientOwnerBalance(msg.sender, owner, newCap);
            }
            authorizationData[msg.sender][owner][authorized].cap = newCap;
            emit IncreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
            return newCap;
        }
    }

    function _decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
    onlyRegisteredClient
    returns (uint256)
    {
        uint256 currentCap = authorizationData[msg.sender][owner][authorized].cap;
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
        authorizationData[msg.sender][owner][authorized].cap = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
        return newCap;
    }


    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(subtractedCap)
        returns (uint256)
    {
        return _decreaseAuthorizedCap(owner, authorized, subtractedCap);
    }

    function isAuthorized(address addr, address owner, address authorized) public view returns (bool)
    {
        return authorizationData[addr][owner][authorized].isAuthorized;
    }

    function revokeAuthorization(address owner, address authorized) public onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
    {
        delete authorizationData[msg.sender][owner][authorized];
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    function approveFor(address owner, address authorized, address spender, uint256 amount) public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validAddress(spender)
    {
        if ((spender == authorized) || (spender == owner))
        {
            revert InvalidSpender(spender);
        }
        // ERC20 allows approval > balance, so leave balance check out
        uint256 currentCap = getAuthorizedCap(msg.sender, owner, authorized);
        if (currentCap < amount)
        {
            revert InsufficientAuthorizedCap(
                msg.sender, owner, authorized, currentCap, amount);
        }
        if (amount > 0)
        {
            _decreaseAuthorizedCap(owner, authorized, amount);
        }
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