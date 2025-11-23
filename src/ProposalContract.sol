// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ProposalContract {
    enum ProposalType {
        Generic,
        UpdateVotingPeriod,
        UpdateMinTokensToCreateProposal
    }

    uint256 public id;
    address public author;
    string public description;

    bool public executed;
    uint256 public voteCountFor;
    uint256 public voteCountAgainst;
    uint256 public deadline;

    uint256 public constant QUORUM_PERCENTAGE = 50;

    IERC20 public governanceToken;
    address public dao;

    ProposalType public proposalType;
    uint256 public configValue;

    mapping(address => bool) public hasVoted; // voter address => voted or not

    event Voted(uint256 id, address voter, bool support, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == dao, "DAO Proposal: Only DAO can execute");
        _;
    }

    modifier canVote() {
        checkVote();
        _;
    }

    modifier canExecute() {
        checkExecute();
        _;
    }

    // constructor
    constructor(
        uint256 _id,
        address _author,
        string memory _description,
        uint256 _deadline,
        address _token,
        address _dao,
        ProposalType _proposalType,
        uint256 _configValue
    ) {
        id = _id;
        author = _author;
        description = _description;
        deadline = _deadline;
        governanceToken = IERC20(_token);
        dao = _dao;

        proposalType = _proposalType;
        configValue = _configValue;
    }

    // Vote logic
    function vote(bool _support) external canVote {
        uint256 voterBalance = governanceToken.balanceOf(msg.sender);

        if (_support) {
            voteCountFor += voterBalance;
        } else {
            voteCountAgainst += voterBalance;
        }

        hasVoted[msg.sender] = true;

        emit Voted(id, msg.sender, _support, voterBalance);
    }

    function checkVote() public view {
        require(block.timestamp < deadline, "DAO Proposal: voting period has ended");

        require(!hasVoted[msg.sender], "DAO Proposal: voter has already voted on this proposal");

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        require(voterBalance > 0, "DAO Proposal: insufficient tokens to vote");
    }

    // Execute logic
    function execute() external onlyDAO canExecute {
        executed = true;
    }

    function checkExecute() public view {
        require(!executed, "DAO Proposal: proposal has already been executed");
        require(block.timestamp >= deadline, "DAO Proposal: voting period is still active");

        uint256 totalVotes = voteCountFor + voteCountAgainst;
        require(totalVotes > 0, "DAO Proposal: no votes cast for this proposal");

        uint256 quorum = totalVotes * QUORUM_PERCENTAGE / 100;
        require(voteCountFor > quorum, "DAO Proposal: proposal did not reach quorum");
    }
}
