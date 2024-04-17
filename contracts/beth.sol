pragma solidity ^0.8.0;
import "./ABDKMath64x64.sol";

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

    struct bet {
        string betName;
        string side1Description;
        string side2Description;
        uint256 minBet;
        address betCreator;
        uint8 currentParticipantsCount;
        uint256 groupId;
        uint256 openingDate;
        uint256 closingDate;
        uint256 payoutDate;
        bool completed;
        bool result;
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
    uint256 constant DELAY = 1 minutes;

    event PayoutDelayed(uint256 executionTime);
    event PayoutExecuted();

    modifier adminOnly() {
        require(msg.sender == admin, "Only an admin can execute this function");
        _;
    }

    modifier approvedAddresses(uint256 groupId, uint256 betId, address addr) {
        bool check = false;
        
        // check if bet group is public
        if (groupId == 0) {
            check = true;    
        } else {
            // check if address is in approved list of addresses for private group
            address[] memory arr = groups[groupId];
            for (uint256 i = 0; i < arr.length; i++) {
                if (addr == arr[i]) {
                    check = true;
                }
            }
        }

        // check if address has already placed for bet
        address[] memory sidearr = bets[betId].side1BetsAddress;
        for (uint256 i = 0; i < sidearr.length; i++) {
                if (addr == sidearr[i]) {
                    check = false;
                }
        }   

        // check if address has already placed for bet
        sidearr = bets[betId].side2BetsAddress;
        for (uint256 i = 0; i < sidearr.length; i++) {
                if (addr == sidearr[i]) {
                    check = false;
                }
        } 

        require(check == true, "Current address is not allowed to place bet");
        _;
    }


    modifier onlyAfter(uint256 time) {
        require(block.timestamp >= time, "Payout can only be called after 24 hours");
        _;
    }

    modifier existingGroup(uint256 groupId) {
        if (groupId != 0) {
            require(groups[groupId].length != 0, "GroupId is invalid");
        }
        _;
    }

    modifier validBet(uint256 betId) {
        require(bets[betId].openingDate != 0, "BetId is invalid");
        _;
    }

    // Bet Functions
    //function to create a new bet
    function createBet(
        string memory betName,
        string memory side1Description,
        string memory side2Description,
        uint256 minBet,
        uint256 openingDate,
        uint256 closingDate,
        uint256 groupId
    ) public existingGroup(groupId) returns(uint256) {
        //new bet object
        uint256 newBetId = numBets++;
        bet storage newBet = bets[newBetId];
        
        //initialize relevant variables in new bet object
        newBet.betName = betName;
        newBet.side1Description = side1Description;
        newBet.side2Description = side2Description;
        newBet.minBet = minBet;
        newBet.openingDate = openingDate;
        newBet.closingDate = closingDate;
        newBet.payoutDate = closingDate;
        newBet.groupId = groupId;
        newBet.completed = false;
        newBet.result = false;
        newBet.betCreator = msg.sender;
        newBet.currentParticipantsCount = 0;
        newBet.stakeSide1Bet = 0;
        newBet.stakeSide2Bet = 0;

        //return betId
        return newBetId;
    }

    //function to place bets
    function placeBet(
        uint256 betId,
        bool betSide
    ) public payable 
      validBet(betId)
      approvedAddresses(bets[betId].groupId, betId, msg.sender) 
    {   
        require(msg.value >= bets[betId].minBet, "Bet amount is less than minimum bet");
        require(block.timestamp >= bets[betId].openingDate && block.timestamp <= bets[betId].closingDate, "Bet not placed within betting dates");
        
        address payable recipient = payable(admin);
        recipient.transfer(msg.value);
        
        if (betSide) {
            //update bet object and side 1 bet variables
            uint256 curSide1Amt = bets[betId].stakeSide1Bet;
            bets[betId].stakeSide1Bet = curSide1Amt + msg.value;
            bets[betId].side1BetsAddress.push(msg.sender);
            bets[betId].side1Bets[msg.sender] = msg.value;
        } else {
            //update bet object and side 2 bet variables
            uint256 curSide2Amt = bets[betId].stakeSide2Bet;
            bets[betId].stakeSide2Bet = curSide2Amt + msg.value;
            bets[betId].side2BetsAddress.push(msg.sender);
            bets[betId].side2Bets[msg.sender] = msg.value;
        }
    }

    // function to view bet name
    function viewBetName(uint256 betId) public view returns (string memory) {
        return bets[betId].betName;
    }

    // function to view bet side 1 name
    function viewBetSide1Name(uint256 betId) public view returns (string memory) {
        return bets[betId].side1Description;
    }

    // function to view bet side 2 name
    function viewBetSide2Name(uint256 betId) public view returns (string memory) {
        return bets[betId].side2Description;
    }

    // function to view bet opening date
    function viewBetOpeningDate(uint256 betId) public view returns (uint256) {
        return bets[betId].openingDate;
    }

    // function to view bet closing date
    function viewBetClosingDate(uint256 betId) public view returns (uint256) {
        return bets[betId].closingDate;
    }

    // function to view bet result
    function viewBetResult(uint256 betId) public view returns (bool) {
        return bets[betId].result;
    }

    // function to view completion status
    function viewCompletionStatus(uint256 betId) public view returns (bool) {
        return bets[betId].completed;
    }

    // function to view the current odds
    function viewCurrentOdds(uint256 betId) public view returns(int128) {
        // For the case when the denominator is 0
        if (bets[betId].stakeSide2Bet == 0) {
            return 0;
        }

        return ABDKMath64x64.divu(bets[betId].stakeSide1Bet, bets[betId].stakeSide2Bet);
    }


    // Group Functions
    //function to create a group for private bets
    function createGroup(address[] memory arr) public returns(uint256) {
        numGroups++;
        uint256 newGroupId = numGroups;
        groups[newGroupId] = arr;
        return newGroupId;
    }

    //function to view group for private bets
    function viewGroup(uint256 groupId) public view returns(address[] memory) {
        address[] memory arr = groups[groupId];
        return arr;
    }


    // Admin Functions
    // wrapper function for admin to pay betters with 24 hours delay
    function executePayout(uint256 betId, bool result) public adminOnly() {
        require(block.timestamp >= bets[betId].closingDate, "Payout can only be executed after closing date");
        bets[betId].result = result;
        bets[betId].payoutDate = block.timestamp + DELAY;
        emit PayoutDelayed(bets[betId].payoutDate);
    }

    // function to payout betters
    function payout(uint256 betId) public adminOnly() {
        //onlyAfter(bets[betId].payoutDate
        //require(bets[betId].closingDate != bets[betId].payoutDate, "Admin has not set results, so payout date is not set");
        address[] memory winnerLs;

        if (bets[betId].result) {
            winnerLs = bets[betId].side1BetsAddress;
        } else {
            winnerLs = bets[betId].side2BetsAddress;
        }

        uint256 totalPrizePool = bets[betId].stakeSide1Bet + bets[betId].stakeSide2Bet;
        uint256 txfee = tx.gasprice;
        uint256 payoutWinners = ((100 - commissionFeeBetCreator - commissionFeeDev) * totalPrizePool / 100)  - txfee * (winnerLs.length + 2);

        //Pay bet initiator
        address payable betCreator = payable(bets[betId].betCreator);
        uint256 betCreatorPayment = commissionFeeBetCreator * totalPrizePool / 100;
        betCreator.transfer(betCreatorPayment);

        // Pay developers
        address payable dev = payable(admin);
        dev.transfer(commissionFeeDev * totalPrizePool / 100 );

        // Iterate through winners list to pay each winner depending on their stake
        for (uint i = 0; i < winnerLs.length; i++) {
            address payable recipient = payable(winnerLs[i]);
            uint256 payoutPerPerson = 0;

            if (bets[betId].result) {
                payoutPerPerson = bets[betId].side1Bets[recipient] * payoutWinners / totalPrizePool ;
            } else {
                payoutPerPerson = bets[betId].side2Bets[recipient] * payoutWinners / totalPrizePool ;
            }

            recipient.transfer(payoutPerPerson);
        }

        // Change payout and completion status
        bets[betId].completed = true;
        emit PayoutExecuted();
    }

    // function for admin to edit result of the bet
    function changeResult(uint256 betId) public adminOnly() returns (bool) {
        bets[betId].result = !bets[betId].result;
        return !bets[betId].result;
    }

    // A lot of helper functions here for debugging
    // will delete later
    function viewBetSide1Stakes(uint256 betId) public view returns (uint256) {
        return bets[betId].stakeSide1Bet;
    }

    function viewBetSide2Stakes(uint256 betId) public view returns (uint256) {
        return bets[betId].stakeSide2Bet;
    }

    function viewBetSide1Add(uint256 betId) public view returns (address[] memory) {
        return bets[betId].side1BetsAddress;
    }

    function viewBetSide2Add(uint256 betId) public view returns (address[] memory) {
        return bets[betId].side2BetsAddress;
    }

    function viewbetCreator(uint256 betId) public view returns (address) {
        return bets[betId].betCreator;
    }

    function getCurrentTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function getGas() public view returns(uint256) {
        return tx.gasprice;
    }
}
