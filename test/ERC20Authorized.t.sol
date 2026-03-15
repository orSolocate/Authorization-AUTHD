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
    event ApproveFor(address indexed, address indexed, address, uint256);
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


    function test_authorizeInvalidAddress() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        // Trying to authorize zero address
        vm.expectRevert();
        erc20Authorized.authorize(owner, address(0), 50);
        // Trying to authorize from the zero address
        vm.expectRevert();
        erc20Authorized.authorize(address(0), authorized1, 50);
    }

    function test_selfAuthorize() external
    {
        deal(address(customToken1), owner, 50);
        assertEq(customToken1.balanceOf(owner), 50);
        vm.prank(address(customToken1));
        // Trying to self authorize
        vm.expectRevert();
        erc20Authorized.authorize(owner, owner, 50);
    }

    function test_authorizeMoreThanBalance() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(owner, authorized1, 100);
    }

    function test_authorizeEmptyCap() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        // Not enough tokens to authorize
        vm.expectRevert();
        erc20Authorized.authorize(owner, authorized1, 0);
    }

    function test_authorizeTwice() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 20);
        // Verify cannot authorize twice
        vm.expectRevert();
        erc20Authorized.authorize(owner, authorized1, 10);
    }

    function test_authorize() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        // Verify cap updates
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 50, "Cap should updated after authorizing");
        // TODO: Move to Client tests
        // Verify authorization automatically approves authorized
        //assertEq(customToken.allowance(owner, authorized1), 50, "Authorization should approve authorized");
    }

    function test_authorizeEventEmitted() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        vm.expectEmit(true, true, false, true);
        emit Authorization(address(customToken1), owner, authorized1, 50);
        erc20Authorized.authorize(owner, authorized1, 50);
    }

    function test_authorizeDouble() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 60);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60, "Cap should updated after authorizing");

        // Verify the authorization cap depends on owner's balance, and not on other authorization caps
        erc20Authorized.authorize(owner, authorized2, 100);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized2), 100, "Cap should updated after authorizing");
    }

    function test_revokeUnauthorized() external
    {
        deal(address(customToken1), owner, 50);
        vm.prank(address(customToken1));
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(owner, authorized1);
    }

    function test_revokeAuthorization() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));

        // Verify revoke works
        vm.expectEmit(true, true, false, true);
        emit RevokeAuthorization(address(customToken1), owner, authorized1);
        erc20Authorized.revokeAuthorization(owner, authorized1);
        assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));

        // Verify re-authorization works
        erc20Authorized.authorize(owner, authorized1, 20);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 20, "Cap should updated after authorizing");
    }

    function test_revokeTwice() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        erc20Authorized.revokeAuthorization(owner, authorized1);
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(owner, authorized1);
    }

    function test_authorizedOnTwoAddresses() external
    {
        deal(address(customToken1), owner, 100);
        assertEq(customToken1.balanceOf(owner), 100);
        deal(address(customToken2), owner, 200);
        assertEq(customToken2.balanceOf(owner), 200);

        // Authorization effects only the customToken it was authorized on
        vm.prank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 100);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertFalse(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));

        // Cannot revoke authorization from customToken2
        vm.prank(address(customToken2));
        vm.expectRevert();
        erc20Authorized.revokeAuthorization(owner, authorized1);

        // Balance is kept separate
        vm.prank(address(customToken2));
        erc20Authorized.authorize(owner, authorized1, 200);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 100, "Cap should updated after authorizing");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken2), owner, authorized1), 200, "Cap should updated after authorizing");

        // Cannot re-authorization only enabled under the revoked customToken
        vm.prank(address(customToken1));
        erc20Authorized.revokeAuthorization(owner, authorized1);
        assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertTrue(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));
        vm.prank(address(customToken2));
        vm.expectRevert();
        erc20Authorized.authorize(owner, authorized1, 200);

        vm.prank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 100);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertTrue(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));

        // Re-authorization applies only to the customToken specified
        vm.prank(address(customToken1));
        erc20Authorized.revokeAuthorization(owner, authorized1);
        vm.prank(address(customToken2));
        erc20Authorized.revokeAuthorization(owner, authorized1);
        vm.prank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 100);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertFalse(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));
    }

    function test_increaseUnauthorized() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 50);

        erc20Authorized.authorize(owner, authorized1, 100);
        erc20Authorized.revokeAuthorization(owner, authorized1);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 50);
    }

    function test_decreaseUnauthorized() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 50);
        erc20Authorized.authorize(owner, authorized1, 100);
        erc20Authorized.revokeAuthorization(owner, authorized1);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 50);
    }

    function test_increaseEmptyAmount() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 0);
    }

    function test_decreaseEmptyAmount() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 0);
    }

    function test_increaseMoreThanBalance() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 60);
        // Increase on exact balance is allowed
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 50);
    }

    function test_increaseDecreaseAuthorizedCap() external
    {
        deal(address(customToken1), owner, 100);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 10);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 10, "Cap should updated after authorizing");
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 60);
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 50);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60, "Cap should updated after increase");
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 80);
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 20);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 80, "Cap should updated after increase");
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 30);
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 50);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 30, "Cap should updated after decrease");
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 20);
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 10);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 20, "Cap should updated after decrease");
    }

    function test_increaseOverflow() external
    {
        uint256 maxInt = type(uint256).max;
        deal(address(customToken1), owner, maxInt);
        assertEq(customToken1.balanceOf(owner), maxInt);

        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 50);
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(customToken1), owner, authorized1, maxInt);
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, maxInt);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), maxInt, "Cap should clip overflow to maxInt on increase");
    }

    function test_decreaseUnderflow() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 0);
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount / 2);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should decrease");
    }

    function test_decreaseToZero() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount);
        // Decrease to 0 un-authorizes
        assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        // Cannot increase/decrease after decrease to 0
        vm.expectRevert();
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount / 2);
    }

    function test_approveForUnauthorized() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.prank(address(customToken1));
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, authorized2, amount / 2);
    }

    function test_approveForInvalidSpender() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, address(0), amount / 2);
    }

    function test_approveForSpenderIsOwner() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, owner, amount / 2);
    }

    function test_approveForSelfApproval() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, authorized1, amount / 2);
    }

    function test_approveForEmptyAmount() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, authorized2, 0);
    }

    function test_approveForAmountMoreThanCap() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, authorized2, amount);
    }

    function test_approveFor() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount);
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(customToken1), owner,  authorized1, 3 * amount / 4);
        vm.expectEmit(true, true, false, true);
        emit ApproveFor(address(customToken1), owner,  authorized1, amount / 4);
        erc20Authorized.approveFor(owner, authorized1, authorized2, amount / 4);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 3 * amount / 4, "Cap should updated after approveFor");
    }

    function test_approveForAllAmount() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        erc20Authorized.approveFor(owner, authorized1, authorized2, amount);
        assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
    }

    function test_approveForSameSpenderTwoAuthorizers() external
    {
        deal(address(customToken1), owner, 300);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 100);
        erc20Authorized.authorize(owner, authorized2, 200);
        erc20Authorized.approveFor(owner, authorized1, authorized2, 50);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 50, "Cap should updated after approveFor");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized2), 200, "Cap should updated after approveFor");
        erc20Authorized.approveFor(owner, authorized2, authorized1, 170);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 50, "Cap should updated after approveFor");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized2), 30, "Cap should updated after approveFor");
    }

    /*
    // TODO: Consider moving this functionality to Client
    function test_approveForEmptySpendersOrAmounts() external
    {
        uint256 amount = 100;
        uint256[] memory amountsEmpty = new uint256[](0);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 2;
        uint256[] memory amountsDiffLength =  new uint256[](1);
        amountsDiffLength[0] = amount / 2;
        address[] memory spendersEmpty = new address[](0);
        address[] memory spenders = new address[](2);
        spenders[0] = authorized2;
        spenders[1] = authorized2;

        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spendersEmpty, amounts);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spenders, amountsEmpty);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spenders, amountsDiffLength);
    }

    // TODO: Consider moving this functionality to Client
    function test_approveForConstraintsForEachSpender() external
    {
        uint256 amount = 100;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 2;
        uint256[] memory amountsWithEmpty = new uint256[](2);
        amountsWithEmpty[0] = amount / 2;
        amountsWithEmpty[1] = 0;
        address[] memory spendersWithOwner = new address[](2);
        spendersWithOwner[0] = authorized2;
        spendersWithOwner[1] = owner;
        address[] memory spendersWithAuthorized = new address[](2);
        spendersWithAuthorized[0] = authorized2;
        spendersWithAuthorized[1] = authorized1;
        address[] memory spenders = new address[](2);
        spenders[0] = authorized2;
        spenders[1] = authorized2;

        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spenders, amountsWithEmpty);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spendersWithOwner, amounts);
        vm.expectRevert();
        erc20Authorized.approveFor(owner, authorized1, spendersWithAuthorized, amounts);
    }

    // TODO: Consider moving this functionality to Client
    function test_approveForSameSpenders() external
    {
        uint256 amount = 100;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 4;
        address[] memory spenders = new address[](2);
        spenders[0] = authorized2;
        spenders[1] = authorized2;

        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount);
        erc20Authorized.approveFor(owner, authorized1, spenders, amounts);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), amount / 4, "Cap should updated after approveFor");
    }
    */
}