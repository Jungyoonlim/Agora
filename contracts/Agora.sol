//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import zkSync verifier
import "./CustomVerifier.sol";

contract PrivateAuction {
    // Auction parameters
    uint public reservePrice;
    uint public biddingEndTime;
    address public beneficiary;

    // Bidding state
    mapping(address => bytes32) public commitments;
    mapping(address => uint) public revealedBids;
    address public highestBidder;
    uint public highestBid;

    //Auction Phases
    enum Phase { Bidding, Reveal, Finalized }
    Phase public currentPhase; 

    //zkSync verifier
    CustomVerifier public customVerifier; 

    //Specific criteria, fee threshold, and required fee token for the auction
    uint public feeThreshold;
    uint public specificCriteria;
    address public requiredFeeToken;

    event BidPlaced(address indexed bidder, bytes32 commitment);
    event BidRevealed(address indexed bidder, uint bid);
    event AuctionFinalized(address indexed winner, uint highestBid);

    // Constructor -- called when the 'auction' contract is deployed. 
    // The constructor is used to initialize the contract's data, and is only called once.
    // The constructor is optional, and if it is not present, the contract is initialized with all zeros.
    constructor(uint _reservePrice, uint _biddingTime, address _beneficiar, address _customVerifier) {
        reservePrice = _reservePrice;
        biddingEndTime = block.timestamp + _biddingTime;
        beneficiary = _beneficiary;
        currentPhase = Phases.Bidding;
        customVerifier = CustomVerifier(_customVerifier);
    } 

    //Verifies the zkSync proof and if it is valid, the bid is valid
    function verifyZKP(bytes memory proof, address bidder, bytes32 hash) external {
        bool isValid = CustomVerifier.verifyProof(proof, bidder, hash);
        require(isValid, "Invalid ZK proof");

         //bidding, revealing, and auction finalization functions
    
    //Allows bidders to reveal their bids during the reveal phase
    //checks if the hashed bid matches the commitment and if it does, the bid is valid
    //The function then updates the highest bid and highest bidder if the revelaed bid is greater than the current highest bid
    }

    function publicValueMeetsCriteria() internal view returns (bool){
        //check if the public value meets the specific criteria for the auction
        uint minBalance = 10 ether;
        return (address(bidder).balance >= minBalance);
    }

    function feeIsBelowThreshold() internal view returns (bool) {
        //check if the fee is below the threshold for the auction
        uint maxFeePercentage = 5;
        uint maxAllowedFee = (revealedBids[bidder] * maxFeePercentage) / 100;
        return (fee <= maxAllowedFee);
    }
   
    function reveal(uint bid, bytes32 nonce) public {
        require(currentPhase == Phase.Revealing, "Not in revealing phase");
        bytes32 hashedBid = keccak256(abi.encodePacked(bid, nonce));
        require(commitments[msg.sender] == hashedBid, "Invalid bid or nonce");

        revealedBids[msg.sender] = bid;
        if (bid > highestBid && bid >= reservePrice) {
            highestBidder = msg.sender;
            highestBid = bid;
        }
        emit BidRevealed(msg.sender, bid);
    }

    //Used to finalize the auction after the revealing phase
    //Checks if the auction is in the finalized phase if the bidding time has ended
    //Transfers the highest bid to the beneficiary and emits an event with the auction's results
    function finalizeAuction() public {
        require(currentPhase == Phase.Finalized, "Auction not finalized yet");
        require(block.timestamp > biddingEndTime, "Bidding time has not ended");
        payable(beneficiary).transfer(highestBid);
        emit AuctionFinalized(highestBidder, highestBid);
    }

    //Allows changing the current phase of the auction. 
    //Checks the bidding time has ended before changing the phase
    function changePhase(Phase newPhase) public {
        require(block.timestamp > biddingEndTime, "Bidding time has not ended");
        currentPhase = newPhase;
    }
}

