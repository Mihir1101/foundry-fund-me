// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployingFundMe} from "../script/DeployingFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address public constant USER = address(1);

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployingFundMe deployingFundMe = new DeployingFundMe();
        fundMe = deployingFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testMinimunDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(),5e18);
    }

    function testOwnerIsMsgSender() public {
        //as the address that is deploying the test contract will be msg.sender
        //and we aew deployingfundme in setup function
        assertEq(fundMe.i_owner(),msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }

    function testFundFailWithoutEnoughtETH() public {
        vm.expectRevert(); //next line is expected to revert 
        fundMe.fund(); //sending 0 valaue in fund function which is less that 50 usd so it will fail 
        //this test will test if funds are failing on not sending enough 
    }

    function testFundUpdatesDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddAddressToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funderAddress = fundMe.getFunder(0);
        assertEq(funderAddress, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();

    }

    function testWithdrawWithASingleFunder() public funded {
        //Arange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance );
    }

    function testWithdrawFromMultipleFunder() public funded{
        uint160 numberOfFunders = 10;
        uint160 addressOfFunders = 1;
        for (uint160 i = addressOfFunders; i<numberOfFunders; i++){
            // hoax(<someaddress>, SEND_VALUE)
            //hoax can do both togerther prank and deal 
            //i.e. making a address and also having some funds in it
            //uint 160 -> address have same bytes as uint 160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }
    function testWithdrawFromMultipleFunderCheaper() public funded{
        uint160 numberOfFunders = 10;
        uint160 addressOfFunders = 1;
        for (uint160 i = addressOfFunders; i<numberOfFunders; i++){
            // hoax(<someaddress>, SEND_VALUE)
            //hoax can do both togerther prank and deal 
            //i.e. making a address and also having some funds in it
            //uint 160 -> address have same bytes as uint 160
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdrawCheaper();
        vm.stopPrank();
        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }
}