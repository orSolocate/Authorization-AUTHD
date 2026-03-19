// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import {ERC20AuthorizedErrors} from "./ERC20AuthorizedErrors.sol";

contract ERC20Authorized is ERC20, IERC20Authorized, ERC20AuthorizedErrors, Ownable {
    // ---------------------------------
    // Registration state
    // ---------------------------------
    mapping(address => bool) public registeredClients;

    uint256 private constant INITIAL_AUTHD_SUPPLY = 1_000_000 * 1e18;
    uint256 public constant CLIENT_AUTHD_POOL = 250_000 * 1e18;

    // Minimum ETH needed to register at all
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    // Base AUTHD amount granted for a valid registration
    uint256 public constant REGISTRATION_AUTHD_AMOUNT = 20 * 1e18;

    // Daily cached rate
    uint256 public cachedRateDay;
    uint256 public cachedAuthdRate;

    // Remaining AUTHD held by server for registrations
    uint256 public clientPoolRemaining;

    // ---------------------------------
    // Authorization state
    // ---------------------------------
    struct AuthorizationEntry {
        uint256 cap;
        bool isAuthorized;
    }

    // client token => owner => authorized => entry
    mapping(address => mapping(address => mapping(address => AuthorizationEntry))) public authorizationData;

    // ---------------------------------
    // Registration / treasury events
    // ---------------------------------
    event ClientRegistered(address indexed client, address indexed payer, uint256 ethPaid, uint256 authdSent);
    event ClientRegistrationRevoked(address indexed client);
    event TreasuryWithdrawal(address indexed to, uint256 amount);

    // ---------------------------------
    // Interface events
    // ---------------------------------
    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event ApproveFor(address indexed, address indexed, address, uint256);

    constructor() ERC20("AuthorizedToken", "AUTHD") Ownable(msg.sender) {
        clientPoolRemaining = CLIENT_AUTHD_POOL;

        // 25% for client registrations sits in this contract
        _mint(address(this), CLIENT_AUTHD_POOL);

        // 75% to owner/deployer
        _mint(msg.sender, INITIAL_AUTHD_SUPPLY - CLIENT_AUTHD_POOL);

        // Lock initial daily rate at deployment day
        cachedRateDay = _currentDay();
        cachedAuthdRate = previewAuthdRate(clientPoolRemaining / 1e18);
    }

    // ---------------------------------
    // Registration / treasury logic
    // ---------------------------------
    modifier onlyRegisteredClient() {
        require(registeredClients[msg.sender], "Client contract not registered");
        _;
    }

    function isRegisteredClient(address client) public view returns (bool) {
        return registeredClients[client];
    }

    function _currentDay() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function _linearRate(
        uint256 x,
        uint256 xHigh,
        uint256 xLow,
        uint256 yHigh,
        uint256 yLow
    ) internal pure returns (uint256) {
        require(x <= xHigh && x >= xLow, "x out of range");
        if (xHigh == xLow) return yLow;

        // y = yHigh + (xHigh - x) * (yLow - yHigh) / (xHigh - xLow)
        return yHigh + ((xHigh - x) * (yLow - yHigh)) / (xHigh - xLow);
    }

    /**
     * remainingWholeTokens is in whole AUTHD tokens, not wei units.
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
     * View helper for frontend/read-only use.
     * If today's rate is already cached, return it.
     * Otherwise preview what today's rate would be from current pool state.
     */
    function previewCurrentAuthdRate() public view returns (uint256) {
        uint256 today = _currentDay();
        if (cachedRateDay == today) {
            return cachedAuthdRate;
        }

        uint256 remainingWholeTokens = clientPoolRemaining / 1e18;
        return previewAuthdRate(remainingWholeTokens);
    }

    /**
     * Locks / refreshes the daily rate once per day.
     * Same day => same rate, even if registrations happen later that day.
     */
    function _getOrUpdateDailyAuthdRate() internal returns (uint256) {
        uint256 today = _currentDay();

        if (cachedRateDay != today) {
            cachedRateDay = today;
            cachedAuthdRate = previewAuthdRate(clientPoolRemaining / 1e18);
        }

        return cachedAuthdRate;
    }

    /**
     * Current locked ETH price per 1 whole AUTHD token.
     * This updates at most once per day.
     */
    function getAuthdRate() public returns (uint256) {
        return _getOrUpdateDailyAuthdRate();
    }

    function _registrationFeeFromRate(uint256 rate) internal pure returns (uint256) {
        uint256 dynamicFee = (REGISTRATION_AUTHD_AMOUNT * rate) / 1e18;
        return dynamicFee < REGISTRATION_FEE ? REGISTRATION_FEE : dynamicFee;
    }

    /**
     * Locked daily minimum fee needed to register.
     */
    function getRegistrationFee() public returns (uint256) {
        uint256 rate = _getOrUpdateDailyAuthdRate();
        return _registrationFeeFromRate(rate);
    }

    /**
     * View helper for reading today's minimum fee without changing state.
     */
    function previewCurrentRegistrationFee() public view returns (uint256) {
        uint256 rate = previewCurrentAuthdRate();
        return _registrationFeeFromRate(rate);
    }

    /**
     * Registration rules implemented here:
     * 1) Same-day rate is locked once first queried/used.
     * 2) Registration requires at least today's locked minimum fee.
     * 3) Base registration gives 20 AUTHD.
     * 4) Any ETH paid above the minimum fee is converted into extra AUTHD
     *    at the same locked daily rate.
     */
    function registerClient(address client) external payable {
        require(client != address(0), "Invalid client address");
        require(!registeredClients[client], "Client already registered");

        uint256 rate = _getOrUpdateDailyAuthdRate();
        uint256 fee = _registrationFeeFromRate(rate);

        require(msg.value >= fee, "Insufficient registration fee");

        uint256 authdAmount = REGISTRATION_AUTHD_AMOUNT;

        // Convert only the excess above the minimum fee into extra AUTHD
        if (msg.value > fee) {
            uint256 extraEth = msg.value - fee;
            uint256 extraAuthd = (extraEth * 1e18) / rate;
            authdAmount += extraAuthd;
        }

        require(clientPoolRemaining >= authdAmount, "Client pool exhausted");
        require(balanceOf(address(this)) >= authdAmount, "Insufficient AUTHD in pool");

        registeredClients[client] = true;
        clientPoolRemaining -= authdAmount;

        _transfer(address(this), client, authdAmount);

        emit ClientRegistered(client, msg.sender, msg.value, authdAmount);
    }

    function revokeClientRegistration(address client) external onlyOwner {
        require(registeredClients[client], "Client not registered");
        registeredClients[client] = false;
        emit ClientRegistrationRevoked(client);
    }

    function withdrawTreasury(address payable to) external onlyOwner {
        require(to != address(0), "Invalid withdraw address");

        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");

        (bool ok, ) = to.call{value: amount}("");
        require(ok, "ETH withdrawal failed");

        emit TreasuryWithdrawal(to, amount);
    }

    receive() external payable {}

    // ---------------------------------
    // Authorization logic
    // ---------------------------------
    modifier validCapAmount(uint256 capAmount) {
        if (capAmount == 0) {
            revert InvalidAmount(capAmount);
        }
        _;
    }

    modifier validAddress(address addr) {
        require(addr != address(0), "InvalidAddress");
        _;
    }

    modifier currentlyAuthorized(address clientAddr, address owner, address authorized) {
        if (!isAuthorized(clientAddr, owner, authorized)) {
            revert NotCurrentlyAuthorized(clientAddr, owner, authorized);
        }
        _;
    }

    function authorize(address owner, address authorized, uint256 cap)
        public
       
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

    function getAuthorizedCap(address client, address owner, address authorized)
        public
        view
        returns (uint256)
    {
        return authorizationData[client][owner][authorized].cap;
    }

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap)
        public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(addedCap)
        returns (uint256)
    {
        uint256 currentCap = authorizationData[msg.sender][owner][authorized].cap;

        unchecked {
            uint256 newCap = currentCap + addedCap;
            if (newCap < currentCap) {
                newCap = type(uint256).max;
            }

            if (IERC20(msg.sender).balanceOf(owner) < newCap) {
                revert InsufficientOwnerBalance(msg.sender, owner, newCap);
            }

            authorizationData[msg.sender][owner][authorized].cap = newCap;
            emit IncreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
            return newCap;
        }
    }

    function _decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap)
        internal
        returns (uint256)
    {
        uint256 currentCap = authorizationData[msg.sender][owner][authorized].cap;
        uint256 newCap;

        if (subtractedCap >= currentCap) {
            newCap = 0;
        } else {
            unchecked {
                newCap = currentCap - subtractedCap;
            }
        }

        authorizationData[msg.sender][owner][authorized].cap = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
        return newCap;
    }

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap)
        public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(subtractedCap)
        returns (uint256)
    {
        return _decreaseAuthorizedCap(owner, authorized, subtractedCap);
    }

    function isAuthorized(address client, address owner, address authorized)
        public
        view
        returns (bool)
    {
        return authorizationData[client][owner][authorized].isAuthorized;
    }

    function revokeAuthorization(address owner, address authorized)
        public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
    {
        delete authorizationData[msg.sender][owner][authorized];
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    function approveFor(address owner, address authorized, address spender, uint256 amount)
        public
        onlyRegisteredClient
        currentlyAuthorized(msg.sender, owner, authorized)
        validAddress(spender)
    {
        if (spender == authorized || spender == owner) {
            revert InvalidSpender(spender);
        }

        uint256 currentCap = getAuthorizedCap(msg.sender, owner, authorized);
        if (currentCap < amount) {
            revert InsufficientAuthorizedCap(msg.sender, owner, authorized, currentCap, amount);
        }

        if (amount > 0) {
            _decreaseAuthorizedCap(owner, authorized, amount);
        }

        emit ApproveFor(msg.sender, owner, authorized, amount);
    }
}