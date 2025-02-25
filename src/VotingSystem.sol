// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Proposal.sol";
import "./Treasury.sol";

 contract VotingSystem is ProposalManager {
    struct Voter {
        bool voted;
        uint8 vote; // 0=Abstain, 1=Yes, 2=No
    }
    
    Treasury public treasury;
    uint256 public quorum;
    uint256 public votingPeriod;
    
    mapping(uint256 => mapping(address => Voter)) public voters;
    mapping(uint256 => uint256) public yesVotes;
    mapping(uint256 => uint256) public noVotes;

    constructor(
        uint256 _quorum,
        uint256 _votingPeriod,
        address _treasury
    ) {
        quorum = _quorum;
        votingPeriod = _votingPeriod;
        treasury = Treasury(_treasury);
    }

    modifier validProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal");
        _;
    }

    modifier activeProposal(uint256 proposalId) {
        require(proposals[proposalId].deadline > block.timestamp, "Voting closed");
        _;
    }

    function _createProposal(
        string memory _title,
        string memory _description,
        uint256 _deadline,
        uint256 _amount,
        address _proposer
    ) internal virtual override returns (uint256) {
        uint256 proposalId = ++proposalCount;
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            creationTime: block.timestamp,
            deadline: _deadline,
            amount: _amount,
            proposer: _proposer,
            executed: false
        });
        return proposalId;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _amount
    ) external payable returns (uint256) {
        require(bytes(_title).length > 0, "Empty title");
        require(_amount > 0, "Invalid amount");
        require(msg.value == _amount, "ETH mismatch");

        uint256 deadline = block.timestamp + votingPeriod;
        uint256 proposalId = _createProposal(
            _title,
            _description,
            deadline,
            _amount,
            msg.sender
        );

        treasury.lockFunds{value: msg.value}(proposalId, _amount);
        emit ProposalCreated(proposalId, msg.sender, _amount);
        return proposalId;
    }

    function vote(uint256 proposalId, uint8 _vote) 
        external
        validProposal(proposalId)
        activeProposal(proposalId)
    {
        require(_vote <= 2, "Invalid vote");
        Proposal storage proposal = proposals[proposalId];
        require(!voters[proposalId][msg.sender].voted, "Already voted");

        voters[proposalId][msg.sender] = Voter({
            voted: true,
            vote: _vote
        });

        if(_vote == 1) yesVotes[proposalId]++;
        else if(_vote == 2) noVotes[proposalId]++;
    }

    function tallyVotes(uint256 proposalId) 
        external
        validProposal(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.deadline, "Voting ongoing");
        require(!proposal.executed, "Already executed");
        
        uint256 totalVotes = yesVotes[proposalId] + noVotes[proposalId];
        require(totalVotes >= quorum, "Quorum not met");
        
        proposal.executed = true;
        
        if(yesVotes[proposalId] > noVotes[proposalId]) {
            treasury.releaseFunds(proposalId, payable(proposal.proposer));
        } else {
            treasury.releaseFunds(proposalId, payable(address(0xdead)));
        }
    }
    
    // Function to update the treasury address (for testing purposes)
    function setTreasury(address _treasury) external {
        treasury = Treasury(_treasury);
    }
}