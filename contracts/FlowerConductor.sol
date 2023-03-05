pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Flower.sol";

// handles minting (for now) and transfer and sending expired flower tokens to burn address 
contract FlowerConductor is Ownable {
    Flower public flower;

    constructor(address tokenAddress) {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);

        // set flower token address
        flower = Flower(tokenAddress);
    }

    function mint(uint256 _amount) external {
        // mint set amount of flowers to contract address
        flower.mint(address(this), _amount);
    }
}
