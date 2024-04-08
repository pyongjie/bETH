pragma solidity ^0.5.0;

contract Beth {
    uint8 minParticipant;
    uint8 commissionFeeBetCreator;
    uint8 commissionFeeDev;
    uint8 transactionFee;

    constructor(uint8 minParticipantNo, uint8 betCreatorFee, uint8 devFee, uint8 txFee) public {
        minParticipant = minParticipantNo;
        commissionFeeBetCreator = betCreatorFee;
        commissionFeeDev = devFee;
        transactionFee = txFee;
    }

    struct bet {
        //uint256 betId;
        string betName;
        string side1Description;
        string side2Description;
        uint256 minBet;
        uint256 openingDate;
        uint256 closingDate;
        uint256 groupId;
        bool completed;
        bool result;
        address betCreator;
        uint8 currentParticipantsCount;
        mapping(address => uint256) side1Bets;
        mapping(address => uint256) side2Bets;
    }

    uint256 public numBets = 0;
    mapping(uint256 => bet) bets;
    uint256 public numGroups = 0;
    mapping(uint256 => group) groups;

    //function to create a new bet
    function createBet(
        string memory betName,
        string memory side1Description,
        string memory side2Description,
        uint256 minBet,
        uint256 openingDate,
        uint256 closingDate,
        uint256 groupId
    ) public payable returns(uint256) {

        //new bet object
        bet memory newBet = bet(
            betName,
            side1Description,
            side2Description,
            minBet,
            openingDate,
            closingDate,
            groupId,
            false,
            false,
            msg.sender,
            0
        );

        uint256 newBetId = numBets++;
        bets[newBetId] = newBet;
        return newBetId;
    }

    //function to create a group for private bets
    function createGroup(
        address[] memory arr
    ) public returns(uint256) {
        uint256 newGroupId = numGroups++;
        groups[newGroupId] = arr;
        return newGroupId;
    }
 
}
