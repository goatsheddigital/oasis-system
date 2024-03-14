// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CharityVoting {
    address public admin;
    IERC20 public token;
    uint public end;
    uint public voteYes;
    uint public voteNo;
    uint public totalVotes;
    mapping(address => bool) public voted;
    mapping(address => uint) public balances;
    address public charityAddress;
    bool public voteConcluded;
    bool public fundsSent;

    event Deposited(address indexed user, uint amount);
    event Voted(address indexed user, bool vote);
    event Refunded(address indexed user, uint amount);

    constructor(address _token, uint _duration, address _charityAddress) {
        admin = msg.sender;
        token = IERC20(_token);
        end = block.timestamp + _duration;
        charityAddress = _charityAddress;
    }

    function deposit(uint _amount) external {
        require(block.timestamp < end, "Voting has ended");
        token.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
        emit Deposited(msg.sender, _amount);
    }

    function vote(bool _vote) external {
        require(block.timestamp < end, "Voting has ended");
        require(!voted[msg.sender], "Already voted");
        require(balances[msg.sender] > 0, "No deposit found");

        voted[msg.sender] = true;
        if(_vote) {
            voteYes += balances[msg.sender];
        } else {
            voteNo += balances[msg.sender];
        }
        totalVotes += balances[msg.sender];
        emit Voted(msg.sender, _vote);
    }

    function concludeVote() external {
        require(block.timestamp >= end, "Voting period is still active");
        require(!voteConcluded, "Vote already concluded");

        voteConcluded = true;
        if(voteYes > voteNo) {
            uint balance = token.balanceOf(address(this));
            token.transfer(charityAddress, balance);
            fundsSent = true;
        }
    }

    function refund() external {
        require(voteConcluded, "Vote has not been concluded");
        require(!fundsSent, "Funds have been sent to charity");

        uint amount = balances[msg.sender];
        require(amount > 0, "No deposit to refund");
        
        balances[msg.sender] = 0;
        token.transfer(msg.sender, amount);
        emit Refunded(msg.sender, amount);
    }
}

