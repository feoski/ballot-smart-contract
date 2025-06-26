// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DeployBallot} from "script/DeployBallot.s.sol";
import {Ballot} from "../src/Ballot.sol";

contract TestBallot is Test {
    Ballot ballot;

    string constant CANDIDATE = "CANDIDATE";
    string constant PARTY = "PARTY";
    bytes32 constant CANDIDATE_ID = keccak256(abi.encode(CANDIDATE, PARTY));
    string constant WINNING_CANDIDATE = "name0";
    string constant WINNING_PARTY = "party0";
    uint256 constant WINNING_VOTES = 10;

    address VOTER = makeAddr("VOTER");
    address now_owner = makeAddr("owner");

    event CandidateAdded(string name, string party, bytes32 candidateId);
    event ElectionStarted(uint256);
    event Voted(address indexed voter);
    event ElectionEnded(uint256);
    event WinnerDeclared(string name, string party, uint256 votes);

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

    modifier addFiveCandidatesAndVote() {
        uint256 noOfCandidates = 5;
        for (uint256 i = 0; i < noOfCandidates; i++) {
            vm.prank(now_owner);
            ballot.addCandidate(string.concat("name", vm.toString(i)), string.concat("party", vm.toString(i)));
        }
        vm.prank(now_owner);
        ballot.startElection();

        uint256 voters = 10;
        for (uint256 i = 0; i < 5; i++) {
            string memory correctCandidateName = string.concat("name", vm.toString(i));
            string memory correctPartyName = string.concat("party", vm.toString(i));
            for (uint256 j = 0; j < voters; j++) {
                address voter = makeAddr(vm.toString(i * 100 + j));

                vm.prank(voter);
                ballot.voteFor(correctCandidateName, correctPartyName);
            }
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

    function testSingleCandidateUpdatesStorageVariables() external {
        vm.prank(now_owner);
        vm.expectEmit(false, false, false, false);
        emit CandidateAdded(CANDIDATE, PARTY, CANDIDATE_ID);
        ballot.addCandidate(CANDIDATE, PARTY);
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
        vm.expectEmit(false, false, false, false);
        emit ElectionStarted(block.timestamp);
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

    function testDeclareWinner() external addFiveCandidatesAndVote {
        vm.prank(now_owner);
        vm.expectEmit(false, false, false, false);
        emit WinnerDeclared(WINNING_CANDIDATE, WINNING_PARTY, WINNING_VOTES);
        ballot.declareWinner();
        (string memory winner,, uint256 votes) = ballot.s_winner();
        assertEq(WINNING_CANDIDATE, winner);
        assertEq(WINNING_VOTES, votes);
    }

    // Revert Tests
    function testAddCandidateRevertsByNonOwner() external {
        vm.prank(VOTER);
        vm.expectRevert();
        ballot.addCandidate(CANDIDATE, PARTY);
    }

    function testNoCandidateRevertWorks() external {
        vm.expectRevert(Ballot.Ballot__NoCandidatesAvailable.selector);
        ballot.getAllCandidates();
    }

    function testAddCandidateRevertsOnElectionstarted() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();

        vm.prank(now_owner);
        vm.expectRevert(Ballot.Ballot__ElectionAlreadyStarted.selector);
        ballot.addCandidate(CANDIDATE, PARTY);
    }

    function testAddCandidateRevertsOnElectionEnd() external addFiveCandidates {
        vm.startPrank(now_owner);
        ballot.startElection();
        ballot.endElection();

        vm.expectRevert(Ballot.Ballot__ElectionAlreadyEnded.selector);
        ballot.addCandidate(CANDIDATE, PARTY);
        vm.stopPrank();
    }

    function testAddCandidateRevertsOnDuplicateEntry() external addSingleCandidate {
        vm.prank(now_owner);
        vm.expectRevert(Ballot.Ballot__CandidateAlreadyExists.selector);
        ballot.addCandidate(CANDIDATE, PARTY);
    }

    function testVotingFailsBeforeElectionStarts() external addSingleCandidate {
        vm.prank(VOTER);
        vm.expectRevert(Ballot.Ballot__ElectionNotStartedYet.selector);
        ballot.voteFor(CANDIDATE, PARTY);
    }

    function testVotingFailsAfterElectionEnds() external addFiveCandidates {
        vm.startPrank(now_owner);
        ballot.startElection();
        vm.expectEmit(false, false, false, false);
        emit ElectionEnded(block.timestamp);
        ballot.endElection();
        vm.stopPrank();

        vm.prank(VOTER);
        vm.expectRevert(Ballot.Ballot__ElectionAlreadyEnded.selector);
        ballot.voteFor(WINNING_CANDIDATE, WINNING_PARTY);
    }

    function testVotingFailsOnWrongCandidate() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();

        vm.prank(VOTER);
        vm.expectRevert(Ballot.Ballot__NoCandidatesAvailable.selector);
        ballot.voteFor(CANDIDATE, PARTY);
    }

    function testVotingFailsWhenVoterVotesTwice() external addFiveCandidates {
        vm.prank(now_owner);
        ballot.startElection();

        vm.startPrank(VOTER);
        ballot.voteFor(WINNING_CANDIDATE, WINNING_PARTY);
        vm.expectRevert(Ballot.Ballot__AlreadyVoted.selector);
        ballot.voteFor(WINNING_CANDIDATE, WINNING_PARTY);
        vm.stopPrank();
    }

    function testDeclareWinnerRevertsOnCallingTwice() external addFiveCandidatesAndVote {
        vm.startPrank(now_owner);
        ballot.declareWinner();
        vm.expectRevert();
        ballot.declareWinner();
        vm.stopPrank();
    }

    function testStartElectionFailsWithoutEnoughCandidates() external {
        vm.prank(now_owner);
        vm.expectRevert(Ballot.Ballot__NotEnoughCandidates.selector);
        ballot.startElection();
    }

    function testEndElectionFailsBeforeElectionStart() external {
        vm.prank(now_owner);
        vm.expectRevert(Ballot.Ballot__ElectionNotStartedYet.selector);
        ballot.endElection();
    }
}
