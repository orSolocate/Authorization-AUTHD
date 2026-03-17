// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
// import {Vm} from "forge-std/Vm.sol";
import {DemoClient} from "./DemoClient.sol";
import {ERC20Authorized} from "../contracts/ERC20Authorized.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20AuthorizedEvents
{
    event Authorization(address indexed, address indexed, address, uint256);
    event RevokeAuthorization(address indexed, address indexed, address);
    event IncreaseAuthorizedCap(address indexed, address indexed, address, uint256);
    event DecreaseAuthorizedCap(address indexed, address indexed, address, uint256);
   event ApproveFor(address indexed, address indexed, address, address, uint256);
}

contract AuthorizedClientTest is Test, IERC20AuthorizedEvents
{
    ERC20Authorized public authorizedServer;
    DemoClient public demoClient1;
    // ERC20AuthorizedClient public demoClient2;
    address internal owner = makeAddr("Owner-address");
    address internal authorized1 = makeAddr("Authorized-address-1");
    address internal authorized2 = makeAddr("Authorized-address-2");
    address internal spender1 = makeAddr("Spender-address-1");
    address internal spender2 = makeAddr("Spender-address-2");

    function setUp() public
    {
        authorizedServer = new ERC20Authorized();
        demoClient1 = new DemoClient(address(authorizedServer));
        uint256 registrationFee = demoClient1.getRegistrationFee();
        vm.deal(address(this), registrationFee);
        demoClient1.registerClient{value: registrationFee}();
    }

    function test_authorize() external
    {
        deal(address(demoClient1), owner, 50);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval( owner,  authorized1, 25);
        vm.expectEmit(true, true, false, true);
        emit Authorization(address(demoClient1), owner, authorized1, 25);
        demoClient1.authorize(authorized1, 25);
        assertTrue(demoClient1.isAuthorized(authorized1));
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 25, "Cap should update after authorize");
        // Verify authorized address calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 25, "Authorized should be approved on the authorized cap");
    }

    function test_increaseAuthorizedCap() external
    {
        deal(address(demoClient1), owner, 50);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 25);

        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval( owner,  authorized1, 45);
        vm.expectEmit(true, true, false, true);
        emit IncreaseAuthorizedCap(address(demoClient1), owner, authorized1, 45);
        demoClient1.increaseAuthorizedCap(authorized1, 20);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 45, "Cap should update after increase");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 45, "Authorized should be approved on the updated authorized cap");
    }

    function test_increaseOverflow() external
    {
        uint256 maxInt = type(uint256).max;
        deal(address(demoClient1), owner, maxInt);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 100);
        demoClient1.increaseAuthorizedCap(authorized1, maxInt);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), maxInt, "Cap should update after increase");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), maxInt, "Authorized should be approved on the updated authorized cap");
    }

    function test_decreaseAuthorizedCap() external
    {
        deal(address(demoClient1), owner, 50);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 25);

        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval( owner,  authorized1, 10);
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(demoClient1), owner, authorized1, 10);
        demoClient1.decreaseAuthorizedCap(authorized1, 15);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 10, "Cap should update after decrease");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 10, "Authorized should be approved on the updated authorized cap");
    }

    function test_decreaseUnderflow() external
    {
        deal(address(demoClient1), owner, 50);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 50);
        demoClient1.decreaseAuthorizedCap(authorized1, 100);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 0, "Cap should update after decrease");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 0, "Authorized should be approved on the updated authorized cap");
    }

    function test_revokeAuthorization() external
    {
        deal(address(demoClient1), owner, 50);
        vm.prank(owner);
        demoClient1.authorize(authorized1, 50);
        // Only owner can revoke their authorizations
        vm.prank(authorized2);
        vm.expectRevert();
        demoClient1.revokeAuthorization(authorized1);
        vm.startPrank(owner);
        vm.expectEmit(true, true, false, true);
        emit RevokeAuthorization(address(demoClient1), owner, authorized1);
        demoClient1.revokeAuthorization(authorized1);
        assertFalse(demoClient1.isAuthorized(authorized1), "Revoking should un-authorize");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 0, "Revoked should not be approved on any amount");
        vm.expectRevert();
        demoClient1.decreaseAuthorizedCap(authorized1, 50);
        vm.expectRevert();
        demoClient1.increaseAuthorizedCap(authorized1, 50);
        vm.stopPrank();
        vm.prank(authorized1);
        vm.expectRevert();
        demoClient1.approveFor(owner,  spender1, 20);
    }

    function test_approveFor() external
    {
        deal(address(demoClient1), owner, 50);
        vm.prank(owner);
        demoClient1.authorize(authorized1, 25);

        vm.prank(authorized1);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval( owner,  authorized1, 10);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval( owner,  spender1, 15);
        vm.expectEmit(true, true, false, true);
        emit DecreaseAuthorizedCap(address(demoClient1), owner, authorized1,10);
        vm.expectEmit(true, true, false, true);
        emit ApproveFor(address(demoClient1), owner, authorized1, spender1, 15);
        demoClient1.approveFor(owner, spender1, 15);
        vm.prank(owner);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 10, "Cap should update after approve");
        // Verify authorized address increase calls ERC20's approval
        assertEq(demoClient1.allowance(owner, authorized1), 10, "Authorized should be approved on the updated authorized cap");
        assertEq(demoClient1.allowance(owner, spender1), 15, "Spender allowance should be updated");
    }

    function test_approveForMoreThanCap() external
    {
        deal(address(demoClient1), owner, 50);
        vm.prank(owner);
        demoClient1.authorize(authorized1, 25);

        vm.prank(authorized1);
        vm.expectRevert();
        demoClient1.approveFor(owner, spender1, 40);
    }

    function test_revokeAfterApproveFor() external
    {
        deal(address(demoClient1), owner, 50);
        vm.prank(owner);
        demoClient1.authorize(authorized1, 50);
        vm.prank(authorized1);
        demoClient1.approveFor(owner, spender1, 10);
        vm.prank(owner);
        demoClient1.revokeAuthorization(authorized1);
        // Verify already approves allowances are intact after revoke
        assertEq(demoClient1.allowance(owner, authorized1), 0, "Authorized should be revoked");
        assertEq(demoClient1.allowance(owner, spender1), 10, "Spender allowance should be updated");
        vm.prank(authorized1);
        vm.expectRevert();
        demoClient1.approveFor(owner, spender1, 10);
    }

    function test_approveForTwoAuthorizersSameSpender() external
    {
        deal(address(demoClient1), owner, 200);
        vm.prank(owner);
        demoClient1.authorize(authorized1, 100);
        vm.prank(owner);
        demoClient1.authorize(authorized2, 100);
        vm.prank(authorized1);
        demoClient1.approveFor(owner, spender1, 50);
        vm.prank(authorized2);
        demoClient1.approveFor(owner, spender1, 75);
        vm.startPrank(owner);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 50, "Cap should update after approve");
        assertEq(demoClient1.GetAuthorizedCap(authorized2), 25, "Cap should update after approve");
        assertEq(demoClient1.allowance(owner, authorized1), 50, "Authorized1 allowance should be updated");
        assertEq(demoClient1.allowance(owner, authorized2), 25, "Authorized2 allowance should be updated");
        assertEq(demoClient1.allowance(owner, spender1), 75, "Spender allowance should be updated according the most recent approval");
    }

    function test_approveForMultipleInvalidSpendersOrAmounts() external
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
        spenders[0] = spender1;
        spenders[1] = spender2;

        deal(address(demoClient1), owner, amount);
        vm.prank(owner);
        demoClient1.authorize(authorized1, amount);
        vm.startPrank(authorized1);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner,  spendersEmpty, amounts);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner, spenders, amountsEmpty);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner, spenders, amountsDiffLength);
    }

    function test_approveForMultipleConstraintsForEachSpender() external
    {
        uint256 amount = 100;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 2;
        uint256[] memory amountsWithEmpty = new uint256[](2);
        amountsWithEmpty[0] = amount / 2;
        amountsWithEmpty[1] = 0;
        address[] memory spendersWithOwner = new address[](2);
        spendersWithOwner[0] = spender1;
        spendersWithOwner[1] = owner;
        address[] memory spendersWithAuthorized = new address[](2);
        spendersWithAuthorized[0] = authorized2;
        spendersWithAuthorized[1] = spender2;
        address[] memory spenders = new address[](2);
        spenders[0] = spender1;
        spenders[1] = spender2;

        deal(address(demoClient1), owner, amount);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, amount);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner, spenders, amountsWithEmpty);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner, spendersWithOwner, amounts);
        vm.expectRevert();
        demoClient1.approveForMultiple(owner, spendersWithAuthorized, amounts);
    }

    function test_approveForMultiple() external
    {
        uint256 amount = 100;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 4;
        address[] memory spenders = new address[](2);
        spenders[0] = spender1;
        spenders[1] = spender2;

        deal(address(demoClient1), owner, amount);
        vm.prank(owner);
        demoClient1.authorize(authorized1, amount);
        vm.prank(authorized1);
        demoClient1.approveForMultiple(owner, spenders, amounts);
        vm.prank(owner);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), amount / 4, "Cap should update after approve");
        assertEq(demoClient1.allowance(owner, authorized1), amount / 4, "Authorized1 allowance should be updated");
        assertEq(demoClient1.allowance(owner, spender1), amount / 2, "Spender1 allowance should be updated");
        assertEq(demoClient1.allowance(owner, spender2), amount / 4, "Spender2 allowance should be updated");
    }

    function test_approveForMultipleSameSpenders() external
    {
        uint256 amount = 100;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount / 2;
        amounts[1] = amount / 4;
        address[] memory spenders = new address[](2);
        spenders[0] = spender1;
        spenders[1] = spender1;

        deal(address(demoClient1), owner, amount);
        vm.prank(owner);
        demoClient1.authorize(authorized1, amount);
        vm.prank(authorized1);
        demoClient1.approveForMultiple(owner, spenders, amounts);
        vm.prank(owner);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), amount / 4, "Cap should update after approve");
        assertEq(demoClient1.allowance(owner, authorized1), amount / 4, "Authorized1 allowance should be updated");
        assertEq(demoClient1.allowance(owner, spender1), amount / 4, "Spender allowance should be updated according the most recent approval");
    }

    function test__update() external
    {
        deal(address(demoClient1), owner, 200);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 100);
        demoClient1.authorize(authorized2, 200);
        demoClient1.transfer(address(this), 50);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 100, "Cap should not update if not needed after transfer");
        assertEq(demoClient1.allowance(owner, authorized1),100, "Authorized1 allowance should not be updated");
        assertEq(demoClient1.GetAuthorizedCap(authorized2), 150, "Cap should update after transfer");
        assertEq(demoClient1.allowance(owner, authorized2), 150, "Authorized2 allowance should be updated");
        vm.stopPrank();
        vm.prank(authorized1);
        demoClient1.approveFor(owner, spender1, 60);
        vm.startPrank(owner);
        demoClient1.transfer(address(this), 100);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 40, "Cap should not be needed after transfer");
        assertEq(demoClient1.allowance(owner, authorized1),40, "Authorized1 allowance shouldn't be updated");
        assertEq(demoClient1.GetAuthorizedCap(authorized2), 50, "Cap should update after transfer to owner's balance");
        assertEq(demoClient1.allowance(owner, authorized2), 50, "Authorized2 allowance should be updated to owner's balance");
        assertEq(demoClient1.allowance(owner, spender1), 60, "spender allowance should not be updated during _update");
    }

    function test__updateOnBurn() external
    {
        deal(address(demoClient1), owner, 200);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 100);
        demoClient1.burn(150);
        assertEq(demoClient1.GetAuthorizedCap(authorized1), 50, "Cap should update after burn");
        assertEq(demoClient1.allowance(owner, authorized1),50, "Authorized1 allowance should be updated");
    }

    function test__updateWithRevokedAuthorizer() external
    {
        deal(address(demoClient1), owner, 200);
        vm.startPrank(owner);
        demoClient1.authorize(authorized1, 100);
        demoClient1.authorize(authorized2, 200);
        demoClient1.revokeAuthorization(authorized1);
        // Verify there is no issue with revoked authorizer
        demoClient1.transfer(address(this), 120);
        assertFalse(demoClient1.isAuthorized(authorized1));
        assertEq(demoClient1.GetAuthorizedCap(authorized2), 80, "Cap should update after transfer");
        assertEq(demoClient1.allowance(owner, authorized2), 80, "Authorized2 allowance should be updated");
    }

    function test_registerClientNotRegistered() external
    {
        DemoClient demoClient2 = new DemoClient(address(authorizedServer));
        uint256 registrationFee = demoClient2.getRegistrationFee();
        vm.deal(address(this), 9 * registrationFee / 10);
        vm.expectRevert();
        demoClient2.registerClient{value: 9 * registrationFee / 10}();
        deal(address(demoClient2), owner, 200);
        vm.startPrank(owner);
        vm.expectRevert();
        demoClient2.authorize(authorized1, 50);
        vm.expectRevert();
        demoClient2.increaseAuthorizedCap(authorized1, 50);
        vm.expectRevert();
        demoClient2.decreaseAuthorizedCap(authorized1, 50);
        vm.expectRevert();
        demoClient2.decreaseAuthorizedCap(authorized1, 50);
        assertFalse(demoClient2.isRegisteredClient());
        assertTrue(demoClient1.isRegisteredClient());
    }
}
