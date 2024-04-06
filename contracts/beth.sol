pragma solidity ^0.5.0;

contract Beth {
    struct bet {
        uint256 betId;
        string betName;
        string side1Description;
        string side2Description;
        uint256 minBet;
        uint256 openingDate;
        uint256 closingDate;
        bool completed;
        bool result;
        address betInitiator;
        mapping(address => uint256) side1Bets;
        mapping(address => uint256) side2Bets;
        uint8 currentParticipantsCount;
    }

    bet[] Bets_Array;
    uint8 minParticipant;
    uint8 commissionFeeBetCreator;
    uint8 commissionFeeDev;
    uint8 transactionFee;
    uint8[] groups;

    


}
