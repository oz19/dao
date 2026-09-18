// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;


import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./DaoGovernanceToken.sol";


interface IDaoTreasury {
    function approveProposal(uint256 proposalId) external;
    function spendFunds(uint256 proposalId, address recipient, uint256 amount, address token) external;
}


contract Dao is Ownable {

    DaoGovernanceToken public governanceToken;
    IDaoTreasury public treasury;

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool cancelled;
        address recipient;
        uint256 amount;
        address token;
        mapping(address => bool) hasVoted;
        mapping(address => bool) votedFor;
    }

    uint256 public proposalThreshold;
    uint256 public votingPeriod;
    uint256 public quorumVotes;

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address recipient, uint256 amount, address token, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ConfigUpdated(uint256 proposalThreshold, uint256 votingPeriod, uint256 quorumVotes);
    
    constructor(
        address _governanceTokenAddr,
        address _treasury,
        uint256 _proposalThreshold,
        uint256 _votingPeriod,
        uint256 _quorumVotes
    ) Ownable(msg.sender) {
        governanceToken = DaoGovernanceToken(_governanceTokenAddr);
        proposalThreshold = _proposalThreshold;
        votingPeriod = _votingPeriod;
        quorumVotes = _quorumVotes;
    }

    function createProposal(
        string memory description,
        address recipient,
        uint256 amount,
        address token
    ) external returns(uint256 proposalId) {
        require(
            governanceToken.getVotingPower(msg.sender) >= proposalThreshold,
            "Insufficient voting power to create proposals"
        );
        require(bytes(description).length > 0, "Description cannot be empty");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");

        proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.recipient = recipient;
        proposal.amount = amount;
        proposal.token = token;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        proposal.executed = false;
        proposal.cancelled = false;

        emit ProposalCreated(proposalId, msg.sender, description, proposal.recipient, proposal.amount, proposal.token, proposal.startTime, proposal.endTime);
    }

    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.startTime, "Voting period has not started");
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.cancelled, "Proposal was cancelled");
        require(!proposal.executed, "Proposal already executed");

        uint256 votes = DaoGovernanceToken.getVotingPower(msg.sender);
        require(votes > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        proposal.votedFor[msg.sender] = support;
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit Voted(proposalId, msg.sender, support, votes);
    }

    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal is cancelled");
        require(
            msg.sender == proposal.proposer || msg.sender == owner(),
            "Not authorized to cancel"
        );

        proposal.cancelled = true;

        emit ProposalCancelled(proposalId);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "Voting not ended");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal is cancelled");
        require(
            proposal.forVotes + proposal.againstVotes >= quorumVotes,
            "Quorum not reached"
        );
        require(proposal.forVotes > proposal.againstVotes, "Proposal not approved");

        proposal.executed = true;

        treasury.approveProposal(proposalId);
        treasury.spendFunds(proposalId, proposal.recipient, proposal.amount, proposal.token);

        emit ProposalExecuted(proposalId);
    }
    
}