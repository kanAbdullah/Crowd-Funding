//SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {CrowdFunding} from "../src/CrowdFunding.sol";

pragma solidity ^0.8.18;

contract DeployCrowdFunding is Script{

    uint256 duration;
    uint256 goalAmount;

    
    function run() external returns(CrowdFunding){
        vm.startBroadcast();
        CrowdFunding crowdFunding = new CrowdFunding(
            100,
            1000,
            0,
            payable(address(0)),
            CrowdFunding.CrowdFundingType.ALL_OR_NOTHING
        );
        vm.stopBroadcast();
    }
}