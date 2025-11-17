// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// NOTE: Ye FHE types use karta hai (euint, ebool etc).
// Actual FHEVM / Zama setup ke hisaab se tumhe import paths adjust karne pad sakte hain.
// Yahan structure ready hai encrypted prediction market ke liye.

import "@fhenixprotocol/contracts/FHE.sol";
import "@fhenixprotocol/contracts/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PredictionBeliefMarket is Ownable {
    struct EventData {
        uint256 id;
        string question;
        string[] outcomes;
        uint256 endTime;
        bool resultDeclared;
        uint8 correctOutcome;
    }

    struct EncryptedVote {
        address voter;
        euint64 encryptedStake;
        euint8 encryptedOutcome;
    }

    uint256 public eventCounter;
    mapping(uint256 => EventData) public events;
    mapping(uint256 => EncryptedVote[]) private encryptedVotes;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event EventCreated(uint256 indexed id, string question);
    event VoteSubmitted(uint256 indexed id, address voter);
    event ResultDeclared(uint256 indexed id, uint8 correctOutcome);
    event RewardClaimed(uint256 indexed id, address claimant);

    function createEvent(
        string memory _question,
        string[] memory _outcomes,
        uint256 _endTime
    ) external {
        require(_outcomes.length > 1, "Need 2+ outcomes");

        eventCounter++;
        events[eventCounter] = EventData(
            eventCounter,
            _question,
            _outcomes,
            _endTime,
            false,
            0
        );

        emit EventCreated(eventCounter, _question);
    }

    function submitEncryptedVote(
        uint256 _eventId,
        inEuint64 calldata _encryptedStakeInput,
        inEuint8 calldata _encryptedOutcomeInput
    ) external {
        require(block.timestamp < events[_eventId].endTime, "Event ended");

        encryptedVotes[_eventId].push(
            EncryptedVote(
                msg.sender,
                TFHE.asEuint64(_encryptedStakeInput),
                TFHE.asEuint8(_encryptedOutcomeInput)
            )
        );

        emit VoteSubmitted(_eventId, msg.sender);
    }

    function declareResult(uint256 _eventId, uint8 _correctOutcome) external onlyOwner {
        require(!events[_eventId].resultDeclared, "Already declared");
        events[_eventId].resultDeclared = true;
        events[_eventId].correctOutcome = _correctOutcome;

        emit ResultDeclared(_eventId, _correctOutcome);
    }

    function claimReward(uint256 _eventId) external {
        require(events[_eventId].resultDeclared, "Not declared");
        require(!claimed[_eventId][msg.sender], "Already claimed");

        EncryptedVote[] memory votes = encryptedVotes[_eventId];
        uint256 n = votes.length;

        euint64 totalCorrectStake = TFHE.asEuint64(0);
        euint64 userStake = TFHE.asEuint64(0);
        uint8 correct = events[_eventId].correctOutcome;

        for (uint i = 0; i < n; i++) {
            euint8 decryptedOutcome = votes[i].encryptedOutcome;
            ebool isCorrect = TFHE.eq(decryptedOutcome, correct);

            totalCorrectStake = TFHE.add(
                totalCorrectStake,
                TFHE.select(isCorrect, votes[i].encryptedStake, TFHE.asEuint64(0))
            );

            if (votes[i].voter == msg.sender) {
                userStake = votes[i].encryptedStake;
            }
        }

        require(TFHE.decrypt(userStake) > 0, "No stake");

        euint64 encryptedReward = TFHE.asEuint64(
            TFHE.decrypt(userStake) * 2  // example 2x payout
        );

        claimed[_eventId][msg.sender] = true;

        TFHE.transfer(
            address(this),
            msg.sender,
            encryptedReward
        );

        emit RewardClaimed(_eventId, msg.sender);
    }

    function getEvent(uint256 _eventId) external view returns (
        string memory,
        string[] memory,
        uint256,
        bool,
        uint8
    ) {
        EventData memory e = events[_eventId];
        return (e.question, e.outcomes, e.endTime, e.resultDeclared, e.correctOutcome);
    }

    function totalVotes(uint256 _eventId) external view returns (uint256) {
        return encryptedVotes[_eventId].length;
    }
}
