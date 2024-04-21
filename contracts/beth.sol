pragma solidity ^0.8.0;
import "./ABDKMath64x64.sol";

contract Beth {
    uint8 commissionFeeBetCreator;
    uint8 commissionFeeAdmin;
    uint8 transactionFee;
    address admin;

    // Init contract
    constructor(uint8 betCreatorFee, uint8 adminFee, uint8 txFee) public payable {
        commissionFeeBetCreator = betCreatorFee;
        commissionFeeAdmin = adminFee;
        transactionFee = txFee;
        admin = msg.sender;
    }

    uint256 constant DELAY = 1440 minutes; // 24 hours
    uint256 constant averageGasLimit = 30000000;

    // Bet object
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

    // Events
    event betPlaced(
        uint256 betId,
        bool betSide,
        address bettorAddress,
        uint256 betValue
    );
    event payoutDelayed(uint256 executionTime);
    event payoutExecuted();
    event betResultChanged(bool result);

    // Modifiers to implement reusable requirements
    modifier adminOnly() {
        require(msg.sender == admin, "Only an admin can execute this function");
        _;
    }

    modifier approvedAddress(
        uint256 groupId,
        uint256 betId,
        address addr
    ) {
        bool check = false;
        // Check if bet group is public
        if (groupId == 0) {
            check = true;
        } else {
            // Check if address is inside the approved list of addresses for private group
            address[] memory arr = groups[groupId];
            for (uint256 i = 0; i < arr.length; i++) {
                if (addr == arr[i]) {
                    check = true;
                }
            }
        }

        require(
            check == true,
            "User is not approved to place bet in this group"
        );
        _;
    }

    modifier onlyAfterDelay(uint256 time) {
        require(
            block.timestamp >= time,
            "Payout can only be called after 24 hours"
        );
        _;
    }

    modifier validGroupId(uint256 groupId) {
        if (groupId != 0) {
            require(groups[groupId].length != 0, "groupId is invalid");
        }
        _;
    }

    modifier validBetId(uint256 betId) {
        require(bets[betId].openingDate != 0, "betId is invalid");
        _;
    }

    // Bet functions for all users
    // Function to create a new bet
    function createBet(
        string memory betName,
        string memory side1Description,
        string memory side2Description,
        uint256 minBet,
        uint256 openingDate,
        uint256 closingDate,
        uint256 groupId
    ) public validGroupId(groupId) returns (uint256) {
        // New bet object
        bet storage newBet;
        uint256 newBetId = numBets++;
        bets[newBetId] = newBet; 

        // Initialize relevant variables in new bet object
        newBet.betName = betName;
        newBet.side1Description = side1Description;
        newBet.side2Description = side2Description;
        newBet.minBet = minBet;
        newBet.openingDate = openingDate;
        newBet.closingDate = closingDate;
        newBet.payoutDate = 0;
        newBet.groupId = groupId;
        newBet.completed = false;
        newBet.result = false;
        newBet.betCreator = msg.sender;
        newBet.currentParticipantsCount = 0;
        newBet.stakeSide1Bet = 0;
        newBet.stakeSide2Bet = 0;

        return newBetId;
    }

    // Function to place bets
    function placeBet(
        uint256 betId,
        bool betSide
    )
        public
        payable
        validBetId(betId)
        approvedAddress(bets[betId].groupId, betId, msg.sender)
    {
        require(
            msg.value >= bets[betId].minBet,
            "Bet amount is less than minimum bet"
        );
        require(
            block.timestamp >= bets[betId].openingDate &&
                block.timestamp <= bets[betId].closingDate,
            "Bet has to be placed within betting dates"
        );

        // Bet on side 1
        if (betSide) {
            // Update bet object and side 1 bet variables
            uint256 curSide1Amt = bets[betId].stakeSide1Bet;
            bets[betId].stakeSide1Bet = curSide1Amt + msg.value;
            bets[betId].side1BetsAddress.push(msg.sender);
            bets[betId].side1Bets[msg.sender] += msg.value;
        // Bet on side 2
        } else {
            // Update bet object and side 2 bet variables
            uint256 curSide2Amt = bets[betId].stakeSide2Bet;
            bets[betId].stakeSide2Bet = curSide2Amt + msg.value;
            bets[betId].side2BetsAddress.push(msg.sender);
            bets[betId].side2Bets[msg.sender] += msg.value;
        }

        emit betPlaced(betId, betSide, msg.sender, msg.value);
    }

    // Function to view bet name
    function viewBetName(uint256 betId) public view returns (string memory) {
        return bets[betId].betName;
    }

    // Function to view bet side 1 name
    function viewBetSide1Name(
        uint256 betId
    ) public view returns (string memory) {
        return bets[betId].side1Description;
    }

    // Function to view bet side 2 name
    function viewBetSide2Name(
        uint256 betId
    ) public view returns (string memory) {
        return bets[betId].side2Description;
    }

    // Function to view bet opening date
    function viewBetOpeningDate(uint256 betId) public view returns (uint256) {
        return bets[betId].openingDate;
    }

    // Function to view bet closing date
    function viewBetClosingDate(uint256 betId) public view returns (uint256) {
        return bets[betId].closingDate;
    }

    // Function to view bet result
    function viewBetResult(uint256 betId) public view returns (bool) {
        return bets[betId].result;
    }

    // Function to view bet completion status
    function viewCompletionStatus(uint256 betId) public view returns (bool) {
        return bets[betId].completed;
    }

    // Function to view the current odds of the bet
    function viewCurrentOdds(uint256 betId) public view returns (int128) {
        // For the case when the denominator is 0
        if (bets[betId].stakeSide2Bet == 0) {
            return 0;
        }
        return
            // Calculate odds using ABDKMath64x64 divison which supports floating point number
            ABDKMath64x64.divu(
                bets[betId].stakeSide1Bet,
                bets[betId].stakeSide2Bet
            );
    }

    // Group functions for all users
    // Function to create a group for private bets
    function createGroup(address[] memory arr) public returns (uint256) {
        numGroups++;
        uint256 newGroupId = numGroups;
        groups[newGroupId] = arr;
        return newGroupId;
    }

    // Function to view group for private bets
    function viewGroup(uint256 groupId) public view returns (address[] memory) {
        address[] memory arr = groups[groupId];
        return arr;
    }

    // Functions for admin only
    // Wrapper function for admin to set the bet result and to pay betters after 24 hours delay
    function executePayout(
        uint256 betId,
        bool result
    ) public adminOnly validBetId(betId) {
        require(
            block.timestamp >= bets[betId].closingDate,
            "Payout can only be executed after closing date"
        );

        // Set the bet result
        bets[betId].result = result;
        // Set the payoutDate with 24 hours delay after this function is called
        bets[betId].payoutDate = block.timestamp + DELAY;

        emit payoutDelayed(bets[betId].payoutDate);
    }

    // Function to payout prize pool to winners and commission fees to admin and bet creator
    function payout(
        uint256 betId
    ) public adminOnly onlyAfterDelay(bets[betId].payoutDate) {
        require(
            bets[betId].closingDate != 0,
            "Payout date not set as admin has yet to call wrapper function and set results"
        );
        
        // List of winners
        address[] memory winnerLs;

        // If side 1 won the bet
        if (bets[betId].result) {
            winnerLs = bets[betId].side1BetsAddress;
        // If side 2 won the bet
        } else {
            winnerLs = bets[betId].side2BetsAddress;
        }

        uint256 totalPrizePool = bets[betId].stakeSide1Bet + bets[betId].stakeSide2Bet;
        // Calculate total transaction fee for winner payouts including gas price
        uint256 totalTxFee = transactionFee * tx.gasprice * averageGasLimit;
        // Calculate prize pool for the winners after deducting the commission fee and total tx fee
        uint256 winnerPrizePool = (((100 -
            commissionFeeBetCreator -
            commissionFeeAdmin) * totalPrizePool) / 100) -
            totalTxFee *
            (winnerLs.length + 2);

        //Pay bet creator
        address payable betCreatorPayout = payable(bets[betId].betCreator);
        uint256 betCreatorPayment = (commissionFeeBetCreator * totalPrizePool) / 100;
        betCreatorPayout.transfer(betCreatorPayment);

        // Pay admin
        address payable adminPayout = payable(admin);
        uint256 adminPayment = (commissionFeeAdmin * totalPrizePool) / 100;
        adminPayout.transfer(adminPayment);

        // Iterate through the winners list to pay each winner depending on their stakes made
        for (uint i = 0; i < winnerLs.length; i++) {
            address payable winnerPayout = payable(winnerLs[i]);
            uint256 paymentPerPerson = 0;

            // If side 1 won the bet
            if (bets[betId].result) {
                paymentPerPerson =
                    (bets[betId].side1Bets[winnerPayout] * winnerPrizePool) /
                    bets[betId].stakeSide1Bet;
            // If side 2 won the bet
            } else {
                paymentPerPerson =
                    (bets[betId].side2Bets[winnerPayout] * winnerPrizePool) /
                    bets[betId].stakeSide2Bet;
            }

            winnerPayout.transfer(paymentPerPerson);
        }

        // Update bet completion status
        bets[betId].completed = true;

        emit payoutExecuted();
    }

    // Function for admin to edit result of the bet within the 24 hours delay
    function changeResult(
        uint256 betId
    ) public adminOnly validBetId(betId) {
        require(
            bets[betId].completed == false,
            "Bet has already been paid out and completed"
        );

        bets[betId].result = !bets[betId].result;

        emit betResultChanged(bets[betId].result);
    }

    // General functions for all users
    // Function to get current timestamp
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    // Function to check current gas price
    function checkGasPrice() public view returns (uint256) {
        return tx.gasprice;
    }
}
