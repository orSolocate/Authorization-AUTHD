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
        _mint(msg.sender, INITIAL_AUTHD_SUPPLY);
    }

    // for E: Your code here


    /*
     * INTERFACE FUNCTIONS (this is a placeholder to avoid merge conflicts
     */

    // TODO: use custom errors instead of `require` to reduce code size

    event Authorization(address indexed, address indexed, address, uint256);

    modifier validCap(address addr, uint256 cap)
    {
        require(cap > 0, "Cap amount cannot be empty");
        _;
    }

    modifier isAuthorized(address addr, address authorized)
    {
        require(isAuthorizedByMe(addr, authorized), "Address not authorized");
        _;
    }

    /// authorize docstring - assuming addr is the address of the token contract
    function authorize(address addr, address authorized, uint256 cap) public validCap(addr, cap)
    {
        // require the call to be from a registered client
        require(msg.sender != authorized, "Self authorization is prohibited");
        require(!isAuthorizedByMe(addr, authorized), "Address already authorized, call increase/decrease instead");
        require(IERC20(addr).balanceOf(msg.sender) >= cap, "Cannot authorize more than balance");
        authorizedCaps[addr][msg.sender][authorized] = cap;
        emit Authorization(addr, msg.sender, authorized, cap);
        // TODO: approve authorized address on client
    }

    /// This is the read function
    function getAuthorizedCap(address addr, address owner, address authorized) view public returns (uint256)
    {
        return authorizedCaps[addr][owner][authorized];
    }

    function increaseAuthorizedCap(address addr, address authorized, uint256 addedCap) public
        isAuthorized(addr, authorized)
        validCap(addr, addedCap)
    {
        uint256 currentCap = authorizedCaps[addr][msg.sender][authorized];
        unchecked
        {
            uint256 newCap = currentCap + addedCap;
            if (newCap < currentCap)
            {
                // Overflow occurred
                newCap = type(uint256).max;
            }
            require(IERC20(addr).balanceOf(msg.sender) >= newCap, "Cannot authorize more than balance");
            authorizedCaps[addr][msg.sender][authorized] = newCap;
        }
    }

    function decreaseAuthorizedCap(address addr, address authorized, uint256 subtractedCap) public
        isAuthorized(addr, authorized)
        validCap(addr, subtractedCap)
    {
        uint256 currentCap = authorizedCaps[addr][msg.sender][authorized];
        if (subtractedCap >= currentCap)
        {
            authorizedCaps[addr][msg.sender][authorized] = 0;
        }
        else
        {
            unchecked
            {
                // currentCap>=subtractedCap, no way for underflow
                authorizedCaps[addr][msg.sender][authorized] -= subtractedCap;
            }
        }
    }

    function isAuthorizedByMe(address addr, address authorized) public view returns (bool)
    {
        return authorizedCaps[addr][msg.sender][authorized] > 0;
    }

    function revokeAuthorization(address addr, address authorized) public
    {
        require(isAuthorizedByMe(addr, authorized), "Cannot revoke authorization without authorizing first");
        delete authorizedCaps[addr][msg.sender][authorized];
    }

    /// Should be called by authorized
    function approveFor(address owner, address spender, uint256 amount) public
    {

    }

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address[] memory spenders, uint256[] memory amounts) public
    {

    }
}
