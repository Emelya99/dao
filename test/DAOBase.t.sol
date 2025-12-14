// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {AYEMToken} from "../src/AYEMToken.sol";
import {DAOContract} from "../src/DAOContract.sol";
import {ProposalContract} from "../src/ProposalContract.sol";

contract DAOBase is Test {
    // Contracts
    DAOContract internal dao;
    AYEMToken internal token;

    // Constants
    uint256 internal constant MIN_TOKENS_TO_CREATE = 700;
    uint256 internal constant VOTING_PERIOD = 3 days;

    // Test accounts
    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    address internal charlie = vm.addr(3);
    address internal dave = vm.addr(4);

    function setUp() public virtual {
        // deploy token and DAO
        token = new AYEMToken(address(this), address(this));
        dao = new DAOContract(address(token), MIN_TOKENS_TO_CREATE, VOTING_PERIOD);

        // transfer token ownership to DAO
        token.transferOwnership(address(dao));
        dao.transferOwnership(address(dao));

        require(token.transfer(alice, _toWei(1000)), "transfer failed");
        require(token.transfer(bob, _toWei(500)), "transfer failed");
        require(token.transfer(dave, _toWei(5000)), "transfer failed");
    }

    function _createGenericProposal(address _author, string memory _description) internal {
        vm.startPrank(_author);
        dao.createProposal(_description, address(dao), 0, abi.encodeWithSignature("noop()"));
        vm.stopPrank();
    }

    function _createProposal(
        address _author,
        string memory _description,
        address _target,
        uint256 _value,
        bytes memory _data
    ) internal {
        vm.startPrank(_author);
        dao.createProposal(_description, _target, _value, _data);
        vm.stopPrank();
    }

    function _getProposal(uint256 id) internal view returns (ProposalContract) {
        address proposalAddr = dao.getProposal(id);
        return ProposalContract(proposalAddr);
    }

    function _vote(address _voter, ProposalContract _proposal, bool _support) internal {
        vm.prank(_voter);
        _proposal.vote(_support);
    }

    function _skipDeadline(ProposalContract _proposal) internal {
        vm.warp(_proposal.deadline() + 1);
    }

    function _toWei(uint256 _amount) internal view returns (uint256) {
        return _amount * 10 ** uint256(token.decimals());
    }
}
