pragma solidity ^0.8.23;

abstract contract ProposalManager {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 creationTime;
        uint256 deadline;
        uint256 amount;
        address proposer;
        bool executed;
        
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        uint256 amount
    );

    // Will be implemented in VotingSystem
    function _createProposal(
        string memory _title,
        string memory _description,
        uint256 _deadline,
        uint256 _amount,
        address _proposer
    ) internal virtual returns (uint256);
}
