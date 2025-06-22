// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AIInvest is ERC20, Ownable, Pausable {
    uint256 public tokenPrice = 10000; // 1 ETH = 1000 token
    mapping(address => uint256) public lockedUntil;
    mapping(address => uint256) public claimableAmounts;
    mapping(address => bool) public hasClaimed;
    event TokenLocked(address indexed user, uint256 until);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    receive() external payable {
        buyToken();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function buyToken() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint256 amount = msg.value * tokenPrice;
        _transfer(owner(), msg.sender, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function lockToTime(address user, uint256 timestamp) external onlyOwner {
        require(timestamp > block.timestamp, "Must be future time");
        lockedUntil[user] = timestamp;
        emit TokenLocked(user, timestamp);
    }

    function lockForMinutes(address user, uint256 minutesFromNow) external onlyOwner {
        require(minutesFromNow > 0, "Must be greater than zero");
        uint256 lockUntil = block.timestamp + (minutesFromNow * 1 minutes);
        lockedUntil[user] = lockUntil;
        emit TokenLocked(user, lockUntil);
    }

    function lockManyForMinutes(address[] calldata users, uint256 minutesFromNow) external onlyOwner {
        require(minutesFromNow > 0, "Must be greater than zero");
        require(users.length > 0, "No users provided");

        uint256 lockUntil = block.timestamp + (minutesFromNow * 1 minutes);

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            lockedUntil[user] = lockUntil;
            emit TokenLocked(user, lockUntil);
        }
    }

    function unlock(address user) external onlyOwner {
        lockedUntil[user] = 0;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (from != address(0)) {
            require(block.timestamp > lockedUntil[from], "Sender's token is locked");
        }
        super._update(from, to, value);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function setClaimableAmounts(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
        require(users.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < users.length; i++) {
            claimableAmounts[users[i]] = amounts[i] * 10**decimals();
            hasClaimed[users[i]] = false;
        }
    }

    function claim() external {
        require(!hasClaimed[msg.sender], "Already claimed");
        uint256 amount = claimableAmounts[msg.sender];
        require(amount > 0, "Nothing to claim");

        hasClaimed[msg.sender] = true;
        _transfer(owner(), msg.sender, amount);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amount) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amount[i] * 10**decimals());
        }
    }
}
