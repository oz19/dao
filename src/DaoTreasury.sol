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

    function fundTreasuryWithEth() external payable {
        require(msg.value > 0, "Must fund ETH");
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function fundTreasuryWithToken(address token, uint256 amount) external {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        emit TreasuryFunded(msg.sender, amount);
    }

    // This function allows the contract to receive ETH
    receive() external payable {
        emit TreasuryFunded(msg.sender, msg.value);
    }

    function emergencyWithdraw(address token, uint256 amount, address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");

        if (token == address(0)) {  // Withdraw ETH
            require(address(this).balance > 0, "Insufficient ETH balance");
            (bool success,) = recipient.call{value: amount}("");
            require(success, "ETH withdrawal failed");

        } else {
            IERC20 tokenContract = IERC20(token);
            require(tokenContract.balanceOf(address(this)) > 0, "Insufficient token balance");
            bool success = tokenContract.transfer(recipient, amount);
            require(success, "Token withdrawal failed");
        }
    }
}