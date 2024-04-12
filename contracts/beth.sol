pragma solidity ^0.5.0;

contract Beth {
    uint8 minParticipant;
    uint8 commissionFeeBetCreator;
    uint8 commissionFeeDev;
    uint8 transactionFee;
    address admin;

    constructor(uint8 minParticipantNo, uint8 betCreatorFee, uint8 devFee, uint8 txFee) public {
        minParticipant = minParticipantNo;
        commissionFeeBetCreator = betCreatorFee;
        commissionFeeDev = devFee;
        transactionFee = txFee;
        admin = msg.sender;
    }

    // Which are the important ones to show?
    // Check Logic?
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
        uint256 stakeSide1Bet;
        uint256 stakeSide2Bet;
        address[] side1BetsAddress;
        address[] side2BetsAddess; 
        mapping(address => uint256) side1Bets;
        mapping(address => uint256) side2Bets;
    }

    uint256 public numBets = 0;
    mapping(uint256 => bet) bets;
    uint256 public numGroups = 0;
    mapping(uint256 => group) groups;

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

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

    function viewGroup(
        uint256 groupId
    ) public view returns(address[] memory) {
        address[] arr = groups[groupsId];
        return arr;
    }

    function viewBet(uint256 betId) public view returns(bet) {
        return bets[betId];
    }

    function viewCurrentOdds(uint256 betId) public view returns(uint256) {
        return bets[betId].stakeSide1Bet / bets[betId].stakeSide2Bet;
    }

    function payout(uint256 betId, bool result) public view adminOnly() {
        bets[betId].result = result;
        bets[betId].completed = true;

        if (result) {
            uint256 winnerLs = bets[betId].side1BetsAddress;
            mapping(address => uint256) winnerHash = bets[betId].side1Bets;
        } else {
            uint256 winnerLs = bets[betId].side2BetsAddress;
            mapping(address => uint256) winnerHash = bets[betId].side2Bets;
        }

        uint256 totalPrizePool = bets[betId].stakeSide1Bet + bets[betId].stakeSide2Bet;
        uint256 txfee = tx.gas;
        uint256 payoutWinners = ((100 - commissionFeeBetCreator - commissionFeeDev) / 100) * totalPrizePool - txfee * (winnerLs.length + 2);

        address payable betCreator = bets[betId].betCreator;
        betCreator.transfer(commissionFeeBetCreator / 100 * totalPrizePool);

        address payable dev = admin;
        dev.transfer(commissionFeeDev / 100 * totalPrizePool);

        for (uint i=0; i<winners.length; i++) {
            address payable recipient = winners[i];
            uint256 payoutPerPerson = (winnerHash[recipient] / totalPrizePool) * payoutWinners;
            recipient.transfer(payoutPerPerson);
        }
    }

    function changeResult(uint256 betId) public view adminOnly() returns(bool) {
        bets[betId].result = !bets[betId].result;
        return result;
    }
}