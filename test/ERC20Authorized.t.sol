// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20Authorized} from "../contracts/ERC20Authorized.sol";
import {IERC20Authorized} from "../contracts/interfaces/IERC20Authorized.sol";
import {ERC20AuthorizedErrors} from "../contracts/ERC20AuthorizedErrors.sol";

contract ERC20AuthorizedTest is Test
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
        uint256 fee1 = erc20Authorized.getRegistrationFee();
        uint256 fee2 = erc20Authorized.getRegistrationFee();
        // Register both dummy client contracts so authorize/increase/decrease/etc can be called
        vm.deal(address(customToken1), fee1);
        vm.prank(address(customToken1));
        erc20Authorized.registerClient{value: fee1}();
        vm.deal(address(customToken2), fee2);
        vm.prank(address(customToken2));
        erc20Authorized.registerClient{value: fee2}();
    }

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
        erc20Authorized.authorize(owner, authorized1, 0);
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should updated after authorize");
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
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.Authorization(address(customToken1), owner, authorized1, 50);
        erc20Authorized.authorize(owner, authorized1, 50);
        // Verify cap updates
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 50, "Cap should updated after authorizing");
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

    function test_getAuthorizersList() external
    {
        deal(address(customToken1), owner, 50);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 10);
        erc20Authorized.authorize(owner, authorized2, 20);
        address[] memory authorizers =  new address[](2);
        authorizers[0] = authorized1;
        authorizers[1] = authorized2;
        assertEq(erc20Authorized.getAuthorizersList(address(customToken1), owner), authorizers);
        erc20Authorized.revokeAuthorization(owner, authorized1);
        delete authorizers;
        authorizers =  new address[](1);
        authorizers[0] = authorized2;
        assertEq(erc20Authorized.getAuthorizersList(address(customToken1), owner), authorizers);
    }

    function test_getOwnersList() external
    {
        address owner2 = makeAddr("Owner-address-2");
        deal(address(customToken1), owner, 50);
        deal(address(customToken1), owner2, 75);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, 10);
        erc20Authorized.authorize(owner2, authorized1, 20);
        erc20Authorized.authorize(owner, authorized2, 15);
        address[] memory ownersAuthorized1 =  new address[](2);
        ownersAuthorized1[0] = owner;
        ownersAuthorized1[1] = owner2;
        assertEq(erc20Authorized.getOwnersList(address(customToken1), authorized1), ownersAuthorized1);
        address[] memory ownersAuthorized2 =  new address[](1);
        ownersAuthorized2[0] = owner;
        assertEq(erc20Authorized.getOwnersList(address(customToken1), authorized2), ownersAuthorized2);
        // Verify owners list is updated after revoking authorization
        erc20Authorized.revokeAuthorization(owner, authorized1);
        delete ownersAuthorized1;
        ownersAuthorized1 =  new address[](1);
        ownersAuthorized1[0] = owner2;
        assertEq(erc20Authorized.getOwnersList(address(customToken1), authorized1), ownersAuthorized1);
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
        emit IERC20Authorized.RevokeAuthorization(address(customToken1), owner, authorized1);
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
        emit IERC20Authorized.IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 60);
        uint256 newCap = erc20Authorized.increaseAuthorizedCap(owner, authorized1, 50);
        assertEq(newCap, 60, "returned value from increase should be the new cap");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60, "Cap should updated after increase");
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.IncreaseAuthorizedCap(address(customToken1), owner, authorized1, 80);
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, 20);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 80, "Cap should updated after increase");
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 30);
        newCap = erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 50);
        assertEq(newCap, 30, "returned value from decrease should be the new cap");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 30, "Cap should updated after decrease");
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 20);
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
        emit IERC20Authorized.IncreaseAuthorizedCap(address(customToken1), owner, authorized1, maxInt);
        uint256 newCap = erc20Authorized.increaseAuthorizedCap(owner, authorized1, maxInt);
        assertEq(newCap, maxInt, "returned value from increase should be the new cap");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), maxInt, "Cap should clip overflow to maxInt on increase");
    }

    function test_decreaseUnderflow() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.DecreaseAuthorizedCap(address(customToken1), owner, authorized1, 0);
        uint256 newCap = erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount / 2);
        assertEq(newCap, 0, "returned value from decrease should be the new cap");
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should decrease");
    }

    function test_decreaseToZero() external
    {
        uint256 amount = 100;
        deal(address(customToken1), owner, amount);
        vm.startPrank(address(customToken1));
        erc20Authorized.authorize(owner, authorized1, amount / 2);
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount);
        // Decrease to 0 does not un-authorize
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should updated after decrease");
        // Can increase/decrease after decrease to 0
        erc20Authorized.increaseAuthorizedCap(owner, authorized1, amount / 2);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), amount / 2, "Cap should updated after increase");
        erc20Authorized.decreaseAuthorizedCap(owner, authorized1, amount / 2);
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should updated after decrease");
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
        vm.recordLogs();
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.ApproveFor(address(customToken1), owner,  authorized1, authorized2, 0);
        erc20Authorized.approveFor(owner, authorized1, authorized2, 0);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2, "Only 2 events should have been emitted");
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
        vm.recordLogs();
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.DecreaseAuthorizedCap(address(customToken1), owner,  authorized1, 3 * amount / 4);
        vm.expectEmit(true, true, false, true);
        emit IERC20Authorized.ApproveFor(address(customToken1), owner,  authorized1, authorized2, amount / 4);
        erc20Authorized.approveFor(owner, authorized1, authorized2, amount / 4);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 4, "Only 4 events should have been emitted");
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
        assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
        assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0, "Cap should updated after approveFor");
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

    function test_registerClientWorks() external
        {
            ERC20Authorized newClient = new ERC20Authorized();
            uint256 fee = erc20Authorized.getRegistrationFee();
            uint256 authdAmount = erc20Authorized.REGISTRATION_AUTHD_AMOUNT();
            vm.deal(address(newClient), fee);
            vm.startPrank(address(newClient));
            vm.expectEmit(true, false, false, true);
            emit IERC20Authorized.ClientRegistered(address(newClient),  fee, authdAmount);
            erc20Authorized.registerClient{value: fee}();

            assertTrue(erc20Authorized.isRegisteredClient(address(newClient)));
            assertEq(erc20Authorized.balanceOf(address(newClient)), authdAmount);
        }

    function test_registerClientRevertsIfZeroAddress() external
        {
            vm.deal(address(0), 0.01 ether);
            vm.startPrank(address(0));
            vm.expectRevert();
            erc20Authorized.registerClient{value: 0.01 ether}();
        }

    function test_registerClientRevertsIfAlreadyRegistered() external
        {
            vm.deal(address(customToken1), 0.01 ether);
            vm.startPrank(address(customToken1));
            vm.expectRevert();
            erc20Authorized.registerClient{value: 0.01 ether}();
        }

    function test_registerClientRevertsIfInsufficientFee() external {
            address client = makeAddr("client");
            uint256 fee = erc20Authorized.getRegistrationFee();
            vm.deal(client, fee - 1);
            vm.prank(client);
            vm.expectRevert(abi.encodeWithSelector(ERC20AuthorizedErrors.InsufficientRegistrationFee.selector, fee - 1, fee));
            erc20Authorized.registerClient{value: fee - 1}();
        }

    function test_isRegisteredClientWorks() external
        {
            assertTrue(erc20Authorized.isRegisteredClient(address(customToken1)));
            assertTrue(erc20Authorized.isRegisteredClient(address(customToken2)));

            ERC20Authorized unregisteredClient = new ERC20Authorized();
            assertFalse(erc20Authorized.isRegisteredClient(address(unregisteredClient)));
        }

    function test_revokeClientRegistrationRevertsForNonOwner() external
    {
        vm.prank(address(customToken1));
        vm.expectRevert();
        erc20Authorized.revokeClientRegistration(address(customToken2));
    }

    function test_revokeClientRegistrationRevertsIfClientNotRegistered() external
    {
        ERC20Authorized unregisteredClient = new ERC20Authorized();

        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20AuthorizedErrors.ClientNotRegistered.selector,
                address(unregisteredClient)
            )
        );
        erc20Authorized.revokeClientRegistration(address(unregisteredClient));
    }

    function test_revokeClientRegistrationWorks() external
    {
        vm.expectEmit(true, false, false, true);
        emit IERC20Authorized.ClientRegistrationRevoked(address(customToken1));

        erc20Authorized.revokeClientRegistration(address(customToken1));

        assertFalse(erc20Authorized.isRegisteredClient(address(customToken1)));
    }

    
    function test_authorizeRevertsIfClientNotRegistered() external
        {
            ERC20Authorized unregisteredClient = new ERC20Authorized();

            deal(address(unregisteredClient), owner, 50);

            vm.prank(address(unregisteredClient));
            vm.expectRevert();
            erc20Authorized.authorize(owner, authorized1, 20);
        }

    function test_increaseAuthorizedCapRevertsIfClientNotRegistered() external
        {
            ERC20Authorized unregisteredClient = new ERC20Authorized();

            deal(address(unregisteredClient), owner, 100);

            // even if the storage path exists conceptually, function should fail due to registration modifier
            vm.prank(address(unregisteredClient));
            vm.expectRevert();
            erc20Authorized.increaseAuthorizedCap(owner, authorized1, 20);
        }

    function test_decreaseAuthorizedCapRevertsIfClientNotRegistered() external
        {
            ERC20Authorized unregisteredClient = new ERC20Authorized();

            deal(address(unregisteredClient), owner, 100);

            vm.prank(address(unregisteredClient));
            vm.expectRevert();
            erc20Authorized.decreaseAuthorizedCap(owner, authorized1, 20);
        }

    function test_approveForRevertsIfClientNotRegistered() external
        {
            ERC20Authorized unregisteredClient = new ERC20Authorized();

            deal(address(unregisteredClient), owner, 100);

            vm.prank(address(unregisteredClient));
            vm.expectRevert();
            erc20Authorized.approveFor(owner, authorized1, authorized2, 20);
        }

    function test_withdrawTreasuryWorks() external {
            address payable treasuryReceiver = payable(makeAddr("treasuryReceiver"));

            vm.deal(address(erc20Authorized), 1 ether);

            uint256 beforeBalance = treasuryReceiver.balance;
            uint256 treasuryBalance = address(erc20Authorized).balance;

            vm.expectEmit(true, false, false, true, address(erc20Authorized));
            emit IERC20Authorized.TreasuryWithdrawal(treasuryReceiver, treasuryBalance);

            erc20Authorized.withdrawTreasury(treasuryReceiver);

            assertEq(address(erc20Authorized).balance, 0);
            assertEq(treasuryReceiver.balance, beforeBalance + treasuryBalance);
        }

    function test_withdrawTreasuryRevertsIfNotOwner() external
        {
            address payable treasuryReceiver = payable(makeAddr("treasuryReceiver"));
            address notOwner = makeAddr("notOwner");

            vm.prank(notOwner);
            vm.expectRevert();
            erc20Authorized.withdrawTreasury(treasuryReceiver);
        }

    function test_withdrawTreasuryRevertsIfNoBalance() external {
            address payable treasuryReceiver = payable(makeAddr("treasuryReceiver"));

            vm.deal(address(erc20Authorized), 0);

            vm.expectRevert(bytes("No ETH to withdraw"));
            erc20Authorized.withdrawTreasury(treasuryReceiver);
        }

    // function test_revokeClientRegistrationClearsAuthorizationState() external 
    // {
    //     deal(address(customToken1), owner, 100);
    //     deal(address(customToken2), owner, 200);

    //     vm.prank(address(customToken1));
    //     erc20Authorized.authorize(owner, authorized1, 60);

    //     vm.prank(address(customToken2));
    //     erc20Authorized.authorize(owner, authorized1, 150);

    //     assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 60);

    //     assertTrue(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken2), owner, authorized1), 150);

    //     address[] memory client1AuthorizersBefore = new address[](1);
    //     client1AuthorizersBefore[0] = authorized1;
    //     assertEq(
    //         erc20Authorized.getAuthorizersList(address(customToken1), owner),
    //         client1AuthorizersBefore
    //     );

    //     address[] memory client1OwnersBefore = new address[](1);
    //     client1OwnersBefore[0] = owner;
    //     assertEq(
    //         erc20Authorized.getOwnersList(address(customToken1), authorized1),
    //         client1OwnersBefore
    //     );

    //     erc20Authorized.revokeClientRegistration(address(customToken1));

    //     assertFalse(erc20Authorized.isRegisteredClient(address(customToken1)));
    //     assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0);
    //     assertEq(erc20Authorized.getAuthorizersList(address(customToken1), owner).length, 0);
    //     assertEq(erc20Authorized.getOwnersList(address(customToken1), authorized1).length, 0);

    //     assertTrue(erc20Authorized.isRegisteredClient(address(customToken2)));
    //     assertTrue(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken2), owner, authorized1), 150);

    //     address[] memory client2AuthorizersAfter = new address[](1);
    //     client2AuthorizersAfter[0] = authorized1;
    //     assertEq(
    //         erc20Authorized.getAuthorizersList(address(customToken2), owner),
    //         client2AuthorizersAfter
    //     );

    //     address[] memory client2OwnersAfter = new address[](1);
    //     client2OwnersAfter[0] = owner;
    //     assertEq(
    //         erc20Authorized.getOwnersList(address(customToken2), authorized1),
    //         client2OwnersAfter
    //     );
    // }

    // function test_revokeClientRegistrationAllowsReregistrationWithFreshState() external 
    // {
    //     deal(address(customToken1), owner, 100);
    //     deal(address(customToken2), owner, 200);

    //     vm.prank(address(customToken1));
    //     erc20Authorized.authorize(owner, authorized1, 50);

    //     vm.prank(address(customToken2));
    //     erc20Authorized.authorize(owner, authorized1, 125);

    //     erc20Authorized.revokeClientRegistration(address(customToken1));

    //     uint256 fee = erc20Authorized.getRegistrationFee();
    //     vm.deal(address(customToken1), fee);

    //     vm.prank(address(customToken1));
    //     erc20Authorized.registerClient{value: fee}();

    //     assertTrue(erc20Authorized.isRegisteredClient(address(customToken1)));
    //     assertFalse(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 0);
    //     assertEq(erc20Authorized.getAuthorizersList(address(customToken1), owner).length, 0);
    //     assertEq(erc20Authorized.getOwnersList(address(customToken1), authorized1).length, 0);

    //     assertTrue(erc20Authorized.isRegisteredClient(address(customToken2)));
    //     assertTrue(erc20Authorized.isAuthorized(address(customToken2), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken2), owner, authorized1), 125);

    //     vm.prank(address(customToken1));
    //     erc20Authorized.authorize(owner, authorized1, 25);

    //     assertTrue(erc20Authorized.isAuthorized(address(customToken1), owner, authorized1));
    //     assertEq(erc20Authorized.getAuthorizedCap(address(customToken1), owner, authorized1), 25);

    //     address[] memory client1AuthorizersAfter = new address[](1);
    //     client1AuthorizersAfter[0] = authorized1;
    //     assertEq(
    //         erc20Authorized.getAuthorizersList(address(customToken1), owner),
    //         client1AuthorizersAfter
    //     );

    //     address[] memory client1OwnersAfter = new address[](1);
    //     client1OwnersAfter[0] = owner;
    //     assertEq(
    //         erc20Authorized.getOwnersList(address(customToken1), authorized1),
    //         client1OwnersAfter
    //     );
    // }
}

