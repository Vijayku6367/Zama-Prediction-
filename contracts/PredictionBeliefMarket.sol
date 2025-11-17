// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PredictionBeliefMarket {
    struct EventData {
        uint256 id;
        string question;
        string[] outcomes;
        uint256 endTime;
        bool resultDeclared;
        uint8 correctOutcome;
    }

    uint256 public eventCounter;
    mapping(uint256 => EventData) public events;

    event EventCreated(uint256 indexed id, string question);
    event ResultDeclared(uint256 indexed id, uint8 correctOutcome);

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

    function declareResult(uint256 _eventId, uint8 _correctOutcome) external {
        require(!events[_eventId].resultDeclared, "Already declared");
        events[_eventId].resultDeclared = true;
        events[_eventId].correctOutcome = _correctOutcome;

        emit ResultDeclared(_eventId, _correctOutcome);
    }

    function getEvent(uint256 _eventId) external view returns (
        string memory question,
        string[] memory outcomes,
        uint256 endTime,
        bool resultDeclared,
        uint8 correctOutcome
    ) {
        EventData memory e = events[_eventId];
        return (e.question, e.outcomes, e.endTime, e.resultDeclared, e.correctOutcome);
    }
}
