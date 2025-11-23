// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract ProposalContractTest is DAOBase {
    ProposalContract proposal;

    event Voted(uint256 id, address voter, bool support, uint256 amount);

    function setUp() public override {
        super.setUp();

        _createGenericProposal(alice, "My first Proposal");

        proposal = _getProposal(1);
    }

    // Should vote "for" and emit event
    function test_VoteFor() public {
        uint256 currentBalance = token.balanceOf(alice);

        vm.expectEmit(true, true, true, true);
        emit Voted(proposal.id(), alice, true, currentBalance);

        _vote(alice, proposal, true);

        assertEq(currentBalance, proposal.voteCountFor());
        assertEq(0, proposal.voteCountAgainst());
    }

    // Should vote "against" and emit event
    function test_VoteAgainst() public {
        uint256 currentBalance = token.balanceOf(bob);

        vm.expectEmit(true, true, true, true);
        emit Voted(proposal.id(), bob, false, currentBalance);

        _vote(bob, proposal, false);

        assertEq(currentBalance, proposal.voteCountAgainst());
        assertEq(0, proposal.voteCountFor());
    }

    // Should revert if trying to vote after deadline
    function test_VoteDeadlineEndedRevert() public {
        _skipDeadline(proposal);

        vm.expectRevert(bytes("DAO Proposal: voting period has ended"));
        _vote(alice, proposal, true);
    }

    // Should revert if user has already voted
    function test_VoteTwiceRevert() public {
        _vote(bob, proposal, false);

        vm.expectRevert(bytes("DAO Proposal: voter has already voted on this proposal"));
        _vote(bob, proposal, true);
    }

    // Should revert if user doesn't have enough tokens
    function test_VoteNotEnoughBalanceRevert() public {
        vm.expectRevert(bytes("DAO Proposal: insufficient tokens to vote"));
        _vote(charlie, proposal, false);
    }

    // Should exucute a proposal, success
    function test_ExecuteProposal() public {
        _vote(bob, proposal, true);

        _skipDeadline(proposal);

        dao.executeProposal(1);

        assertEq(true, proposal.executed());
    }

    // Should revert if not dao call the function
    function test_ExecuteNotDaoCall_Revert() public {
        _vote(bob, proposal, true);

        _skipDeadline(proposal);

        vm.expectRevert(bytes("DAO Proposal: Only DAO can execute"));
        proposal.execute();
    }

    // Should revert if proposal has already executed
    function test_ProposalAlrearyExecuted_Revert() public {
        test_ExecuteProposal();

        vm.expectRevert(bytes("DAO Proposal: proposal has already been executed"));
        dao.executeProposal(1);
    }

    // Should revert if voting period is still active
    function test_ProposalActiveVoting_Revert() public {
        _vote(bob, proposal, true);

        vm.expectRevert(bytes("DAO Proposal: voting period is still active"));
        dao.executeProposal(1);
    }

    // Should revert if total votes are zero
    function test_ProposalWithoutVotes_Revert() public {
        _skipDeadline(proposal);

        vm.expectRevert(bytes("DAO Proposal: no votes cast for this proposal"));
        dao.executeProposal(1);
    }

    // Should revert if proposal did not reach quorum
    function test_ProposalQuorumFailure_Revert() public {
        _vote(bob, proposal, false);

        _skipDeadline(proposal);

        vm.expectRevert(bytes("DAO Proposal: proposal did not reach quorum"));
        dao.executeProposal(1);
    }
}
