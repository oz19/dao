// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/Dao.sol";


contract DaoTreasury is Ownable {

    Dao public dao;

    mapping(uint256 => bool) public approvedProposals;
    mapping(uint256 => bool) public executedProposals;

    event ProposalApproved(uint256 indexed proposalId);
    event FundsSpent(uint256 indexed proposalId, address indexed recipient, uint256 amount, address token);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event DaoSet(address indexed dao);

    constructor(address _daoAddr) Ownable(msg.sender) {
        dao = Dao(_daoAddr);
    }

    function setDao(address _daoAddr) external onlyOwner {
        require(_daoAddr != address(0), "Invalid DAO address");
        dao = Dao(_daoAddr);
        emit DaoSet(_daoAddr);
    }

}