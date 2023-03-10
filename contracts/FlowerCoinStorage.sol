pragma solidity 0.8.4;  
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";

// Stores flower coin 
contract FlowerCoinStorage is Ownable {
    constructor() {
        // Set the deployer as the initial owner
        transferOwnership(msg.sender);
    }

    // tracks total flower coin balance of each address
    mapping ( address => uint256 ) public totalBalances;

    // tracks total supply of flower coin
    uint256 public totalSupply;
    // tracks total flower coins burned
    uint256 public totalBurned;

    // mint flower coins to address
    function mint(address addr, uint256 amount) public onlyOwner {
        // update total balance in address
        totalBalances[addr] += amount;
        // update total supply of tokens
        totalSupply += amount;
    }
   
    // transfer flower coins to address
    function transfer(address from, address to, uint256 amount) public onlyOwner {
        require(totalBalances[from] >= amount, "From address does not have enough FlowerCoins to transfer");

        // subtract amount from from adress
        totalBalances[from] -= amount;
        // add amount to to address
        totalBalances[to] += amount;
    }

    // burn flower coins
    function burn(address addr, uint256 amount) public onlyOwner {
        require(totalBalances[addr] >= amount, "Address does not have enough FlowerCoins to burn");

        // subtract amount from address
        totalBalances[addr] -= amount;
        // subtract amount from total supply
        totalSupply -= amount;
        // add amount to total burned
        totalBurned += amount;
    }

}