pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FlowerConductor.sol";

// Contract enables a set amount of flowers for each address to claim in a 24 hour window
// ** May need to schedule deployment as close to 00:00 UTC as possible so that easy to know when the claim window is refreshed

contract FlowerFaucet is Ownable {
    // the number of flowers available to be claimed by each account every 24 hours
    uint256 public claimableAmount = 1000000000000000000; // 1.00 where unit denominated in wei

    // TODO create mapping to store claimed amount

    // TODO store timestamps for checking claim refresh

    // TODO create claim mechanism

    // TODO create expiry/reset mechanism for unclaimed flower
}