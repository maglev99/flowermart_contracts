// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Example_Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 2 ether;

  event Stake(address,uint256);

  uint256 public deadline = block.timestamp + 30 seconds;

  bool public openForWithdraw = false;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable beforeDeadline notCompleted {
    // pass in value
    uint256 value = msg.value;
    // add value staked
    balances[msg.sender] += value;
    // emit event
    emit Stake(msg.sender, value);
  }

    modifier notCompleted() {
        require(!exampleExternalContract.completed() ,"Contract complete, no new deposits accepted");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }


   modifier beforeDeadline() {
        require(block.timestamp < deadline ,"Cannot perform action because deadline passed");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public notCompleted {
    if (block.timestamp >= deadline)
    {
      if (address(this).balance >= threshold) {
        exampleExternalContract.complete{value: address(this).balance}();
      }
      // if not completed after deadline can withdraw funds
      else if (address(this).balance < threshold && !exampleExternalContract.completed())
      {
        console.log("address balance: ", address(this).balance);
        openForWithdraw = true;
      }
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
  function withdraw() public notCompleted {
    require(openForWithdraw, "Withdrawals are not open.");
    
    // store value of withdrawer in tmp variable to prevent reentrancy
    uint256 value = balances[msg.sender];
    payable(msg.sender).transfer(value);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }


  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
      //call stake
      stake();
  }
}
