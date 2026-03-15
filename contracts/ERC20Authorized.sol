// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// For Debug:
//import "hardhat/console.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Authorized} from "./interfaces/IERC20Authorized.sol";
import {ERC20AuthorizedErrors} from "./ERC20AuthorizedErrors.sol";

/// The "server"
contract ERC20Authorized is ERC20, IERC20Authorized, ERC20AuthorizedErrors
{
    // For registration verification
    mapping(address => bool) public registeredClients;

    //uint256 private constant INITIAL_AUTHD_SUPPLY = 1_000_000 * 10**18;
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

    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event ApproveFor(address indexed, address indexed, address, uint256);

    modifier validCapAmount(uint256 capAmount)
    {
        if (capAmount == 0)
        {
            revert InvalidAmount(capAmount);
        }
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

    /// authorize docstring - assuming addr is the address of the token contract
    function authorize(address owner, address authorized, uint256 cap) public validCapAmount(cap)
    {
        // require the call to be from a registered client
        if (owner == authorized)
        {
            revert SelfAuthorizationProhibited();
        }
        if (isAuthorized(msg.sender, owner, authorized))
        {
            revert AlreadyAuthorized(msg.sender, owner, authorized);
        }
        if (IERC20(msg.sender).balanceOf(owner) < cap)
        {
            revert InsufficientOwnerBalance(msg.sender, owner, cap);
        }
        authorizedCaps[msg.sender][owner][authorized] = cap;
        emit Authorization(msg.sender, owner, authorized, cap);
    }

    /// This is the read function
    function getAuthorizedCap(address client, address owner, address authorized) view public returns (uint256)
    {
        return authorizedCaps[client][owner][authorized];
    }

    function increaseAuthorizedCap(address owner, address authorized, uint256 addedCap) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(addedCap)
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
            if (IERC20(msg.sender).balanceOf(owner) < newCap)
            {
                revert InsufficientOwnerBalance(msg.sender, owner, newCap);
            }
            authorizedCaps[msg.sender][owner][authorized] = newCap;
            emit IncreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
            return newCap;
        }
    }

    function decreaseAuthorizedCap(address owner, address authorized, uint256 subtractedCap) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(subtractedCap)
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
                // currentCap>=subtractedCap, no way for underflow
                newCap = currentCap - subtractedCap;
            }
        }
        authorizedCaps[msg.sender][owner][authorized] = newCap;
        emit DecreaseAuthorizedCap(msg.sender, owner, authorized, newCap);
        return newCap;
    }

    function isAuthorized(address client, address owner, address authorized) public view returns (bool)
    {
        return authorizedCaps[client][owner][authorized] > 0;
    }

    function revokeAuthorization(address owner, address authorized) public
        currentlyAuthorized(msg.sender, owner, authorized)
    {
        delete authorizedCaps[msg.sender][owner][authorized];
        emit RevokeAuthorization(msg.sender, owner, authorized);
    }

    function approveFor(address owner, address authorized, address spender, uint256 amount) public
        currentlyAuthorized(msg.sender, owner, authorized)
        validCapAmount(amount)
    {
        // require(isRegistered(msg.sender), "Contract not registered to authorize");
        if ((spender == authorized) || (spender == owner))
        {
            revert InvalidSpender(spender);
        }
        // ERC20 allows to approve more than owner balance, fails only during transfer. So leave this error check out
        //require(IERC20(msg.sender).balanceOf(owner) >= amount, "Owner doesn't have enough balance");
        uint256 currentCap = getAuthorizedCap(msg.sender, owner, authorized);
        if (currentCap < amount)
        {
            revert InsufficientAuthorizedCap(
                msg.sender, owner, authorized, currentCap, amount);
        }
        decreaseAuthorizedCap(owner, authorized, amount);
        emit ApproveFor(msg.sender, owner,  authorized, amount);
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
