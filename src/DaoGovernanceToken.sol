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
    ) ERC20(name, symbol, initialSupply) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
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