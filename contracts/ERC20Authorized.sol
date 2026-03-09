// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// For Debug:
//import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";

/// The "server"
contract ERC20Authorized is ERC20, IERC20Authorized
{
    // For registration verification
    mapping(address => bool) public registeredClients;

    uint256 private constant INITIAL_AUTHD_SUPPLY = 1_000_000 * 10**18;
    // for E: Add More logic related to registration if needed here
    //
    //

    // Cap = 0 is the default and means no authorization. Usage: authorizedCaps[owner][authorized]
    mapping(address => mapping(address => mapping(address => uint256))) public authorizedCaps;


    /* for E: Add a constructor and:
     * function to validate a contract is registered - also create a modifier
     * decide what events you want to emit upon: "registration", "rejection"
     * function to register a new address (client contract) - you need to think about how much ETH should be payed
     * create the supply of AUTHD, and the constructor, receive ETH - make this contract "Ownable"
     * Maybe a function to withdraw the ETH to the contract (server) creator/us
     */

    constructor() ERC20("AuthorizedToken", "AUTHD")
    {
        // For E: registration: check if needed after you add Ownable
        //_mint(msg.sender, INITIAL_AUTHD_SUPPLY);
    }

    // for E: Your code here


    /*
     * INTERFACE FUNCTIONS (this is a placeholder to avoid merge conflicts
     */

    // TODO: use custom errors instead of `require` to reduce code size
    // TODO: change msg.sender logic in all contract when implementing the _update logic on spend

    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event ApproveFor(address indexed, address indexed, address, uint256);

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

    /// authorize docstring - assuming addr is the address of the token contract
    function authorize(address owner, address authorized, uint256 cap) public validCap(cap)
    {
        // require the call to be from a registered client
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
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(addedCap)
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
        }
    }

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(subtractedCap)
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
                // currentCap>=subtractedCap, no way for underflow
                newCap = currentCap - subtractedCap;
            }
        }
        authorizedCaps[msg.sender][owner][authorized] = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
    }

    function isAuthorized(address addr, address owner, address authorized) public view returns (bool)
    {
        return authorizedCaps[addr][owner][authorized] > 0;
    }

    function revokeAuthorization(address owner, address authorized) public
    {
        require(isAuthorized(msg.sender, owner, authorized), "Cannot revoke authorization without authorizing first");
        delete authorizedCaps[msg.sender][owner][authorized];
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    function approveFor(address owner, address authorized, address spender, uint256 amount) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCap(amount)
    {
        // require(isRegistered(msg.sender), "Contract not registered to authorize");
        require(spender != authorized, "Self approval is prohibited");
        require(spender != owner, "Approval to owner is prohibited");
        // ERC20 allows to approve more than owner balance, fails only during transfer. So leave this error check out
        //require(IERC20(msg.sender).balanceOf(owner) >= amount, "Owner doesn't have enough balance");
        require(getAuthorizedCap(msg.sender, owner, authorized) >= amount, "Authorized doesn't have enough cap");
        decreaseAuthorizedCap(owner, authorized, amount);
        emit ApproveFor(msg.sender, owner,  authorized, amount);
        // Approval itself done by client
    }

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address authorized, address[] calldata spenders, uint256[] calldata amounts) public
    {
        require((spenders.length == amounts.length) && (amounts.length > 0), "Spenders and amounts array length should be non-zero and same");
        for (uint256 i = 0; i < spenders.length; ++i)
        {
            // TODO: consider maybe not revert all if some approvals fail
            approveFor(owner, authorized, spenders[i], amounts[i]);
        }
    }
}
