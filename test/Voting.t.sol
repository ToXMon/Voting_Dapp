// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/VotingSystem.sol";
import "../src/Treasury.sol";

contract VotingTest is Test {
    VotingSystem voting;
    Treasury treasury;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Create VotingSystem first with a temporary Treasury address
        voting = new VotingSystem(
            3,  // quorum = 3 votes
            1 days,  // voting period
            address(1) // Temporary address
        );
        
        // Now create Treasury with the actual VotingSystem address
        treasury = new Treasury(address(voting));
        
        // Update the Treasury address in VotingSystem
        // We need to add a function for this in VotingSystem
    }

    function testCreateProposal() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        uint256 proposalId = voting.createProposal{value: 1 ether}(
            "Test Proposal",
            "Description",
            1 ether
        );
        
        assertEq(proposalId, 1);
    }

    function testVoteFlow() public {
        // Initialize proposal first
        testCreateProposal();
        
        vm.prank(user2);
        voting.vote(1, 1); // Vote "Yes"
        
        // Check if the proposal is not executed yet
        (uint256 id, , , , , , address proposer, bool executed) = voting.proposals(1);
        assertEq(id, 1);
        assertEq(proposer, user1);
        assertFalse(executed);
    }
}