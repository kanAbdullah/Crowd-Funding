// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract CrowdFunding{
    
    error CrowdFunding__NotOwner();
    error CrowdFunding__TransferFailed();
    error CrowdFunding__CrowdFundingIsNotActive();
    error CrowdFunding__UpkeepNotNeeded();
    error CrowdFunding__TimeHasNotFinished();
    
    enum CrowdFundingType{
        ALL_OR_NOTHING, //0
        KEEP_IT_ALL     //1
    }

    enum CrowdFundingState{
        ACTIVE,
        ENDED,
        WAITING
    }

    event ContractFunded(address indexed funder, uint256 amount);
    event FundsReturned(uint256 amount);
    event FundsWithdrawn(uint256 amount);

    string public fundingName;
    uint256 public duration;
    uint256 public goalAmount;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public s_lastTimeStamp;

    CrowdFundingType s_crowdFundingType;
    CrowdFundingState s_crowdFundingState;
    
    address payable[] private s_funders;
    mapping(address => uint256) private addressToAmountFunded;
    address private immutable i_owner;
    address payable public immutable i_recipient;

    modifier onlyOwner(){
        if(msg.sender != i_owner) revert CrowdFunding__NotOwner();
        _;
    }
    
    constructor(
        uint256 _duration,
        uint256 _goalAmount,
        uint256 _startTime,
        address payable _recipient,
        CrowdFundingType _crowdFundingType
    ){
        i_owner = msg.sender;

        duration = _duration;
        goalAmount = _goalAmount;
        startTime = _startTime;
        endTime = _startTime + _duration;
        i_recipient = _recipient;

        s_crowdFundingType = _crowdFundingType;
        s_crowdFundingState = CrowdFundingState.WAITING;
        s_lastTimeStamp = block.timestamp;
    }

    function fundContract() public payable{

        if(s_crowdFundingState != CrowdFundingState.ACTIVE)
            revert CrowdFunding__CrowdFundingIsNotActive();

        addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(payable(msg.sender));

        emit ContractFunded(msg.sender, msg.value);
    }
    /**
     * returnFunds function will be used for ALL_OR_NOTHING type of funding.
     * If the funding is not successful, all funds will be returned to funders.
     */
    function returnFunds() public {

        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            uint256 amountFunded = addressToAmountFunded[funder];
            addressToAmountFunded[funder] = 0;
            
            (bool success,) = payable(funder).call{value: amountFunded}("");
            if(!success) 
                revert CrowdFunding__TransferFailed();
        }

        s_funders = new address payable[](0);

        emit FundsReturned(address(this).balance);
    }

    function withdrawFunds() public onlyOwner{ //burası otomatikleştirilecek
        
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        s_funders = new address payable[](0);


        (bool callSuccess,) = payable(i_recipient).call{value: address(this).balance}(""); //withdraws all funds to recipient account
        require(callSuccess,"Call failed");

        emit FundsWithdrawn(address(this).balance);
    }


    function checkUpkeep() public view returns (bool upkeepNeeded, bytes memory /*performData*/){
        
        bool isActive = s_crowdFundingState == CrowdFundingState.ACTIVE;
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= duration;
        bool goalReached = address(this).balance >= goalAmount;

        upkeepNeeded = isActive && timeHasPassed && !goalReached;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /*performData*/) external{

        (bool upkeepNeeded,) = checkUpkeep();

        if(!upkeepNeeded)
            revert CrowdFunding__UpkeepNotNeeded();
        
        if(block.timestamp == startTime)
            startCrowdFunding();

        if(block.timestamp == endTime)
            endCrowdFunding();
    }

    function endCrowdFunding() public onlyOwner{
        
        if(block.timestamp < endTime)  //if time hasn't finished yet
            revert CrowdFunding__TimeHasNotFinished();
        s_crowdFundingState = CrowdFundingState.ENDED;

        /**
         * if funding type is ALL_OR_NOTHING and goalAmount is not reached
         * returnFunds() will be called to refund all funds to funders.
         */

        if(s_crowdFundingType == CrowdFundingType.ALL_OR_NOTHING && address(this).balance < goalAmount)
            returnFunds();
        else 
            withdrawFunds();
    }

    function startCrowdFunding() public onlyOwner{

        if(block.timestamp == startTime)
            s_crowdFundingState = CrowdFundingState.ACTIVE;
    }

    function getFundingName() public view returns(string memory){
        return fundingName;
    }
    function getDuration() public view returns(uint256){
        return duration;
    }
    function getGoalAmount() public view returns(uint256){
        return goalAmount;
    }
    function getStartTime() public view returns (uint256){
        return startTime;
    }
    function getEndTime() public view returns (uint256){
        return endTime;
    }
    function getRecipient() public view returns (address){
        return i_recipient;
    }
    function getCrowdFundingType() public view returns (CrowdFundingType){
        return s_crowdFundingType;
    }
    function getCrowdFundingState() public view returns (CrowdFundingState){
        return s_crowdFundingState;
    }
    function getOwner() public view returns(address){
        return i_owner;
    }
}

