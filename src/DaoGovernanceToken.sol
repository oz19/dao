// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract DaoGovernanceToken is ERC20, Ownable {

    mapping(address => bool) public hasDelegated;
    mapping(address => address) public delegated;
    mapping(address => uint256) public delegatedVotes;

    event VotingPowerDelegated(address indexed delegator, address indexed delegate, uint256 amount);
    event VotingPowerUndelegated(address indexed delegator, address indexed delegate, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function delegateVotingPower(address delegate, uint256 amount) external {
        require(delegate != address(0), "Cannot delegate zero address");
        require(delegate != msg.sender, "Cannot delegate to yourself");
        require(amount > 0, "Amount must be higher than zero");
        require(balanceOf(msg.sender) >= amount, "Not enough votes");

        _transfer(msg.sender, delegate, amount);

        hasDelegated[msg.sender] = true;
        delegated[msg.sender] = delegate;
        delegatedVotes[msg.sender] += amount;

        emit VotingPowerDelegated(msg.sender, delegate, amount);
    }

    function undelegateVotingPower(uint256 amount) external {
        require(hasDelegated[msg.sender], "No delegation found");
        require(amount > 0, "Amount must be higher than zero");
        require(delegatedVotes[msg.sender] >= amount, "Insufficient delegated votes");

        address delegate = delegated[msg.sender];
        _transfer(delegate, msg.sender, amount);

        delegatedVotes[msg.sender] -= amount;
        if (delegatedVotes[msg.sender] == 0) {
            hasDelegated[msg.sender] = false;
            delete delegated[msg.sender];
        }

        emit VotingPowerUndelegated(msg.sender, delegate, amount);
    }

    function getVotingPower(address account) external view returns(uint256) {
        return balanceOf(account);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

}