// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract DAOIntegrationTest is DAOBase {
    event ProposalExecuted(uint256 id, address executor);

    // Should Create Three Proposals in a row
    function test_CreateThreeProposals() public {
        _createGenericProposal(alice, "My first Proposal");
        _createGenericProposal(dave, "My second Proposal");
        _createGenericProposal(alice, "My third Proposal");

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

        assertTrue(proposal.executed());
    }

    // Should change minTokensToCreateProposal
    function test_UpdateMinTokensToCreateProposal() public {
        uint256 newValue = 1000;
        bytes memory data = abi.encodeWithSelector(dao.updateMinTokensToCreateProposal.selector, newValue);

        _createProposal(alice, "Change minTokensToCreateProposal", address(dao), 0, data);

        ProposalContract proposal = _getProposal(1);

        _vote(alice, proposal, true);

        _skipDeadline(proposal);

        dao.executeProposal(1);

        assertTrue(proposal.executed());
        assertEq(dao.minTokensToCreateProposal(), _toWei(newValue));
    }

    // Should change votingPeriod
    function test_UpdateVotingPeriod() public {
        uint256 newValue = 3 days;
        bytes memory data = abi.encodeWithSelector(dao.updateVotingPeriod.selector, newValue);

        _createProposal(alice, "Change votingPeriod", address(dao), 0, data);

        ProposalContract proposal = _getProposal(1);

        _vote(alice, proposal, true);

        _skipDeadline(proposal);

        dao.executeProposal(1);

        assertTrue(proposal.executed());
        assertEq(dao.votingPeriod(), newValue);
    }

    // Should mint 1000 tokens to the DAO after the proposal
    function test_MintTokens() public {
        uint256 mintValue = 10000;
        bytes memory data = abi.encodeWithSelector(token.mint.selector, address(dao), mintValue);

        _createProposal(alice, "Mint tokens", address(token), 0, data);

        ProposalContract proposal = _getProposal(1);

        _vote(alice, proposal, true);

        _skipDeadline(proposal);

        dao.executeProposal(1);

        assertTrue(proposal.executed());
        assertEq(token.balanceOf(address(dao)), mintValue);
    }
}
