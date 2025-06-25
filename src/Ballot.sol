// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error Ballot__ElectionAlreadyStarted();
error Ballot__ElectionAlreadyEnded();
error Ballot__ElectionNotStartedYet();
error Ballot__CandidateAlreadyExists();
error Ballot__NotEnoughCandidates();
error Ballot__NoCandidatesAvailable();
error Ballot__AlreadyVoted();
error Ballot__WinnerAlreadyDeclared();

/**
 * @title A decentralized voting system
 * @author 0xfeoski (Santhosh K)
 * @notice This ballot is used to conduct the election in a decentralized way without the fear of vote manipulation
 * @dev This implements Openzeppelin's access control (Ownable)
 */
contract Ballot is Ownable {
    struct Candidate {
        string name;
        string party;
        uint256 votes;
    }

    enum ElectionState {
        NOT_STARTED,
        STARTED,
        ENDED
    }

    ElectionState private s_currentState;
    Candidate public s_winner;

    bool public winnerDeclared = false;

    bytes32[] public s_listOfCandidateIds;
    mapping(bytes32 => Candidate) public s_idToCandidate;
    mapping(bytes32 => bool) public s_candidateExists;
    mapping(address => bool) public s_alreadyVoted;

    event CandidateAdded(string name, string party, bytes32 candidateId);
    event ElectionStarted(uint256);
    event Voted(address indexed voter);
    event ElectionEnded(uint256);
    event WinnerDeclared(string name, string party, uint256 votes);

    modifier checkEntry(string memory candidateName, string memory candidateParty) {
        if (s_currentState == ElectionState.STARTED) {
            revert Ballot__ElectionAlreadyStarted();
        }
        if (s_currentState == ElectionState.ENDED) {
            revert Ballot__ElectionAlreadyEnded();
        }
        if (s_candidateExists[generateCandidateId(candidateName, candidateParty)] == true) {
            revert Ballot__CandidateAlreadyExists();
        }

        _;
    }

    modifier checkVoter(string memory name, string memory party) {
        if (s_currentState == ElectionState.NOT_STARTED) {
            revert Ballot__ElectionNotStartedYet();
        }
        if (s_currentState == ElectionState.ENDED) {
            revert Ballot__ElectionAlreadyEnded();
        }
        bytes32 id = generateCandidateId(name, party);
        if (s_candidateExists[id] == false) {
            revert Ballot__NoCandidatesAvailable();
        }
        if (s_alreadyVoted[msg.sender] == true) {
            revert Ballot__AlreadyVoted();
        }
        _;
    }

    constructor(address owner) Ownable(owner) {
        s_currentState = ElectionState.NOT_STARTED;
    }

    function addCandidate(string memory candidateName, string memory candidateParty)
        external
        onlyOwner
        checkEntry(candidateName, candidateParty)
    {
        bytes32 candidateId = generateCandidateId(candidateName, candidateParty);
        s_idToCandidate[candidateId] = Candidate({name: candidateName, party: candidateParty, votes: 0});
        s_candidateExists[candidateId] = true;
        s_listOfCandidateIds.push(candidateId);

        emit CandidateAdded(candidateName, candidateParty, candidateId);
    }

    function voteFor(string memory candidateName, string memory candidateParty)
        external
        checkVoter(candidateName, candidateParty)
    {
        bytes32 id = generateCandidateId(candidateName, candidateParty);
        s_idToCandidate[id].votes++;
        s_alreadyVoted[msg.sender] = true;

        emit Voted(msg.sender);
    }

    function declareWinner() external onlyOwner {
        if (winnerDeclared == true) {
            revert Ballot__WinnerAlreadyDeclared();
        }
        endElection();

        uint256 numberOfCandidates = s_listOfCandidateIds.length;
        uint256 highestVotes = 0;
        Candidate memory tempWinner;
        bytes32 id;
        for (uint256 i = 0; i < numberOfCandidates; i++) {
            id = s_listOfCandidateIds[i];
            if (s_idToCandidate[id].votes > highestVotes) {
                highestVotes = s_idToCandidate[id].votes;
                tempWinner = s_idToCandidate[id];
            }
        }
        s_winner = tempWinner;
        winnerDeclared = true;

        emit WinnerDeclared(s_winner.name, s_winner.party, s_winner.votes);
    }

    function startElection() public onlyOwner {
        if (s_currentState == ElectionState.STARTED) {
            revert Ballot__ElectionAlreadyStarted();
        }
        if (s_currentState == ElectionState.ENDED) {
            revert Ballot__ElectionAlreadyEnded();
        }
        if (s_listOfCandidateIds.length < 2) {
            revert Ballot__NotEnoughCandidates();
        }
        s_currentState = ElectionState.STARTED;
        emit ElectionStarted(block.timestamp);
    }

    function endElection() public onlyOwner {
        if (s_currentState == ElectionState.NOT_STARTED) {
            revert Ballot__ElectionNotStartedYet();
        }
        s_currentState = ElectionState.ENDED;
        emit ElectionEnded(block.timestamp);
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        if (s_listOfCandidateIds.length == 0) {
            revert Ballot__NoCandidatesAvailable();
        }

        uint256 numberOfCandidates = s_listOfCandidateIds.length;
        Candidate[] memory tempCandidateArray = new Candidate[](numberOfCandidates);
        bytes32 id;
        for (uint256 i = 0; i < numberOfCandidates; i++) {
            id = s_listOfCandidateIds[i];
            tempCandidateArray[i] = Candidate({
                name: s_idToCandidate[id].name,
                party: s_idToCandidate[id].party,
                votes: s_idToCandidate[id].votes
            });
        }
        return tempCandidateArray;
    }

    function getElectionState() public view returns (ElectionState) {
        return s_currentState;
    }

    function generateCandidateId(string memory name, string memory party) private pure returns (bytes32) {
        return keccak256(abi.encode(name, party));
    }
}
