// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Authorized} from "../contracts/ERC20Authorized.sol";

contract ERC20AuthorizedTest is Test
{
    ERC20Authorized public erc20Authorized;
    ERC20Authorized public customToken;
    address internal user1 = 0x5B38dA6a701C568545DCFcb03FCB0bedeC5DCcE5;

    function setUp() public
    {
        erc20Authorized = new ERC20Authorized();
        customToken = new ERC20Authorized();
        // more setup to register ERC20AuthorizedTest
    }

    function test_selfAuthorize() external
    {
        customToken.transfer(user1, 50);
        assertEq(customToken.balanceOf(user1), 50);
        vm.prank(user1);
        // Trying to self authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken), user1, 50);
    }

    function test_authorizeMoreThanBalance() external
    {
        customToken.transfer(user1, 50);
        assertEq(customToken.balanceOf(user1), 50);
        vm.prank(user1);
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken), address(this), 100);
    }

    function test_authorizeEmptyCap() external
    {
        customToken.transfer(user1, 50);
        assertEq(customToken.balanceOf(user1), 50);
        vm.prank(user1);
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken), address(this), 0);
    }

    function test_authorize() external
    {
        customToken.transfer(user1, 50);
        assertEq(customToken.balanceOf(user1), 50);
        vm.prank(user1);
        erc20Authorized.authorize(address(customToken), address(this), 50);
        // Verify cap updates
        assertEq(erc20Authorized.getAuthorizerCap(address(customToken), user1, address(this)), 50, "Cap should updated after authorizing");
        // Verify authorization automatically approves authorized
        //assertEq(customToken.allowance(user1, address(this)), 50, "Authorization should approve authorized");
    }
}