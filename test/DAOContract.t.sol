// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract DAOContractTest is DAOBase {
    event ProposalCreated(uint256 indexed id, address indexed creator, string description, address proposalAddress);

    // Should create a proposal, success case
    function test_CreateProposal() public {
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
        assertEq(address(dao), proposal.target());
        assertEq(0, proposal.value());
        assertEq(abi.encodeWithSignature("noop()"), proposal.data());
        assertEq(address(token), address(proposal.governanceToken()));
        assertEq(address(dao), address(proposal.dao()));
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

    // Should revert if new minTokens is invalid
    function test_UpdateMinTokensToCreateProposalNotDao_Revert() public {
        vm.startPrank(address(dao));
        vm.expectRevert(bytes("DAO: invalid minTokens"));
        dao.updateMinTokensToCreateProposal(0);
        vm.stopPrank();
    }

    // Sholud revert if new votingPeriod is invalid
    function test_UpdateVotingPeriodNotDao_Revert() public {
        vm.startPrank(address(dao));
        vm.expectRevert(bytes("DAO: invalid voting period"));
        dao.updateVotingPeriod(0);
        vm.stopPrank();
    }

    function _emitCreatedProposal() public {
        vm.expectEmit(true, true, true, false);
        emit ProposalCreated(1, alice, "My first Proposal", address(this));
    }
}
