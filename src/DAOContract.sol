// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ProposalContract} from "./ProposalContract.sol";

contract DAOContract is Ownable, ReentrancyGuard {
    IERC20 public immutable GOVERNANCE_TOKEN;
    uint8 public immutable TOKEN_DECIMALS;

    uint256 public proposalCount;
    uint256 public minTokensToCreateProposal;
    uint256 public votingPeriod;

    mapping(uint256 => address) public proposals; // key - ID | value - ProposalContract address

    event ProposalCreated(uint256 indexed id, address indexed creator, string description, address proposalAddress);
    event ProposalExecuted(uint256 id, address executor);

    constructor(address _governanceToken, uint256 _minTokensToCreateProposal, uint256 _votingPeriod)
        Ownable(msg.sender)
    {
        require(_governanceToken != address(0), "DAO: Token address cannot be zero");
        require(_minTokensToCreateProposal > 0, "DAO: minTokensToCreateProposal must be greater than 0");
        require(_votingPeriod > 0, "DAO: voting period must be greater than 0");

        GOVERNANCE_TOKEN = IERC20(_governanceToken);
        TOKEN_DECIMALS = IERC20Metadata(_governanceToken).decimals();

        minTokensToCreateProposal = _minTokensToCreateProposal * (10 ** uint256(TOKEN_DECIMALS));
        votingPeriod = _votingPeriod;
    }

    function createProposal(string memory _description, address _target, uint256 _value, bytes memory _data)
        external
        returns (uint256)
    {
        require(bytes(_description).length > 0, "DAO: description cannot be empty");
        require(
            GOVERNANCE_TOKEN.balanceOf(msg.sender) >= minTokensToCreateProposal,
            "DAO: You don't have enough tokens to create a proposal"
        );
        require(_target != address(0), "DAO: invalid target");

        proposalCount++;
        uint256 deadline = block.timestamp + votingPeriod;

        ProposalContract proposal = new ProposalContract(
            proposalCount,
            msg.sender,
            _description,
            deadline,
            _target,
            _value,
            _data,
            address(GOVERNANCE_TOKEN),
            address(this)
        );

        proposals[proposalCount] = address(proposal);

        emit ProposalCreated(proposalCount, msg.sender, _description, address(proposal));

        return proposalCount;
    }

    function executeProposal(uint256 _proposalId) external nonReentrant {
        require(proposals[_proposalId] != address(0), "DAO: Proposal does not exist");

        address proposalAddr = proposals[_proposalId];
        ProposalContract proposal = ProposalContract(proposalAddr);

        proposal.checkExecute();
        proposal.markExecuted();

        (bool ok,) = proposal.target().call{value: proposal.value()}(proposal.data());

        require(ok, "DAO: execution failed");

        emit ProposalExecuted(_proposalId, msg.sender);
    }

    function updateMinTokensToCreateProposal(uint256 _newMin) external onlyOwner {
        require(_newMin > 0, "DAO: invalid minTokens");
        minTokensToCreateProposal = _newMin * (10 ** uint256(TOKEN_DECIMALS));
    }

    function updateVotingPeriod(uint256 _newVotingPeriod) external onlyOwner {
        require(_newVotingPeriod > 0, "DAO: invalid voting period");
        votingPeriod = _newVotingPeriod;
    }

    function getProposal(uint256 _id) public view returns (address) {
        return proposals[_id];
    }

    function noop() external {}

    receive() external payable {}
}
