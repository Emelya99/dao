// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ProposalContract} from "./ProposalContract.sol";

contract DAOContract is Ownable {
    IERC20 public immutable GOVERNANCE_TOKEN;

    uint256 public proposalCount = 0;
    uint256 public minTokensToCreateProposal = 100;
    uint256 public votingPeriod = 3 days;

    mapping(uint256 => address) public proposals; // key - ID | value - ProposalContract address

    event ProposalCreated(uint256 id, address creator, string description);
    event ProposalExecuted(uint256 id, address executor);

    constructor(address _governanceToken, uint256 _minTokensToCreateProposal, uint256 _votingPeriod)
        Ownable(msg.sender)
    {
        require(_governanceToken != address(0), "DAO: Token address cannot be zero");
        require(_votingPeriod > 0, "DAO: voting period must be greater than ");

        GOVERNANCE_TOKEN = IERC20(_governanceToken);
        minTokensToCreateProposal = _minTokensToCreateProposal;
        votingPeriod = _votingPeriod;
    }

    function createGenericProposal(string memory _description) external {
        _createProposal(_description, ProposalContract.ProposalType.Generic, 0);
    }

    function createUpdateVotingPeriodProposal(string memory _description, uint256 _votingPeriod) external {
        require(_votingPeriod > 0, "DAO: voting period must be greater than 0");
        _createProposal(_description, ProposalContract.ProposalType.UpdateVotingPeriod, _votingPeriod);
    }

    function createUpdateMinTokensToCreateProposal(string memory _description, uint256 _minTokensToCreateProposal)
        external
    {
        require(_minTokensToCreateProposal > 0, "DAO: minTokensToCreateProposal must be greater than 0");
        _createProposal(
            _description, ProposalContract.ProposalType.UpdateMinTokensToCreateProposal, _minTokensToCreateProposal
        );
    }

    function executeProposal(uint256 _proposalId) external {
        require(proposals[_proposalId] != address(0), "DAO: Proposal does not exist");

        ProposalContract proposal = ProposalContract(proposals[_proposalId]);

        proposal.execute();

        _applyProposal(proposal);

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    function getProposal(uint256 _id) public view returns (address) {
        return proposals[_id];
    }

    function _createProposal(
        string memory _description,
        ProposalContract.ProposalType _proposalType,
        uint256 _configValue
    ) internal {
        require(bytes(_description).length > 0, "DAO: description cannot be empty");
        require(
            GOVERNANCE_TOKEN.balanceOf(msg.sender) >= minTokensToCreateProposal,
            "DAO: You don't have enough tokens to create a proposal"
        );

        proposalCount++;
        uint256 deadline = block.timestamp + votingPeriod;

        ProposalContract proposal = new ProposalContract(
            proposalCount,
            msg.sender,
            _description,
            deadline,
            address(GOVERNANCE_TOKEN),
            address(this),
            _proposalType,
            _configValue
        );

        proposals[proposalCount] = address(proposal);

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    function _applyProposal(ProposalContract _proposal) internal {
        ProposalContract.ProposalType pType = _proposal.proposalType();
        uint256 value = _proposal.configValue();

        if (pType == ProposalContract.ProposalType.UpdateVotingPeriod) {
            votingPeriod = value;
        } else if (pType == ProposalContract.ProposalType.UpdateMinTokensToCreateProposal) {
            minTokensToCreateProposal = value;
        }
    }
}
