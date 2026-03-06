// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

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

    // Cap = 0 is the default and means no authorization. Usage: authorizerCaps[owner][authorizer]
    mapping(address => mapping(address => mapping(address => uint256))) public authorizerCaps;


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

    /// authorize docstring - assuming addr is the address of the token contract
    function authorize(address addr, address authorized, uint256 cap) public
    {
        // require the call to be from a registered client
        require(msg.sender != authorized, "Self authorization is prohibited");
        require(cap > 0, "Cap cannot be empty");
        require(IERC20(addr).balanceOf(msg.sender) >= cap, "Cannot authorize more than balance");
        require(authorizerCaps[addr][msg.sender][authorized] == 0, "authorized address already authorized, call increaseAuthorizerCap/decreaseAuthorizerCap");
        authorizerCaps[addr][msg.sender][authorized] = cap;
        // TODO: approve authorizer
    }

    /// This is the read function
    function getAuthorizerCap(address addr, address owner, address authorized) view public returns (uint256)
    {
        return authorizerCaps[addr][owner][authorized];
    }

    function increaseAuthorizerCap(address authorizer, uint256 addedCap) public
    {

    }

    function decreaseAuthorizerCap(address authorizer, uint256 subtractedCap) public
    {

    }

    function revokeAuthorizer(address authorizer) public
    {

    }

    /// Should be called by authorizer
    function approveFor(address owner, address spender, uint256 amount) public
    {

    }

    // Supports approving multiple spenders in a single transaction
    function approveFor(address owner, address[] memory spenders, uint256[] memory amounts) public
    {

    }
}
