// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Ballot} from "src/Ballot.sol";

contract DeployBallot is Script {
    address now_owner = makeAddr("owner");

    function deploy() public returns (Ballot) {
        Ballot ballot = new Ballot(now_owner);
        return ballot;
    }
}
