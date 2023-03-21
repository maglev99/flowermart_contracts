pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./FlowerConductor.sol";

// Contract enables a set amount of flowers for each address to claim in a 24 hour window
// ** May need to schedule deployment as close to 00:00 UTC as possible so that easy to know when the claim window is refreshed

contract FlowerFaucet is Ownable, ReentrancyGuard {
    using Address for address;
    FlowerConductor public flowerConductor;

    // the number of flowers available to be claimed by each address every 24 hours
    uint256 public claimableAmount = 1000000000000000000; // 1.00 where unit denominated in wei

    // the time faucet with reference for determining whether refresh 
    // set as immutable since changing will make lastClaimedIndex invalid
    uint256 public immutable referenceTime;

    // time interval when flowers can be claimed again
    // set as constant since changing will make lastClaimedIndex invalid
    // redeploy new contract with different refresh time if it needs changing
    uint256 public constant refreshTime = 30;  // 30 sec for testing

    // index that is the closest rounded down integer of (block.timestamp - referenceTime) / refreshTime
    // for determining whether flowers can be claimed again
    mapping ( address => uint256 ) public lastClaimedIndex;

    constructor() {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);

        // Set reference time to time of deployment
        referenceTime = block.timestamp;
    }

    // Events 
    event ClaimFlower(address indexed _addr, uint256 indexed timestamp, uint256 amount);
    event SetFlowerConductor(address indexed flowerConductorAddress);

    // set flower conductor
    function setFlowerConductor(address _addr) public onlyOwner {
        require(_addr.isContract(), "address must be a contract");
        flowerConductor = FlowerConductor(_addr);

        // emit event
        emit SetFlowerConductor(_addr);
    }

    // set claimable amount
    function setClaimableAmount(uint256 _amount) public onlyOwner {
        claimableAmount = _amount;
    } 
  
    // claim flower
    function claim(address _addr) public nonReentrant {
        // get last claimed index to determine if address can claim flower at this time
        uint256 claimedIndex = lastClaimedIndex[_addr];
        uint256 currentIndex = (block.timestamp - referenceTime) / refreshTime;

        // require to prevent claiming until time refreshed
        require(currentIndex > claimedIndex, "Already claimed within time period, wait for refresh before claiming again");

        // mint flower to address
        flowerConductor.mintFlower(_addr, claimableAmount);

        // update last claimed index of address with current index
        lastClaimedIndex[_addr] = currentIndex;

        // EVENT: emit claim flower event
        emit ClaimFlower(_addr, block.timestamp, claimableAmount);
    }
}