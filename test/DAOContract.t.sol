// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract DAOContractTest is DAOBase {
    event ProposalCreated(uint256 id, address creator, string description, address proposalAddress);

    // Should create Generic Proposel, success case
    function test_CreateGenericProposal() public {
        uint256 startTimestamp = block.timestamp;
        uint256 proposalCount = dao.proposalCount();

        _emitCreatedProposal();

        _createGenericProposal(alice, "My first Proposal");

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
        assertEq(uint256(ProposalContract.ProposalType.Generic), uint256(proposal.proposalType()));
        assertEq(0, proposal.configValue());
    }

    // Should create UpdateVotingPeriod Proposel, success case
    function test_CreateUpdateVotingPeriodProposal() public {
        _emitCreatedProposal();

        _createUpdateVotingPeriodProposal(alice, "My first Proposal", 2 days);

        ProposalContract proposal = _getProposal(1);

        assertEq(uint256(ProposalContract.ProposalType.UpdateVotingPeriod), uint256(proposal.proposalType()));
        assertEq(2 days, proposal.configValue());
    }

    // Should revert if new voting period is zero
    function test_CreateUpdateVotingPeriodProposalWithZeroVotingPeriod_Revert() public {
        vm.expectRevert(bytes("DAO: voting period must be greater than 0"));
        _createUpdateVotingPeriodProposal(alice, "My first Proposal", 0);
    }

    // Create UpdateMinTokensToCreateProposal Proposel, success case
    function test_CreateUpdateMinTokensToCreateProposal() public {
        _emitCreatedProposal();

        _createUpdateMinTokensToCreateProposal(alice, "My first Proposal", 2000);

        ProposalContract proposal = _getProposal(1);

        assertEq(
            uint256(ProposalContract.ProposalType.UpdateMinTokensToCreateProposal), uint256(proposal.proposalType())
        );
        assertEq(2000, proposal.configValue());
    }

    // Should revert if new min tokens is zero
    function test_CreateUpdateMinTokensToCreateProposalWithZeroMinTokens_Revert() public {
        vm.expectRevert(bytes("DAO: minTokensToCreateProposal must be greater than 0"));
        _createUpdateMinTokensToCreateProposal(alice, "My first Proposal", 0);
    }

    // Should revert if description is empty
    function test_CreateProposalWithEmptyDescription_Revert() public {
        vm.expectRevert(bytes("DAO: description cannot be empty"));
        _createGenericProposal(alice, "");
    }

    // Should revert if not enough balance
    function test_CreateProposalNotEnoughBalance_Revert() public {
        vm.expectRevert(bytes("DAO: You don't have enough tokens to create a proposal"));
        _createGenericProposal(bob, "My first Proposal");
    }

    // Should revert if try to execute proposal that is not created
    function test_ExecuteProposalNotCreated_Revert() public {
        vm.expectRevert(bytes("DAO: Proposal does not exist"));
        dao.executeProposal(1);
    }

    function _emitCreatedProposal() public {
        vm.expectEmit(true, true, true, false);
        emit ProposalCreated(1, alice, "My first Proposal", address(this));
    }
}
