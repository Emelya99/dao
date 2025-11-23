// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract DAOContractTest is DAOBase {
    event ProposalCreated(uint256 id, address creator, string description);
    event ProposalExecuted(uint256 id, address executor);

    // Create Proposel, success case
    function test_CreateProposal() public {
        uint256 startTimestamp = block.timestamp;
        uint256 proposalCount = dao.proposalCount();

        vm.expectEmit(true, true, true, true);
        emit ProposalCreated(proposalCount + 1, alice, "My first Proposal");

        _createNewProposal(alice, "My first Proposal");

        // Get proposal data from proposal address
        ProposalContract proposal = _getProposal(proposalCount + 1);

        assertEq(proposalCount + 1, proposal.id());
        assertEq(address(alice), proposal.author());
        assertEq("My first Proposal", proposal.description());
        assertEq(false, proposal.executed());
        assertEq(0, proposal.voteCountFor());
        assertEq(0, proposal.voteCountAgainst());
        assertEq(startTimestamp + VOTING_PERIOD, proposal.deadline());
        assertEq(address(token), address(proposal.governanceToken()));
        assertEq(address(dao), address(proposal.dao()));
    }

    // Create Proposal with empty description
    function test_CreateProposalWithEmptyDescriptionRevert() public {
        vm.expectRevert(bytes("DAO: description cannot be empty"));
        _createNewProposal(alice, "");
    }

    // Create Proposal when not enough balance
    function test_CreateProposalNotEnoughBalanceRevert() public {
        vm.expectRevert(bytes("DAO: You don't have enough tokens to create a proposal"));
        _createNewProposal(bob, "My first Proposal");
    }

    // Should update minTokensToCreateProposal
    function test_UpdateMinTokensToCreateProposal() public {
        dao.updateMinTokensToCreateProposal(100);
        assertEq(100, dao.minTokensToCreateProposal());
    }

    // Should revert if minTokensToCreateProposal is zero
    function test_UpdateMinTokensToCreateProposalZero_Revert() public {
        vm.expectRevert(bytes("DAO: minTokensToCreateProposal must be greater than 0"));
        dao.updateMinTokensToCreateProposal(0);
    }

    // Should update voting period
    function test_UpdateVotingPeriod() public {
        dao.updateVotingPeriod(10 minutes);
        assertEq(10 minutes, dao.votingPeriod());
    }

    // Should revert if voting period is zero
    function test_UpdateVotingPeriodZero_Revert() public {
        vm.expectRevert(bytes("DAO: voting period must be greater than 0"));
        dao.updateVotingPeriod(0);
    }
}
