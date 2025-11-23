// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract DAOIntegrationTest is DAOBase {
    event ProposalExecuted(uint256 id, address executor);

    // Should Create Three Proposals in a row
    function test_CreateThreeProposals() public {
        _createGenericProposal(alice, "My first Proposal");
        _createUpdateVotingPeriodProposal(dave, "My second Proposal", 10 days);
        _createUpdateMinTokensToCreateProposal(alice, "My third Proposal", 2500);

        ProposalContract proposalFirst = _getProposal(1);
        ProposalContract proposalSecond = _getProposal(2);
        ProposalContract proposalThird = _getProposal(3);

        // Check id
        assertEq(1, proposalFirst.id());
        assertEq(2, proposalSecond.id());
        assertEq(3, proposalThird.id());

        // Check description
        assertEq("My first Proposal", proposalFirst.description());
        assertEq("My second Proposal", proposalSecond.description());
        assertEq("My third Proposal", proposalThird.description());

        // Check proposal type
        assertEq(uint256(ProposalContract.ProposalType.Generic), uint256(proposalFirst.proposalType()));
        assertEq(uint256(ProposalContract.ProposalType.UpdateVotingPeriod), uint256(proposalSecond.proposalType()));
        assertEq(
            uint256(ProposalContract.ProposalType.UpdateMinTokensToCreateProposal),
            uint256(proposalThird.proposalType())
        );

        // Check address of proposals
        assertEq(dao.getProposal(1), address(proposalFirst));
        assertEq(dao.getProposal(2), address(proposalSecond));
        assertEq(dao.getProposal(3), address(proposalThird));
    }

    // Should Execute Generic Proposal and Emit ProposalExecuted event
    function test_ExecuteGenericProposal() public {
        _createGenericProposal(alice, "My first Proposal");

        ProposalContract proposal = _getProposal(1);

        _vote(alice, proposal, true);

        _skipDeadline(proposal);

        vm.expectEmit(true, true, true, true);
        emit ProposalExecuted(1, address(this));

        dao.executeProposal(1);

        assertEq(true, proposal.executed());
    }

    // Should create full cycle of UpdateVotingPeriod Proposel and check new value
    function test_CreateUpdateVotingPeriodProposalAndExecute() public {
        _createUpdateVotingPeriodProposal(alice, "My first Proposal", 10 days);

        ProposalContract proposalAfter = _getProposal(1);

        _vote(alice, proposalAfter, true);

        _skipDeadline(proposalAfter);

        dao.executeProposal(1);

        assertEq(10 days, dao.votingPeriod());

        uint256 timestampBefore = block.timestamp;

        _createGenericProposal(dave, "New Proposal after UpdateVotingPeriod");

        uint256 expectedDeadline = timestampBefore + 10 days;

        ProposalContract proposalBefore = _getProposal(2);

        assertEq(proposalBefore.deadline(), expectedDeadline);
    }

    // Should create full cycle of UpdateMinTokensToCreateProposal Proposel and check new value
    function test_CreateUpdateMinTokensToCreateProposalAndExecute() public {
        _createUpdateMinTokensToCreateProposal(alice, "My first Proposal", 2500);

        ProposalContract proposal = _getProposal(1);

        _vote(alice, proposal, true);

        _skipDeadline(proposal);

        dao.executeProposal(1);

        assertEq(2500, dao.minTokensToCreateProposal());

        vm.expectRevert(bytes("DAO: You don't have enough tokens to create a proposal"));
        _createGenericProposal(alice, "My second Proposal");
    }
}
