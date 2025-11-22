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

    function setUp() public virtual {
        token = new AYEMToken();
        dao = new DAOContract(address(token), MIN_TOKENS_TO_CREATE, VOTING_PERIOD);

        token.transfer(alice, 1000);
        token.transfer(bob, 500);
    }

    function _createNewProposal(address _author, string memory _descriptopn) internal {
        vm.startPrank(_author);
        dao.createProposal(_descriptopn);
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
}
