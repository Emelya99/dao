// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import {ProposalContract} from "../src/ProposalContract.sol";
import {DAOBase} from "./DAOBase.t.sol";

contract ProposalContractTest is DAOBase {
    ProposalContract proposal;

    event Voted(uint256 id, address voter, bool support, uint256 amount);

    function setUp() public override {
        super.setUp();

        uint256 proposalCount = dao.proposalCount();

        _createNewProposal(alice, "My first Proposal");

        proposal = _getProposal(proposalCount + 1);
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
        vm.warp(proposal.deadline() + 1);

        vm.expectRevert(bytes("DAO: voting period has ended"));
        _vote(alice, proposal, true);
    }

    // Should revert if user has already voted
    function test_VoteTwiceRevert() public {
        _vote(bob, proposal, false);

        vm.expectRevert(bytes("DAO: voter has already voted on this proposal"));
        _vote(bob, proposal, true);
    }

    // Should revert if user doesn't have enough tokens
    function test_VoteNotEnoughBalanceRevert() public {
        vm.expectRevert(bytes("DAO: insufficient tokens to vote"));
        _vote(charlie, proposal, false);
    }
}
