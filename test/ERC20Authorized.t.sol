// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Authorized} from "../contracts/ERC20Authorized.sol";

interface IERC20AuthorizedEvents
{
    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
}

contract ERC20AuthorizedTest is Test, IERC20AuthorizedEvents
{
    ERC20Authorized public erc20Authorized;
    ERC20Authorized public customToken1;
    ERC20Authorized public customToken2;
    address internal owner = makeAddr("Owner-address");
    address internal authorized1 = makeAddr("Authorized-address-1");
    address internal authorized2 = makeAddr("Authorized-address-2");

    function setUp() public
    {
        erc20Authorized = new ERC20Authorized();
        customToken1 = new ERC20Authorized();
        customToken2 = new ERC20Authorized();
        // more setup to register ERC20AuthorizedTest
    }

    // MIGHT BE USEFUL later:
    //        customToken1.transfer(owner, 50);
    //        assertEq(customToken1.balanceOf(owner), 50);

    function test_selfAuthorize() external
    {
        deal(address(customToken1), owner, 50);
        assertEq(customToken1.balanceOf(owner), 50);
        vm.prank(owner);
        // Trying to self authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken1), owner, 50);
    }

    function test_authorizeMoreThanBalance() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken1), authorized1, 100);
    }

    function test_authorizeEmptyCap() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken1), authorized1, 0);
    }

    function test_authorizeTwice() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 20);
        // Verify cannot authorize twice
        vm.prank(owner);
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken1), authorized1, 10);
    }

    function test_authorize() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        // Verify cap updates
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 50, "Cap should updated after authorizing");
        // Verify authorization automatically approves authorized
        //assertEq(customToken.allowance(owner, authorized1), 50, "Authorization should approve authorized");
    }

    function test_authorizeEventEmitted() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit Authorization(address(customToken1), owner, authorized1, 50);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
    }

    function test_authorizeDouble() external
    {
        deal(address(customToken1), owner, 100);
        vm.prank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 60);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60, "Cap should updated after authorizing");

        vm.prank(owner);
        // Verify the authorization cap depends on owner's balance, and not on other authorization caps
        erc20Authorized.authorize(address(customToken1), authorized2, 100);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized2), 100, "Cap should updated after authorizing");
    }

    function test_revokeUnauthorized() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(owner);
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
    }

    function test_revokeAuthorization() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));

        // Verify revoke works
        vm.expectEmit(true, true, false, true);
        emit RevokeAuthorization(address(customToken1), owner, authorized1);
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        assertFalse(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));

        // Verify re-authorization works
        erc20Authorized.authorize(address(customToken1), authorized1, 20);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 20, "Cap should updated after authorizing");
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
    }

    function test_revokeTwice() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
    }

    function test_authorizedOnTwoAddresses() external
    {
        deal(address(customToken1), owner, 100);
        assertEq(customToken1.balanceOf(owner), 100);
        deal(address(customToken2), owner, 200);
        assertEq(customToken2.balanceOf(owner), 200);

        // Authorization effects only the customToken it was authorized on
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 100);
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
        assertFalse(erc20Authorized.isAuthorizedByMe(address(customToken2), authorized1));

        // Cannot revoke authorization of other customToken (mimics call from customToken2)
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(address(customToken2), authorized1);

        // Balance is kept separate
        erc20Authorized.authorize(address(customToken2), authorized1, 200);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 100, "Cap should updated after authorizing");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken2), owner, authorized1), 200, "Cap should updated after authorizing");

        // Cannot re-authorization only enabled under the revoked customToken
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        assertFalse(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken2), authorized1));
        vm.expectRevert();
        erc20Authorized.authorize(address(customToken2), authorized1, 200);

        erc20Authorized.authorize(address(customToken1), authorized1, 100);
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken2), authorized1));

        // Re-authorization applies only to the customToken specified
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        erc20Authorized.revokeAuthorization(address(customToken2), authorized1);
        erc20Authorized.authorize(address(customToken1), authorized1, 100);
        assertTrue(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
        assertFalse(erc20Authorized.isAuthorizedByMe(address(customToken2), authorized1));
    }

    function test_increaseUnauthorized() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 50);

        erc20Authorized.authorize(address(customToken1), authorized1, 100);
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 50);
    }

    function test_decreaseUnauthorized() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, 50);
        erc20Authorized.authorize(address(customToken1), authorized1, 100);
        erc20Authorized.revokeAuthorization(address(customToken1), authorized1);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, 50);
    }

    function test_increaseEmptyAmount() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 0);
    }

    function test_decreaseEmptyAmount() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, 0);
    }

    function test_increaseMoreThanBalance() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 60);
        // Increase on exact balance is allowed
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 50);
    }

    function test_increaseDecreaseAuthorizedCap() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 10);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 10, "Cap should updated after authorizing");
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 60);
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 50);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60, "Cap should updated after increase");
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 80);
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, 20);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 80, "Cap should updated after increase");

        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 30);
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, 50);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 30, "Cap should updated after decrease");
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 20);
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, 10);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 20, "Cap should updated after decrease");
    }

    function test_increaseOverflow() external
    {
        uint256 maxInt = type(uint256).max;
        deal(address(customToken1), owner, maxInt);
        assertEq(customToken1.balanceOf(owner), maxInt);

        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, 50);
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, maxInt);
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, maxInt);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), maxInt, "Cap should clip overflow to maxInt on increase");
    }

    function test_decreaseUnderflow() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, amount / 2);
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 0);
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, amount / 2);

        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should decrease");
    }

    function test_decreaseToZero() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, 100);
        vm.startPrank(owner);
        erc20Authorized.authorize(address(customToken1), authorized1, amount / 2);
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, amount);
        // Decrease to 0 un-authorizes
        assertFalse(erc20Authorized.isAuthorizedByMe(address(customToken1), authorized1));
        // Cannot increase/decrease after decrease to 0
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(address(customToken1), authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(address(customToken1), authorized1, amount / 2);
    }
}