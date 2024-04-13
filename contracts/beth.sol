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
        address[] side2BetsAddress; 
        mapping(address => uint256) side1Bets;
        mapping(address => uint256) side2Bets;
    }

    uint256 public numBets = 0;
    mapping(uint256 => bet) bets;
    uint256 public numGroups = 0;
    mapping(uint256 => address[]) groups;

    modifier adminOnly() {
        require(msg.sender == admin);
        _;
    }

    modifier approvedAddresses(uint256 groupId, address addr) {
        bool check = false;
        
        // Public bet
        if (groupId == 0) {
            check = true;    
        } else {
            // Private bet
            address[] memory arr = groups[groupId];
            for (uint256 i = 0; i < arr.length; i++) {
                if (addr == arr[i]) {
                    check == true;
                }
            }
        }

        require(check == true);
        _;
    }

    modifier minBetAmt(uint256 betId, uint betAmt) {
        require(betAmt >= bets[betId].minBet);
        _;
    }

    modifier withinBettingDates(uint256 betId, uint256 curTimeStamp) {
        require(curTimeStamp >= bets[betId].openingDate && 
        curTimeStamp <= bets[betId].closingDate);
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
    ) public returns(uint256) {
        //new bet object
        bet memory newBet;
        
        //initialize relevant variables in new bet object
        newBet.betName = betName;
        newBet.side1Description = side1Description;
        newBet.side2Description = side2Description;
        newBet.minBet = minBet;
        newBet.openingDate = openingDate;
        newBet.closingDate = closingDate;
        newBet.groupId = groupId;
        newBet.completed = false;
        newBet.result = false;
        newBet.betCreator = msg.sender;
        newBet.currentParticipantsCount = 0;
        newBet.stakeSide1Bet = 0;
        newBet.stakeSide2Bet = 0;
        
        //add new bet object to bets mapping
        uint256 newBetId = numBets++;
        bets[newBetId] = newBet;

        //return betId
        return newBetId;
    }

    //function to create a group for private bets
    function createGroup(address[] memory arr) public returns(uint256) {
        uint256 newGroupId = numGroups++;
        groups[newGroupId] = arr;
        return newGroupId;
    }

    //function to view group for private bets
    function viewGroup(uint256 groupId) public view returns(address[] memory) {
        address[] memory arr = groups[groupId];
        return arr;
    }

    function viewBet(uint256 betId) public view returns(bet) {
        return bets[betId];
    //function to place bets
    function placeBet(
        uint256 betId,
        uint256 groupId, 
        uint256 amount, 
        bool betSide
    ) public payable 
      approvedAddresses(groupId, msg.sender) 
      minBetAmt(betId, amount)
      withinBettingDates(betId, block.timestamp) 
    {
        if (betSide) {
            //update bet object and side 1 bet variables
            uint256 curSide1Amt = bets[betId].stakeSide1Bet;
            bets[betId].stakeSide1Bet = curSide1Amt + amount;
            bets[betId].side1BetsAddress.push(msg.sender);
            bets[betId].side1Bets[msg.sender] = amount;
        } else {
            //update bet object and side 2 bet variables
            uint256 curSide2Amt = bets[betId].stakeSide2Bet;
            bets[betId].stakeSide2Bet = curSide2Amt + amount;
            bets[betId].side2BetsAddress.push(msg.sender);
            bets[betId].side2Bets[msg.sender] = amount;
        }
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