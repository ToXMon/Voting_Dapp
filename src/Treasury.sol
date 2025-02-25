pragma solidity ^0.8.23;
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Treasury {
    // ReentrancyGuard implementation (copied from OZ patterns)
    bool private _locked;
    
    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    mapping(uint256 => uint256) public lockedFunds;
    address public immutable votingSystem;
    
    constructor(address _votingSystem) {
        votingSystem = _votingSystem;
    }

    modifier onlyVotingSystem() {
        require(msg.sender == votingSystem, "Unauthorized");
        _;
    }

    function lockFunds(uint256 proposalId, uint256 amount) 
        external 
        payable 
        onlyVotingSystem 
        nonReentrant 
    {
        require(msg.value == amount, "ETH mismatch");
        lockedFunds[proposalId] += msg.value;
    }

    function releaseFunds(uint256 proposalId, address payable recipient) 
        external 
        onlyVotingSystem 
        nonReentrant 
    {
        uint256 amount = lockedFunds[proposalId];
        require(amount > 0, "No locked funds");
        
        lockedFunds[proposalId] = 0;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}