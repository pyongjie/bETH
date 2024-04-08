pragma solidity ^0.5.0;

contract Beth {
    
    struct bet {
        //uint256 betId;
        string betName;
        string side1Description;
        string side2Description;
        uint256 minBet;
        uint256 openingDate;
        uint256 closingDate;
        bool completed;
        bool result;
        address betInitiator;
        uint8 currentParticipantsCount;
        mapping(address => uint256) side1Bets;
        mapping(address => uint256) side2Bets;
    }

    uint256 public numBets = 0;
    mapping(uint256 => bet) bets;
    
    uint8 minParticipant;
    uint8 commissionFeeBetCreator;
    uint8 commissionFeeDev;
    uint8 transactionFee;
    uint8[] groups;

    //function to create a new bet
    function createBet(
        string betName,
        string side1Description,
        string side2Description,
        uint256 minBet,
        uint256 openingDate,
        uint256 closingDate
    ) public payable returns(uint256) {

        //new bet object
        bet memory newBet = bet(
            betName,
            side1Description,
            side2Description,
            minBet,
            openingDate,
            closingDate,
            false,
            false,
            msg.sender,
            0
        );

        uint256 newBetId = numBets++;
        bets[newBetId] = newBet;
        return newBetId;
    }
 
}
