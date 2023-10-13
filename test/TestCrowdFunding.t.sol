// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {CrowdFunding} from "../rc/CrowdFunding.sol";
import {Test} from "forge-std/Test.sol";

contract TestCrowdFunding is Test {

    CrowdFunding crowdFunding;
    address USER = makeAddr("user");
    uint256 STARTING_BALANCE = 10e18;
    uint256  GAS_PRICE = 1;

    function setUp() external {
        DeployCrowdFunding deployCrowdFunding = new deployCrowdFunding();
        crowdFunding = deployCrowdFunding.run();
        vm.deal(USER,STARTING_BALANCE);  
    }

    function testOwnerIsMsgSender() public {
        assert(crowdFunding.getOwner(),msg.sender);
    }

    function testOnlyOwnerCanWithdraw() public{
        vm.expectRevert();
        vm.prank(USER);
        crowdFunding.withdrawFunds();
    }
    function testFundedAmountStoredInMapping() public{
        vm.prank(USER);
        crowdFunding.fundContract{value:0.1e18}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 0.1e18);
    }

    function testWithdrawSingleFunder() public{
        
        uint256 startingOwnerBalance = crowdFunding.getOwner().balance;
        uint256 startingCrowdFundingBalance = address(crowdFunding).balance;

        vm.prank(crowdFunding.getOwner());
        crowdFunding.withdrawfunds();

        uint256 endingOwnerBalance = crowdFunding.getOwner().balance;
        uint256 endingCrowdFundingBalance = address(crowdFunding).balance;
        assertEq(endingCrowdFundingBalance, 0);
        assertEq(
            endingOwnerBalance, 
            startingOwnerBalance + startingCrowdFundingBalance);
    }

    function testWithdrawMultipleFunders() public{
        
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new balance
            //but hoax does it for us
            hoax(address(i), 0.1e18);
            crowdFunding.fund{value: 0.1e18}();
        }

        uint256 startingOwnerBalance = crowdFunding.getOwner().balance;
        uint256 startingFundMeBalance = address(crowdFunding).balance;

        vm.startPrank(crowdFunding.getOwner());
        crowdFunding.withdrawFunds();
        vm.stopPrank();

        assertEq(address(crowdFunding).balance, 0);
        assertEq(
            startingOwnerBalance + startingCrowdFundingBalance,
            crowdFunding.getOwner().balance);
    }

    function testUserCannotFundIfCrowFundingIsNotActive() public{
        vm.prank(USER);
        crowdFunding.fundContract{value: 0.1}();

        vm.expectRevert(CrowdFunding.CrowdFunding__CrowdFundingIsNotActive.selector)
        vm.prank(USER);
        crowdFunding.fundContract{value: 0.1}();
    }
    
    function testCrowdFundingEndsWhenTimePassed() public{}
    function testCrowdFundingEndsWhenTimePassed() public{}
    function testFundsReturnsCorrectly() public{}
}