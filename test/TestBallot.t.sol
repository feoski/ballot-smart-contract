// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DeployBallot} from "script/DeployBallot.s.sol";
import {Ballot} from "src/Ballot.sol";

contract TestBallot is Test {
    Ballot ballot;

    string constant CANDIDATE = "CANDIDATE";
    string constant PARTY = "PARTY";
    address USER = makeAddr("USER");
    address now_owner = makeAddr("owner");

    event Voted(address indexed voter);

    modifier addSingleCandidate() {
        vm.prank(now_owner);
        ballot.addCandidate(CANDIDATE, PARTY);
        _;
    }

    modifier addFiveCandidates() {
        uint256 noOfCandidates = 5;
        for (uint256 i = 0; i < noOfCandidates; i++) {
            vm.prank(now_owner);
            ballot.addCandidate(string.concat("name", vm.toString(i)), string.concat("party", vm.toString(i)));
        }
        _;
    }

    function setUp() public {
        DeployBallot deployBallot = new DeployBallot();
        ballot = deployBallot.deploy();
    }

    function testOwnerSetProperly() external view {
        assertEq(ballot.owner(), now_owner);
    }

    function testElectionStateIsNotStartedAtBeginning() external view {
        assert(ballot.getElectionState() == Ballot.ElectionState.NOT_STARTED);
    }

    function testAddCandidateRevertsByNonOwnner() external {
        vm.prank(USER);
        vm.expectRevert();
        ballot.addCandidate(CANDIDATE, PARTY);
    }

    function testSingleCandidateUpdatesStorageVariables() external addSingleCandidate {
        bytes32 id = ballot.s_listOfCandidateIds(0);
        (string memory candidateName, string memory candidateParty, uint256 votes) = ballot.s_idToCandidate(id);

        assertEq(candidateName, CANDIDATE);
        assertEq(candidateParty, PARTY);
        assertEq(votes, 0);
        assertEq(ballot.s_candidateExists(id), true);
    }

    function testMultipleCandidatesGetterFunction() external addFiveCandidates {
        Ballot.Candidate[] memory tempArray = ballot.getAllCandidates();

        for (uint256 i = 0; i < tempArray.length; i++) {
            string memory expectedName = string.concat("name", vm.toString(i));
            string memory expectedParty = string.concat("party", vm.toString(i));
            bytes32 candidateId = keccak256(abi.encode(expectedName, expectedParty));

            assertEq(tempArray[i].name, expectedName);
            assertEq(tempArray[i].party, expectedParty);
            assertEq(tempArray[i].votes, 0);
            assertEq(ballot.s_candidateExists(candidateId), true);
        }
    }

    function testStartElectionFunctionChangesState() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();
        assert(ballot.getElectionState() == Ballot.ElectionState.STARTED);
    }

    function testVotingForSingleCandidateWorks() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();

        uint256 voters = 10;
        string memory correctCandidateName = "name0";
        string memory correctPartyName = "party0";
        for (uint256 i = 0; i < voters; i++) {
            address voter = makeAddr(vm.toString(i));

            vm.prank(voter);
            vm.expectEmit(true, false, false, false);
            emit Voted(voter);
            ballot.voteFor(correctCandidateName, correctPartyName);

            assertEq(ballot.s_alreadyVoted(voter), true);
        }
        bytes32 id = ballot.s_listOfCandidateIds(0);
        (,, uint256 votes) = ballot.s_idToCandidate(id);
        assertEq(votes, voters);
    }

    function testVotingForMultipleCandidateWorks() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();

        for (uint256 i = 0; i < 5; i++) {
            uint256 voters = 10;
            string memory correctCandidateName = string.concat("name", vm.toString(i));
            string memory correctPartyName = string.concat("party", vm.toString(i));
            for (uint256 j = 0; j < voters; j++) {
                address voter = makeAddr(vm.toString(i * 100 + j));

                vm.prank(voter);
                vm.expectEmit(true, false, false, false);
                emit Voted(voter);
                ballot.voteFor(correctCandidateName, correctPartyName);

                assertEq(ballot.s_alreadyVoted(voter), true);
            }
            bytes32 id = ballot.s_listOfCandidateIds(i);
            (,, uint256 votes) = ballot.s_idToCandidate(id);
            assertEq(votes, voters);
        }
    }
}
